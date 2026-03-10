using Dominio.DTO.Cobranza;
using Infraestructura.Data;
using Infraestructura.Interfaces;
using Microsoft.Data.SqlClient;
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
    public class CobranzaRepository: ClsConexion, ICobranzaRepository
    {
        private readonly SqlConfig _sqlConfig;
        private readonly ILogger<CobranzaRepository> _logger;

       public CobranzaRepository(IOptions<SqlConfig> sqlConfig, ILogger<CobranzaRepository> logger) : base(sqlConfig)
        {
            _sqlConfig = sqlConfig.Value;
            _logger = logger;
        }

        public async Task<CobranzaResumenDto?> ObtenerResumenAsync(CancellationToken cancellationToken)
        {
            try
            {
                CobranzaResumenDto? item = null;

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("dbo.p_cobranza_resumen_dashboard", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                if (await dr.ReadAsync(cancellationToken))
                {
                    item = new CobranzaResumenDto
                    {
                        TotalPorCobrar = SqlReaderHelper.ValorReaderDecimal(dr, "TotalPorCobrar"),
                        TotalVencido = SqlReaderHelper.ValorReaderDecimal(dr, "TotalVencido"),
                        TotalPorVencer14Dias = SqlReaderHelper.ValorReaderDecimal(dr, "TotalPorVencer14Dias"),
                        CantPrestamosPendientes = SqlReaderHelper.ValorReaderInt(dr, "CantPrestamosPendientes"),
                        CantAlquileresPendientes = SqlReaderHelper.ValorReaderInt(dr, "CantAlquileresPendientes"),
                        CantRentasPorVencer = SqlReaderHelper.ValorReaderInt(dr, "CantRentasPorVencer")
                    };
                }

                return item;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en CobranzaRepository.ObtenerResumenAsync");
                throw;
            }
        }

        public async Task<List<CobranzaPendienteDto>> ListarPrestamosPendientesAsync(CancellationToken cancellationToken)
        {
            try
            {
                var result = new List<CobranzaPendienteDto>();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("dbo.p_cobranza_prestamos_pendientes", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    result.Add(new CobranzaPendienteDto
                    {
                        NroCobranza = SqlReaderHelper.ValorReaderString(dr, "NroCobranza"),
                        TipoOrigen = SqlReaderHelper.ValorReaderString(dr, "TipoOrigen"),
                        Cliente = SqlReaderHelper.ValorReaderString(dr, "Cliente"),
                        Documento = SqlReaderHelper.ValorReaderString(dr, "Documento"),
                        FechaVencimiento = SqlReaderHelper.ValorReaderDateTime(dr, "FechaVencimiento"),
                        ImporteCuota = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteCuota"),
                        ImporteCancelado = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteCancelado"),
                        Saldo = SqlReaderHelper.ValorReaderDecimal(dr, "Saldo"),
                        DiasAtraso = SqlReaderHelper.ValorReaderInt(dr, "DiasAtraso"),
                        Estado = SqlReaderHelper.ValorReaderString(dr, "Estado"),
                        Glosa = SqlReaderHelper.ValorReaderString(dr, "Glosa")
                    });
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en CobranzaRepository.ListarPrestamosPendientesAsync");
                throw;
            }
        }

        public async Task<List<CobranzaPendienteDto>> ListarAlquileresPendientesAsync(CancellationToken cancellationToken)
        {
            try
            {
                var result = new List<CobranzaPendienteDto>();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("dbo.p_cobranza_alquileres_pendientes", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    result.Add(new CobranzaPendienteDto
                    {
                        NroCobranza = SqlReaderHelper.ValorReaderString(dr, "NroCobranza"),
                        TipoOrigen = SqlReaderHelper.ValorReaderString(dr, "TipoOrigen"),
                        Cliente = SqlReaderHelper.ValorReaderString(dr, "Cliente"),
                        Documento = SqlReaderHelper.ValorReaderString(dr, "Documento"),
                        FechaVencimiento = SqlReaderHelper.ValorReaderDateTime(dr, "FechaVencimiento"),
                        ImporteCuota = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteCuota"),
                        ImporteCancelado = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteCancelado"),
                        Saldo = SqlReaderHelper.ValorReaderDecimal(dr, "Saldo"),
                        DiasAtraso = SqlReaderHelper.ValorReaderInt(dr, "DiasAtraso"),
                        Estado = SqlReaderHelper.ValorReaderString(dr, "Estado"),
                        Glosa = SqlReaderHelper.ValorReaderString(dr, "Glosa")
                    });
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en CobranzaRepository.ListarAlquileresPendientesAsync");
                throw;
            }
        }

        public async Task<List<CobranzaPendienteDto>> ListarRentasPorVencerAsync(CancellationToken cancellationToken)
        {
            try
            {
                var result = new List<CobranzaPendienteDto>();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("dbo.p_cobranza_rentas_por_vencer", cn);
                cmd.CommandType = CommandType.StoredProcedure;

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    result.Add(new CobranzaPendienteDto
                    {
                        NroCobranza = SqlReaderHelper.ValorReaderString(dr, "NroCobranza"),
                        TipoOrigen = SqlReaderHelper.ValorReaderString(dr, "TipoOrigen"),
                        Cliente = SqlReaderHelper.ValorReaderString(dr, "Cliente"),
                        Documento = SqlReaderHelper.ValorReaderString(dr, "Documento"),
                        FechaVencimiento = SqlReaderHelper.ValorReaderDateTime(dr, "FechaVencimiento"),
                        ImporteCuota = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteCuota"),
                        ImporteCancelado = SqlReaderHelper.ValorReaderDecimal(dr, "ImporteCancelado"),
                        Saldo = SqlReaderHelper.ValorReaderDecimal(dr, "Saldo"),
                        DiasAtraso = SqlReaderHelper.ValorReaderInt(dr, "DiasAtraso"),
                        Estado = SqlReaderHelper.ValorReaderString(dr, "Estado"),
                        Glosa = SqlReaderHelper.ValorReaderString(dr, "Glosa")
                    });
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en CobranzaRepository.ListarRentasPorVencerAsync");
                throw;
            }
        }

      
    }
}
