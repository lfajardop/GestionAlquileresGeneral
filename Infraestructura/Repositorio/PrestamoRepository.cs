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
                cmd.Parameters.AddWithValue("@Observacion", (object?)request.Observacion ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Usu", (object?)usuario ?? DBNull.Value);

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
                        Mensaje = SqlReaderHelper.ValorReaderString(dr, "Mensaje")
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

    }
}
