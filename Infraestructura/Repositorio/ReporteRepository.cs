using Dominio.DTO.Reporte;
using Infraestructura.Data;
using Infraestructura.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Data;

namespace Infraestructura.Repositorio
{
    public class ReporteRepository : ClsConexion, IReporteRepository
    {
        private readonly ILogger<ReporteRepository> _logger;

        public ReporteRepository(
            IOptions<SqlConfig> sqlConfig,
            ILogger<ReporteRepository> logger) : base(sqlConfig)
        {
            _logger = logger;
        }

        public async Task<ReporteDeudaActualResponseDto> ObtenerDeudaActualAsync(
            ReporteDeudaActualFiltroDto filtro,
            CancellationToken cancellationToken)
        {
            try
            {
                var result = new ReporteDeudaActualResponseDto();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand(@"
SELECT
    p.Cod_TipAnex,
    p.Cod_Anxo,
    ISNULL(a.Des_Anexo, '') AS Cliente,
    ISNULL(a.Num_Ruc, '') AS Documento,
    COUNT(DISTINCT p.Id_Prestamo) AS CantPrestamos,
    COUNT(1) AS CuotasPendientes,
    SUM(CASE WHEN fc.Fec_vencDocum < CONVERT(date, GETDATE()) THEN 1 ELSE 0 END) AS CuotasVencidas,
    SUM(ISNULL(fc.ImpCuota, 0)) AS TotalProgramado,
    SUM(ISNULL(fc.ImpCancelado, 0)) AS TotalPagado,
    SUM(ISNULL(fc.ImpCuota, 0) - ISNULL(fc.ImpCancelado, 0)) AS TotalSaldo,
    SUM(CASE
            WHEN fc.Fec_vencDocum < CONVERT(date, GETDATE())
                THEN ISNULL(fc.ImpCuota, 0) - ISNULL(fc.ImpCancelado, 0)
            ELSE 0
        END) AS TotalVencido,
    MIN(CASE
            WHEN fc.Fec_vencDocum < CONVERT(date, GETDATE())
                THEN fc.Fec_vencDocum
            ELSE NULL
        END) AS PrimerVencimiento,
    MAX(CASE
            WHEN fc.Fec_vencDocum < CONVERT(date, GETDATE())
                THEN DATEDIFF(DAY, fc.Fec_vencDocum, CONVERT(date, GETDATE()))
            ELSE 0
        END) AS DiasAtraso
FROM prest.prestamo p
INNER JOIN prest.cuota c
    ON c.Id_Prestamo = p.Id_Prestamo
INNER JOIN dbo.FI_Cobranza_Cuota fc
    ON fc.NroCobranza = c.NroCobranza
   AND fc.NumCuota = c.Num_Secuencia
   AND fc.Cod_Almacen = p.Cod_Almacen
LEFT JOIN dbo.CN_AnexosContables a
    ON a.Cod_TipAnex = p.Cod_TipAnex
   AND a.Cod_Anxo = p.Cod_Anxo
WHERE ISNULL(p.Flg_Estado, 'A') <> 'X'
  AND ISNULL(fc.FlgStatusPago, 'P') <> 'C'
  AND ISNULL(fc.ImpCuota, 0) - ISNULL(fc.ImpCancelado, 0) > 0
  AND (@FechaDesde IS NULL OR fc.Fec_vencDocum >= @FechaDesde)
  AND (@FechaHasta IS NULL OR fc.Fec_vencDocum < DATEADD(DAY, 1, @FechaHasta))
  AND (
        @Cliente = ''
        OR a.Des_Anexo LIKE '%' + @Cliente + '%'
        OR a.Num_Ruc LIKE '%' + @Cliente + '%'
        OR p.Cod_Anxo LIKE '%' + @Cliente + '%'
      )
  AND (
        @Estado = ''
        OR (@Estado = 'V' AND fc.Fec_vencDocum < CONVERT(date, GETDATE()))
        OR (@Estado = 'P' AND fc.Fec_vencDocum >= CONVERT(date, GETDATE()))
      )
GROUP BY
    p.Cod_TipAnex,
    p.Cod_Anxo,
    a.Des_Anexo,
    a.Num_Ruc
ORDER BY
    TotalSaldo DESC,
    Cliente;", cn)
                {
                    CommandType = CommandType.Text
                };

                cmd.Parameters.Add("@FechaDesde", SqlDbType.Date).Value = (object?)filtro.FechaDesde?.Date ?? DBNull.Value;
                cmd.Parameters.Add("@FechaHasta", SqlDbType.Date).Value = (object?)filtro.FechaHasta?.Date ?? DBNull.Value;
                cmd.Parameters.Add("@Cliente", SqlDbType.VarChar, 150).Value = (object?)filtro.Cliente?.Trim() ?? string.Empty;
                cmd.Parameters.Add("@Estado", SqlDbType.VarChar, 1).Value = (object?)filtro.Estado?.Trim().ToUpperInvariant() ?? string.Empty;

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    var item = new ReporteDeudaActualClienteDto
                    {
                        CodTipAnex = SqlReaderHelper.ValorReaderString(dr, "Cod_TipAnex"),
                        CodAnxo = SqlReaderHelper.ValorReaderString(dr, "Cod_Anxo"),
                        Cliente = SqlReaderHelper.ValorReaderString(dr, "Cliente"),
                        Documento = SqlReaderHelper.ValorReaderString(dr, "Documento"),
                        CantPrestamos = SqlReaderHelper.ValorReaderInt(dr, "CantPrestamos"),
                        CuotasPendientes = SqlReaderHelper.ValorReaderInt(dr, "CuotasPendientes"),
                        CuotasVencidas = SqlReaderHelper.ValorReaderInt(dr, "CuotasVencidas"),
                        TotalProgramado = SqlReaderHelper.ValorReaderDecimal(dr, "TotalProgramado"),
                        TotalPagado = SqlReaderHelper.ValorReaderDecimal(dr, "TotalPagado"),
                        TotalSaldo = SqlReaderHelper.ValorReaderDecimal(dr, "TotalSaldo"),
                        TotalVencido = SqlReaderHelper.ValorReaderDecimal(dr, "TotalVencido"),
                        PrimerVencimiento = dr["PrimerVencimiento"] == DBNull.Value ? null : Convert.ToDateTime(dr["PrimerVencimiento"]),
                        DiasAtraso = SqlReaderHelper.ValorReaderInt(dr, "DiasAtraso")
                    };

                    result.Detalle.Add(item);
                }

                result.Totales = new ReporteDeudaActualTotalesDto
                {
                    TotalClientes = result.Detalle.Count,
                    TotalPrestamos = result.Detalle.Sum(x => x.CantPrestamos),
                    TotalCuotasPendientes = result.Detalle.Sum(x => x.CuotasPendientes),
                    TotalCuotasVencidas = result.Detalle.Sum(x => x.CuotasVencidas),
                    TotalProgramado = result.Detalle.Sum(x => x.TotalProgramado),
                    TotalPagado = result.Detalle.Sum(x => x.TotalPagado),
                    TotalSaldo = result.Detalle.Sum(x => x.TotalSaldo),
                    TotalVencido = result.Detalle.Sum(x => x.TotalVencido)
                };

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en ReporteRepository.ObtenerDeudaActualAsync");
                throw;
            }
        }

