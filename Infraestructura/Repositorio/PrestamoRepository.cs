using Dominio.DTO;
using Dominio.DTO.Common;
using Dominio.DTO.Prestamo;
using Infraestructura.Data;
using Infraestructura.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infraestructura.Repositorio
{
    public class PrestamoRepository :ClsConexion, IPrestamoRepository
    {
        private readonly SqlConfig _sqlConfig;
        private readonly ILogger<PrestamoRepository> _logger;

        public PrestamoRepository(
          IOptions<SqlConfig> sqlConfig,
           ILogger<PrestamoRepository> logger) : base(sqlConfig)
        {
            _sqlConfig = sqlConfig.Value;
            _logger = logger;
        }

        public async Task<List<PrestamoListDto>> ListarAsync(CancellationToken cancellationToken)
        {
            try
            {
                var result = new List<PrestamoListDto>();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("prest.p_prestamo_list", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    result.Add(new PrestamoListDto
                    {
                        Id_Prestamo = SqlReaderHelper.ValorReaderInt(dr, "Id_Prestamo"),
                        Cliente = SqlReaderHelper.ValorReaderString(dr, "Cliente"),
                        Documento = SqlReaderHelper.ValorReaderString(dr, "Documento"),
                        Fecha = SqlReaderHelper.ValorReaderDateTime(dr, "Fecha"),
                        Capital = SqlReaderHelper.ValorReaderDecimal(dr, "Capital"),
                        Nro_Cuotas = SqlReaderHelper.ValorReaderInt(dr, "Nro_Cuotas"),
                        TEA = SqlReaderHelper.ValorReaderDecimal(dr, "TEA"),
                        Estado = SqlReaderHelper.ValorReaderString(dr, "flg_Estado"),
                        Almacen= SqlReaderHelper.ValorReaderString(dr, "Almacen"),
                        Tipo_Modalidad = SqlReaderHelper.ValorReaderString(dr, "Tipo_Modalidad"),
                        Total_Programado= SqlReaderHelper.ValorReaderDecimal(dr, "Total_Programado"),
                        Total_Pagado= SqlReaderHelper.ValorReaderDecimal(dr, "Total_Pagado"),
                        Saldo_Pendiente= SqlReaderHelper.ValorReaderDecimal(dr, "Saldo_Pendiente"),
                        Estado_Descripcion = SqlReaderHelper.ValorReaderString(dr, "Estado_Descripcion"),
                        flg_Estado = SqlReaderHelper.ValorReaderString(dr, "flg_Estado")
                    });
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.ListarAsync");
                throw;
            }
        }
        public async Task<DbActionResult> GuardarAsync(PrestamoCreateRequestDto request, string usuario, CancellationToken cancellationToken)
        {
            try
            {
                var result = new DbActionResult();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("prest.p_prestamo_crear_y_plan_v2", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.AddWithValue("@Cod_Almacen", (object?)request.Cod_Almacen ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Cod_TipAnex", (object?)request.Cod_TipAnex ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Cod_Anxo", (object?)request.Cod_Anxo ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Fecha", request.Fecha);
                cmd.Parameters.AddWithValue("@Capital", request.Capital);
                cmd.Parameters.AddWithValue("@TipoInteres", request.TipoInteres);
                cmd.Parameters.AddWithValue("@PorcInteresMensual", request.PorcInteresMensual);
                cmd.Parameters.AddWithValue("@FrecuenciaPago", request.FrecuenciaPago);
                cmd.Parameters.AddWithValue("@FechaInicioCobro", request.FechaInicioCobro);
                cmd.Parameters.AddWithValue("@FechaFinCobro", request.FechaFinCobro);
                cmd.Parameters.Add("@TipoModalidad", SqlDbType.Char, 1).Value =(object?)request.TipoModalidad ?? DBNull.Value;
                cmd.Parameters.AddWithValue("@Observacion", (object?)request.Observacion ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Usu", (object?)usuario ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Cod_Concepto", (object?)request.Cod_Concepto ?? DBNull.Value);
                var outId = new SqlParameter("@Id_PrestamoOut", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outId);

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                if (await dr.ReadAsync(cancellationToken))
                {
                    result.Ok = SqlReaderHelper.ValorReaderBool(dr, "Ok");
                    result.RowsAffected = SqlReaderHelper.ValorReaderInt(dr, "RowsAffected");
                    result.Mensaje = SqlReaderHelper.ValorReaderString(dr, "Mensaje");
                    result.IdGenerado = SqlReaderHelper.ValorReaderInt(dr, "IdGenerado");
                    result.CodigoGenerado = SqlReaderHelper.ValorReaderString(dr, "CodigoGenerado");
                }

                if ((result.IdGenerado ?? 0) == 0 && outId.Value != DBNull.Value)
                    result.IdGenerado = Convert.ToInt32(outId.Value);

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.GuardarAsync");
                throw;
            }
        }

        public async Task<List<ClienteAnexoSelectDto>> BuscarClientesAsync(string texto, CancellationToken cancellationToken)
        {
            try
            {
                var result = new List<ClienteAnexoSelectDto>();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("dbo.p_cliente_anexo_list", cn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@Texto", (object?)texto ?? string.Empty);

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    result.Add(new ClienteAnexoSelectDto
                    {
                        Cod_TipAnex = SqlReaderHelper.ValorReaderString(dr, "Cod_TipAnex"),
                        Cod_Anxo = SqlReaderHelper.ValorReaderString(dr, "Cod_Anxo"),
                        Documento = SqlReaderHelper.ValorReaderString(dr, "Documento"),
                        NombreCompleto = SqlReaderHelper.ValorReaderString(dr, "NombreCompleto"),
                        TextoMostrar = SqlReaderHelper.ValorReaderString(dr, "TextoMostrar")
                    });
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.BuscarClientesAsync");
                throw;
            }
        }

        public async Task<PrestamoSimulacionDto?> SimularAsync(PrestamoSimulacionRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                PrestamoSimulacionDto? item = null;

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("prest.p_prestamo_simular", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.AddWithValue("@Capital", request.Capital);
                cmd.Parameters.AddWithValue("@TipoInteres", request.TipoInteres);
                cmd.Parameters.AddWithValue("@PorcInteresMensual", request.PorcInteresMensual);
                cmd.Parameters.AddWithValue("@FrecuenciaPago", request.FrecuenciaPago);
                cmd.Parameters.AddWithValue("@FechaInicioCobro", request.FechaInicioCobro);
                cmd.Parameters.AddWithValue("@FechaFinCobro", request.FechaFinCobro);

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                if (await dr.ReadAsync(cancellationToken))
                {
                    item = new PrestamoSimulacionDto
                    {
                        Ok = SqlReaderHelper.ValorReaderBool(dr, "Ok"),
                        NroCuotas = SqlReaderHelper.ValorReaderInt(dr, "NroCuotas"),
                        InteresMensual = SqlReaderHelper.ValorReaderDecimal(dr, "InteresMensual"),
                        InteresDiario = SqlReaderHelper.ValorReaderDecimal(dr, "InteresDiario"),
                        InteresTotal = SqlReaderHelper.ValorReaderDecimal(dr, "InteresTotal"),
                        TotalCobrar = SqlReaderHelper.ValorReaderDecimal(dr, "TotalCobrar"),
                        ImporteCuota = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteCuota"),
                        Mensaje = SqlReaderHelper.ValorReaderString(dr, "Mensaje"),
                        TeaReferencial = SqlReaderHelper.ValorReaderDecimal(dr, "TeaReferencial"),
                        NroCuotasCompletas= SqlReaderHelper.ValorReaderInt(dr, "NroCuotasCompletas"),
                    };
                }

                return item;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.SimularAsync");
                throw;
            }
        }

        public async Task<List<AlmacenSelectDto>> ListarAlmacenesAsync(CancellationToken cancellationToken)
        {
            try
            {
                var result = new List<AlmacenSelectDto>();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("dbo.p_almacen_list", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    result.Add(new AlmacenSelectDto
                    {
                        IdAlmacen = SqlReaderHelper.ValorReaderString(dr, "IdAlmacen"),
                        NombreAlmacen = SqlReaderHelper.ValorReaderString(dr, "NombreAlmacen")
                    });
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.ListarAlmacenesAsync");
                throw;
            }
        }

        public async Task<SpResultDto?> InsertarGarantiaAsync(PrestamoCreateRequestDto request, int idPrestamo, CancellationToken cancellationToken)
        {
            try
            {
                SpResultDto? item = null;

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("prest.p_prestamo_garantia_ins", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.AddWithValue("@Id_Prestamo", idPrestamo);
                cmd.Parameters.AddWithValue("@Tipo_Garantia", (object?)request.TipoGarantia ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Descripcion", (object?)request.DescripcionGarantia ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Marca", (object?)request.MarcaGarantia ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Modelo", (object?)request.ModeloGarantia ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Serie", (object?)request.SerieGarantia ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Estado_Articulo", (object?)request.EstadoGarantia ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Valor_Referencial", (object?)request.ValorGarantia ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Fecha_Recepcion", DBNull.Value);
                cmd.Parameters.AddWithValue("@Observacion", (object?)request.ObservacionGarantia ?? DBNull.Value);

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                if (await dr.ReadAsync(cancellationToken))
                {
                    item = new SpResultDto
                    {
                        Ok = SqlReaderHelper.ValorReaderBool(dr, "Ok"),
                        RowsAffected = SqlReaderHelper.ValorReaderInt(dr, "RowsAffected"),
                        Mensaje = SqlReaderHelper.ValorReaderString(dr, "Mensaje"),
                        IdGenerado = SqlReaderHelper.ValorReaderInt(dr, "IdGenerado")
                    };
                }

                return item;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.InsertarGarantiaAsync");
                throw;
            }
        }

        public async Task<DbActionResult> RegistrarDesembolsoAsync(
    PrestamoRegistrarDesembolsoRequestDto request,
    string usuario,
    string? estacion,
    CancellationToken cancellationToken)
        {
            try
            {
                var result = new DbActionResult();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("prest.p_prestamo_registrar_desembolso", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.AddWithValue("@Id_Prestamo", request.IdPrestamo);
                cmd.Parameters.AddWithValue("@Cod_CajaChica", (object?)request.CodCajaChicaDesembolso ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Importe", request.ImpDesembolso);
                cmd.Parameters.AddWithValue("@Fec_Desembolso", request.FecDesembolso);
                cmd.Parameters.AddWithValue("@Glosa", (object?)request.GlosaDesembolso ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@CodUsuario", Convert.ToInt32(usuario));
                cmd.Parameters.AddWithValue("@CodEstacion", (object?)estacion ?? DBNull.Value);

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                if (await dr.ReadAsync(cancellationToken))
                {
                    result.Ok = SqlReaderHelper.ValorReaderBool(dr, "Ok");
                    result.Mensaje = SqlReaderHelper.ValorReaderString(dr, "Mensaje");
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.RegistrarDesembolsoAsync");
                throw;
            }
        }

        public async Task<List<PrestamoDesembolsoListadoDto>> ListarDesembolsosAsync(
    int idPrestamo,
    CancellationToken cancellationToken)
        {
            try
            {
                var lista = new List<PrestamoDesembolsoListadoDto>();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("prest.p_prestamo_desembolso_listar", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.AddWithValue("@Id_Prestamo", idPrestamo);

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    lista.Add(new PrestamoDesembolsoListadoDto
                    {
                        IdDesembolso = dr["Id_Desembolso"] == DBNull.Value ? 0 : Convert.ToInt32(dr["Id_Desembolso"]),
                        IdPrestamo = dr["Id_Prestamo"] == DBNull.Value ? 0 : Convert.ToInt32(dr["Id_Prestamo"]),
                        Secuencia = dr["Secuencia"] == DBNull.Value ? 0 : Convert.ToInt32(dr["Secuencia"]),
                        FecDesembolso = dr["Fec_Desembolso"] == DBNull.Value ? DateTime.MinValue : Convert.ToDateTime(dr["Fec_Desembolso"]),
                        CodCajaChica = dr["Cod_CajaChica"] == DBNull.Value ? "" : dr["Cod_CajaChica"].ToString()!,
                        DesCajaChica = dr["DesCajaChica"] == DBNull.Value ? "" : dr["DesCajaChica"].ToString()!,
                        Importe = dr["Importe"] == DBNull.Value ? 0 : Convert.ToDecimal(dr["Importe"]),
                        CodTipDoc = dr["Cod_TipDoc"] == DBNull.Value ? "" : dr["Cod_TipDoc"].ToString()!,
                        SerDocum = dr["Ser_docum"] == DBNull.Value ? "" : dr["Ser_docum"].ToString()!,
                        NumDocum = dr["Num_Docum"] == DBNull.Value ? "" : dr["Num_Docum"].ToString()!,
                        Documento = dr["Documento"] == DBNull.Value ? "" : dr["Documento"].ToString()!,
                        Glosa = dr["Glosa"] == DBNull.Value ? "" : dr["Glosa"].ToString()!,
                        NroCobranza = dr["NroCobranza"] == DBNull.Value ? "" : dr["NroCobranza"].ToString()!,
                        NumCuota = dr["NumCuota"] == DBNull.Value ? (int?)null : Convert.ToInt32(dr["NumCuota"]),
                        CodAlmacen = dr["Cod_Almacen"] == DBNull.Value ? "" : dr["Cod_Almacen"].ToString()!,
                        NumMovstk = dr["Num_Movstk"] == DBNull.Value ? (int?)null : Convert.ToInt32(dr["Num_Movstk"]),
                        NumTransaccion = dr["Num_Transaccion"] == DBNull.Value ? (int?)null : Convert.ToInt32(dr["Num_Transaccion"]),
                        SecMovimiento = dr["Sec_Movimiento"] == DBNull.Value ? (int?)null : Convert.ToInt32(dr["Sec_Movimiento"]),
                        CodUsuarioCreacion = dr["Cod_Usuario_Creacion"] == DBNull.Value ? (int?)null : Convert.ToInt32(dr["Cod_Usuario_Creacion"]),
                        FecCreacion = dr["Fec_Creacion"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(dr["Fec_Creacion"]),
                        CodEstacion = dr["Cod_Estacion"] == DBNull.Value ? "" : dr["Cod_Estacion"].ToString()!
                    });
                }

                return lista;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.ListarDesembolsosAsync");
                throw;
            }
        }
        public async Task<List<PrestamoPagoListadoDto>> ListarPagosAsync(
     int idPrestamo,
    CancellationToken cancellationToken)
        {
            try
            {
                var lista = new List<PrestamoPagoListadoDto>();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("prest.p_prestamo_pago_listar", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.AddWithValue("@Id_Prestamo", idPrestamo);

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    lista.Add(new PrestamoPagoListadoDto
                    {
                        NumCuota = dr["numCuota"] == DBNull.Value ? 0 : Convert.ToInt32(dr["numCuota"]),
                        FecPago = dr["fecPago"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(dr["fecPago"]),
                        FormaPago = dr["formaPago"] == DBNull.Value ? "" : dr["formaPago"].ToString()!,
                        CajaBanco = dr["cajaBanco"] == DBNull.Value ? "" : dr["cajaBanco"].ToString()!,
                        Importe = dr["importe"] == DBNull.Value ? 0 : Convert.ToDecimal(dr["importe"]),
                        Deuda = dr["deuda"] == DBNull.Value ? 0 : Convert.ToDecimal(dr["deuda"]),
                        Saldo = dr["saldo"] == DBNull.Value ? 0 : Convert.ToDecimal(dr["saldo"]),
                        Glosa = dr["glosa"] == DBNull.Value ? "" : dr["glosa"].ToString()!
                    });
                }

                return lista;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.ListarPagosAsync");
                throw;
            }
        }

        public async Task<DbActionResult> RegistrarPagoAsync(
    PrestamoRegistrarPagoRequestDto request,
    string usuario,
    string? estacion,
    CancellationToken cancellationToken)
        {
            try
            {
                var result = new DbActionResult();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("dbo.FI_Cobranza_RegistrarPago_Prestamo", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.AddWithValue("@prest_id", request.IdPrestamo);
                cmd.Parameters.AddWithValue("@Cod_Almacen", "PR"); // luego podemos resolverlo real
                cmd.Parameters.AddWithValue("@ImportePago", request.ImportePago);
                cmd.Parameters.AddWithValue("@Fec_Pago", request.FecPago);
                cmd.Parameters.AddWithValue("@IdFormaPago", request.IdFormaPago);
                cmd.Parameters.AddWithValue("@Cod_CajaChica", request.CodCajaChica);
                cmd.Parameters.AddWithValue("@BancoId", DBNull.Value);
                cmd.Parameters.AddWithValue("@CuentaBancoId", DBNull.Value);
                cmd.Parameters.AddWithValue("@Glosa", (object?)request.GlosaPago ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@CodUsuarioCreacion", Convert.ToInt32(usuario));
                cmd.Parameters.AddWithValue("@CodEstacion", (object?)estacion ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@PermitirExcedente", request.PermitirExcedente);

                // temporal: sacar del préstamo luego, por ahora valores base
                //cmd.Parameters.AddWithValue("@Cod_TipAnex", "C");
                //cmd.Parameters.AddWithValue("@Cod_Anxo", "000001");
                //cmd.Parameters.AddWithValue("@Cod_TipDoc", "14");
                //cmd.Parameters.AddWithValue("@Ser_docum", "");
                //cmd.Parameters.AddWithValue("@Num_Docum", "");

                var okParam = new SqlParameter("@Ok", SqlDbType.Bit)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(okParam);

                var msgParam = new SqlParameter("@Mensaje", SqlDbType.VarChar, 500)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(msgParam);

                await cn.OpenAsync(cancellationToken);
                await cmd.ExecuteNonQueryAsync(cancellationToken);

                result.Ok = okParam.Value != DBNull.Value && Convert.ToBoolean(okParam.Value);
                result.Mensaje = msgParam.Value == DBNull.Value ? "" : msgParam.Value.ToString();

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.RegistrarPagoAsync");
                throw;
            }
        }

        public async Task<List<PrestamoConceptoDto>> ListarConceptosAsync(CancellationToken cancellationToken)
        {
            try
            {
                var result = new List<PrestamoConceptoDto>();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("prest.p_concepto_listar", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    result.Add(new PrestamoConceptoDto
                    {
                        Cod_Concepto = SqlReaderHelper.ValorReaderString(dr, "Cod_Concepto"),
                        Nombre = SqlReaderHelper.ValorReaderString(dr, "Nombre"),
                        Flag_Activo = SqlReaderHelper.ValorReaderString(dr, "Flag_Activo"),
                        OrdenVisual = SqlReaderHelper.ValorReaderInt(dr, "OrdenVisual")
                    });
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.ListarConceptosAsync");
                throw;
            }
        }

        public async Task<PrestamoDetalleDto?> ObtenerDetalleAsync(int idPrestamo, CancellationToken cancellationToken)
        {
            using var cn = new SqlConnection(GetConnectionString());
            using var cmd = new SqlCommand("prest.p_prestamo_detalle_consolidado", cn)
            {
                CommandType = CommandType.StoredProcedure
            };

            cmd.Parameters.Add("@Id_Prestamo", SqlDbType.Int).Value = idPrestamo;

            await cn.OpenAsync(cancellationToken);
            using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

            PrestamoDetalleDto? dto = null;

            // Resultset 1: Cabecera
            if (await dr.ReadAsync(cancellationToken))
            {
                dto = new PrestamoDetalleDto
                {
                    Cabecera = new PrestamoDetalleCabeceraDto
                    {
                        IdPrestamo = SqlReaderHelper.ValorReaderInt(dr, "Id_Prestamo"),
                        Fecha = SqlReaderHelper.ValorReaderDateTime(dr, "Fecha"),
                        Capital = SqlReaderHelper.ValorReaderDecimal(dr, "Capital"),
                        NroCuotas = SqlReaderHelper.ValorReaderInt(dr, "Nro_Cuotas"),
                        PorcInteresMensual = SqlReaderHelper.ValorReaderDecimal(dr, "PorcInteresMensual"),
                        TotalCobrar = SqlReaderHelper.ValorReaderDecimal(dr, "TotalCobrar"),
                        CodConcepto = SqlReaderHelper.ValorReaderString(dr, "Cod_Concepto"),
                        Observacion = SqlReaderHelper.ValorReaderString(dr, "Observacion"),
                        TotalDesembolsado = SqlReaderHelper.ValorReaderDecimal(dr, "TotalDesembolsado"),
                        TotalPagado = SqlReaderHelper.ValorReaderDecimal(dr, "TotalPagado"),
                        SaldoPendiente = SqlReaderHelper.ValorReaderDecimal(dr, "SaldoPendiente")
                    }
                };
            }

            if (dto == null)
                return null;

            // Resultset 2: Cuotas
            if (await dr.NextResultAsync(cancellationToken))
            {
                while (await dr.ReadAsync(cancellationToken))
                {
                    dto.Cuotas.Add(new PrestamoDetalleCuotaDto
                    {
                        NumCuota = SqlReaderHelper.ValorReaderInt(dr, "NumCuota"),
                        FecVenc = dr["Fec_Venc"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(dr["Fec_Venc"]),
                        ImporteBase = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteBase"),
                        ImporteInteres = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteInteres"),
                        ImpCuota = SqlReaderHelper.ValorReaderDecimal(dr, "ImpCuota"),
                        Pagado = SqlReaderHelper.ValorReaderDecimal(dr, "Pagado"),
                        Saldo = SqlReaderHelper.ValorReaderDecimal(dr, "Saldo"),
                        FlgStatusPago = SqlReaderHelper.ValorReaderString(dr, "FlgStatusPago")
                    });
                }
            }

            // Resultset 3: Pagos
            if (await dr.NextResultAsync(cancellationToken))
            {
                while (await dr.ReadAsync(cancellationToken))
                {
                    dto.Pagos.Add(new PrestamoDetallePagoDto
                    {
                        FecPago = dr["Fec_Pago"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(dr["Fec_Pago"]),
                        Importe = SqlReaderHelper.ValorReaderDecimal(dr, "Importe"),
                        FormaPago = SqlReaderHelper.ValorReaderString(dr, "FormaPago"),
                        Glosa = SqlReaderHelper.ValorReaderString(dr, "Glosa")
                    });
                }
            }

            // Resultset 4: Desembolsos
            if (await dr.NextResultAsync(cancellationToken))
            {
                while (await dr.ReadAsync(cancellationToken))
                {
                    dto.Desembolsos.Add(new PrestamoDetalleDesembolsoDto
                    {
                        FecDesembolso = dr["Fec_Desembolso"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(dr["Fec_Desembolso"]),
                        Importe = SqlReaderHelper.ValorReaderDecimal(dr, "Importe"),
                        CodCajaChica = SqlReaderHelper.ValorReaderString(dr, "Cod_CajaChica"),
                        Glosa = SqlReaderHelper.ValorReaderString(dr, "Glosa")
                    });
                }
            }

            return dto;
        }

    }
}
