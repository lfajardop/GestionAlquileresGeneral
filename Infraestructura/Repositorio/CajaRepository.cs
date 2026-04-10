using Dominio.CajaChica;
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
    public class CajaRepository : ClsConexion, ICajaRepository
    {
        private readonly SqlConfig _sqlConfig;
        private readonly ILogger<CajaRepository> _logger;

        public CajaRepository(IOptions<SqlConfig> sqlConfig, ILogger<CajaRepository> logger) : base(sqlConfig)
        {
            _sqlConfig = sqlConfig.Value;
            _logger = logger;
        }

        public async Task<List<CajaChicaDto>> ListarCajasPorBancoAsync(string flgEsBanco, CancellationToken cancellationToken)
        {
            try
            {
                var lista = new List<CajaChicaDto>();

                using var cn = new SqlConnection(GetConnectionString());
                using var cmd = new SqlCommand("dbo.CJ_CajaChica_Listar_PorBanco", cn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@Flg_EsBanco", flgEsBanco);

                await cn.OpenAsync(cancellationToken);
                using var dr = await cmd.ExecuteReaderAsync(cancellationToken);

                while (await dr.ReadAsync(cancellationToken))
                {
                    lista.Add(new CajaChicaDto
                    {
                        CodCajaChica = dr["Cod_CajaChica"] == DBNull.Value ? "" : dr["Cod_CajaChica"].ToString()!,
                        DesCajaChica = dr["Des_CajaChica"] == DBNull.Value ? "" : dr["Des_CajaChica"].ToString()!
                    });
                }

                return lista;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoRepository.ListarCajasPorBancoAsync");
                throw;
            }
        }
    }
}