        public async Task<ReporteEstadoCuentaClienteDto?> ObtenerEstadoCuentaClienteAsync(
            string codTipAnex,
            string codAnxo,
            CancellationToken cancellationToken)
        {
            try
            {
                using var cn = new SqlConnection(GetConnectionString());
                await cn.OpenAsync(cancellationToken);

                var result = new ReporteEstadoCuentaClienteDto
                {
                    CodTipAnex = codTipAnex,
                    CodAnxo = codAnxo,
                    FechaEmision = DateTime.Now
                };

                using (var cmdCliente = new SqlCommand(@"
SELECT TOP (1)
    ISNULL(Des_Anexo, '') AS Cliente,
    ISNULL(Num_Ruc, '') AS Documento
FROM dbo.CN_AnexosContables
WHERE Cod_TipAnex = @CodTipAnex
  AND Cod_Anxo = @CodAnxo;", cn))
                {
                    cmdCliente.Parameters.Add("@CodTipAnex", SqlDbType.Char, 1).Value = codTipAnex;
                    cmdCliente.Parameters.Add("@CodAnxo", SqlDbType.Char, 6).Value = codAnxo;
                    using var dr = await cmdCliente.ExecuteReaderAsync(cancellationToken);
                    if (await dr.ReadAsync(cancellationToken))
                    {
                        result.Cliente = SqlReaderHelper.ValorReaderString(dr, "Cliente");
                        result.Documento = SqlReaderHelper.ValorReaderString(dr, "Documento");
                    }
                }

                using (var cmd = new SqlCommand("prest.p_ctacte_cliente_detalle", cn) { CommandType = CommandType.StoredProcedure })
                {
                    cmd.Parameters.Add("@Cod_TipAnex", SqlDbType.Char, 1).Value = codTipAnex;
                    cmd.Parameters.Add("@Cod_Anxo", SqlDbType.Char, 6).Value = codAnxo;
                    using var dr = await cmd.ExecuteReaderAsync(cancellationToken);
                    while (await dr.ReadAsync(cancellationToken))
                    {
                        result.Prestamos.Add(new ReporteEstadoCuentaPrestamoDto
                        {
                            IdPrestamo = SqlReaderHelper.ValorReaderInt(dr, "Id_Prestamo"),
                            Fecha = SqlReaderHelper.ValorReaderDateTime(dr, "Fecha"),
                            Concepto = TieneColumna(dr, "ConceptoMostrar") ? SqlReaderHelper.ValorReaderString(dr, "ConceptoMostrar") : "",
                            Capital = SqlReaderHelper.ValorReaderDecimal(dr, "Capital"),
                            TotalProgramado = SqlReaderHelper.ValorReaderDecimal(dr, "TotalProgramado"),
                            TotalPagado = SqlReaderHelper.ValorReaderDecimal(dr, "TotalPagado"),
                            SaldoPendiente = SqlReaderHelper.ValorReaderDecimal(dr, "SaldoPendiente"),
                            NroCuotas = SqlReaderHelper.ValorReaderInt(dr, "Nro_Cuotas"),
                            CuotasVencidas = SqlReaderHelper.ValorReaderInt(dr, "CuotasVencidas"),
                            DiasAtraso = SqlReaderHelper.ValorReaderInt(dr, "DiasAtraso"),
                            Estado = SqlReaderHelper.ValorReaderString(dr, "EstadoTexto")
                        });
                    }
                }

                if (result.Prestamos.Count == 0)
                    return null;

                using (var cmd = new SqlCommand("prest.p_ctacte_cliente_cuotas", cn) { CommandType = CommandType.StoredProcedure })
                {
                    cmd.Parameters.Add("@Cod_TipAnex", SqlDbType.Char, 1).Value = codTipAnex;
                    cmd.Parameters.Add("@Cod_Anxo", SqlDbType.Char, 6).Value = codAnxo;
                    using var dr = await cmd.ExecuteReaderAsync(cancellationToken);
                    while (await dr.ReadAsync(cancellationToken))
                    {
                        result.Cuotas.Add(new ReporteEstadoCuentaCuotaDto
                        {
                            IdPrestamo = SqlReaderHelper.ValorReaderInt(dr, "Id_Prestamo"),
                            NumCuota = SqlReaderHelper.ValorReaderInt(dr, "NumCuota"),
                            FechaVencimiento = dr["Fec_Venc"] == DBNull.Value ? null : Convert.ToDateTime(dr["Fec_Venc"]),
                            Capital = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteBase"),
                            Interes = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteInteres"),
                            Importe = SqlReaderHelper.ValorReaderDecimal(dr, "ImpCuota"),
                            Pagado = SqlReaderHelper.ValorReaderDecimal(dr, "ImpPagado"),
                            Saldo = SqlReaderHelper.ValorReaderDecimal(dr, "SaldoCuota"),
                            Estado = SqlReaderHelper.ValorReaderString(dr, "EstadoCuota"),
                            DiasAtraso = SqlReaderHelper.ValorReaderInt(dr, "DiasAtraso")
                        });
                    }
                }

                foreach (var prestamo in result.Prestamos)
                {
                    var cuotasPrestamo = result.Cuotas.Where(x => x.IdPrestamo == prestamo.IdPrestamo).ToList();
                    var vencidasPrestamo = cuotasPrestamo
                        .Where(x => x.Saldo > 0 && x.FechaVencimiento.HasValue && x.FechaVencimiento.Value.Date < DateTime.Today)
                        .ToList();
                    prestamo.Interes = cuotasPrestamo.Sum(x => x.Interes);
                    prestamo.CuotasVencidas = vencidasPrestamo.Count;
                    prestamo.DiasAtraso = vencidasPrestamo.Count == 0 ? 0 : vencidasPrestamo.Max(x => x.DiasAtraso);

                    using var cmd = new SqlCommand("prest.p_prestamo_pago_listar", cn) { CommandType = CommandType.StoredProcedure };
                    cmd.Parameters.Add("@Id_Prestamo", SqlDbType.Int).Value = prestamo.IdPrestamo;
                    using var dr = await cmd.ExecuteReaderAsync(cancellationToken);
                    while (await dr.ReadAsync(cancellationToken))
                    {
                        result.Pagos.Add(new ReporteEstadoCuentaPagoDto
                        {
                            IdPrestamo = prestamo.IdPrestamo,
                            NumCuota = SqlReaderHelper.ValorReaderInt(dr, "numCuota"),
                            FechaPago = dr["fecPago"] == DBNull.Value ? null : Convert.ToDateTime(dr["fecPago"]),
                            FormaPago = SqlReaderHelper.ValorReaderString(dr, "formaPago"),
                            CajaBanco = SqlReaderHelper.ValorReaderString(dr, "cajaBanco"),
                            Importe = SqlReaderHelper.ValorReaderDecimal(dr, "importe"),
                            Glosa = SqlReaderHelper.ValorReaderString(dr, "glosa")
                        });
                    }
                }

                using (var cmd = new SqlCommand(@"
SELECT c.Id_Compensacion,c.Numero,c.Fecha,co.Nombre AS Concepto,
       c.ImporteAplicado,c.Flg_Estado,
       CASE c.Flg_Estado WHEN 'A' THEN 'Aplicada' WHEN 'R' THEN 'Revertida' ELSE 'Anulada' END AS Estado,
       ISNULL(o.Referencia,'') AS Referencia,ISNULL(c.Observacion,'') AS Observacion,d.Id_Prestamo,d.NumCuota,d.ImporteAplicado AS ImporteDetalle
FROM comp.compensacion c
JOIN comp.obligacion o ON o.Id_Obligacion=c.Id_Obligacion
JOIN comp.concepto_obligacion co ON co.Cod_Concepto=o.Cod_Concepto
JOIN comp.compensacion_detalle d ON d.Id_Compensacion=c.Id_Compensacion
WHERE c.id_empresa=@IdEmpresa AND c.id_est=@IdEst
  AND c.Cod_TipAnex=@CodTipAnex AND c.Cod_Anxo=@CodAnxo
ORDER BY c.Fecha DESC,c.Id_Compensacion DESC,d.OrdenAplicacion;", cn))
                {
                    cmd.Parameters.Add("@IdEmpresa", SqlDbType.Int).Value = 6;
                    cmd.Parameters.Add("@IdEst", SqlDbType.Char, 2).Value = "4";
                    cmd.Parameters.Add("@CodTipAnex", SqlDbType.Char, 1).Value = codTipAnex;
                    cmd.Parameters.Add("@CodAnxo", SqlDbType.Char, 6).Value = codAnxo;
                    using var dr = await cmd.ExecuteReaderAsync(cancellationToken);
                    var compensaciones = new Dictionary<int, ReporteEstadoCuentaCompensacionDto>();
                    var prestamosCompensados = new Dictionary<int, HashSet<int>>();
                    while (await dr.ReadAsync(cancellationToken))
                    {
                        var id = SqlReaderHelper.ValorReaderInt(dr, "Id_Compensacion");
                        var idPrestamo = SqlReaderHelper.ValorReaderInt(dr, "Id_Prestamo");
                        var estadoCodigo = SqlReaderHelper.ValorReaderString(dr, "Flg_Estado");
                        if (!compensaciones.TryGetValue(id, out var compensacion))
                        {
                            compensacion = new ReporteEstadoCuentaCompensacionDto
                            {
                                IdCompensacion = id,
                                Numero = SqlReaderHelper.ValorReaderString(dr, "Numero"),
                                Fecha = SqlReaderHelper.ValorReaderDateTime(dr, "Fecha"),
                                Concepto = SqlReaderHelper.ValorReaderString(dr, "Concepto"),
                                Referencia = SqlReaderHelper.ValorReaderString(dr, "Referencia"),
                                Importe = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteAplicado"),
                                EstadoCodigo = estadoCodigo,
                                Estado = SqlReaderHelper.ValorReaderString(dr, "Estado"),
                                Observacion = SqlReaderHelper.ValorReaderString(dr, "Observacion")
                            };
                            compensaciones.Add(id, compensacion);
                            prestamosCompensados.Add(id, new HashSet<int>());
                        }

                        compensacion.CuotasAfectadas++;
                        prestamosCompensados[id].Add(idPrestamo);
                        if (estadoCodigo == "A")
                        {
                            result.Pagos.Add(new ReporteEstadoCuentaPagoDto
                            {
                                IdPrestamo = idPrestamo,
                                NumCuota = SqlReaderHelper.ValorReaderInt(dr, "NumCuota"),
                                FechaPago = compensacion.Fecha,
                                FormaPago = "COMPENSACION",
                                CajaBanco = "SIN MOVIMIENTO DE CAJA",
                                Importe = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteDetalle"),
                                Glosa = $"{compensacion.Numero} - {compensacion.Concepto}"
                            });
                        }
                    }

                    foreach (var item in compensaciones.Values)
                    {
                        item.Prestamos = string.Join(", ", prestamosCompensados[item.IdCompensacion].OrderBy(x => x).Select(x => $"#{x}"));
                        result.Compensaciones.Add(item);
                    }
                }

                var hoy = DateTime.Today;
                var cuotasPendientes = result.Cuotas.Where(x => x.Saldo > 0).ToList();
                var cuotasVencidas = cuotasPendientes.Where(x => x.FechaVencimiento.HasValue && x.FechaVencimiento.Value.Date < hoy).ToList();
                result.Resumen = new ReporteEstadoCuentaResumenDto
                {
                    CantPrestamos = result.Prestamos.Count,
                    TotalCapital = result.Prestamos.Sum(x => x.Capital),
                    TotalInteres = result.Cuotas.Sum(x => x.Interes),
                    TotalProgramado = result.Prestamos.Sum(x => x.TotalProgramado),
                    TotalPagado = result.Prestamos.Sum(x => x.TotalPagado),
                    TotalCompensado = result.Compensaciones.Where(x => x.EstadoCodigo == "A").Sum(x => x.Importe),
                    TotalPagosRecibidos = result.Pagos.Where(x => x.FormaPago != "COMPENSACION").Sum(x => x.Importe),
                    SaldoPendiente = result.Prestamos.Sum(x => x.SaldoPendiente),
                    SaldoVencido = cuotasVencidas.Sum(x => x.Saldo),
                    CuotasVencidas = cuotasVencidas.Count,
                    DiasAtraso = cuotasVencidas.Count == 0 ? 0 : cuotasVencidas.Max(x => x.DiasAtraso),
                    ProximoVencimiento = cuotasPendientes
                        .Where(x => x.FechaVencimiento.HasValue && x.FechaVencimiento.Value.Date >= hoy)
                        .OrderBy(x => x.FechaVencimiento)
                        .Select(x => x.FechaVencimiento)
                        .FirstOrDefault()
                };

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al obtener estado de cuenta del cliente {CodTipAnex}-{CodAnxo}", codTipAnex, codAnxo);
                throw;
            }
        }

        private static bool TieneColumna(SqlDataReader dr, string nombre)
        {
            for (var i = 0; i < dr.FieldCount; i++)
            {
                if (string.Equals(dr.GetName(i), nombre, StringComparison.OrdinalIgnoreCase))
                    return true;
            }

            return false;
        }
    }
}
