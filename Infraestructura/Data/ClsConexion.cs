using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Infraestructura.Seguridad;
using Microsoft.Extensions.Options;


namespace Infraestructura.Data
{
    public class ClsConexion
    {
        private readonly string _connectionStringMain;
        private readonly string _connectionStringAuth;

        public ClsConexion(IOptions<SqlConfig> dbConfig)
        {
            var config = dbConfig.Value;

            if (string.IsNullOrEmpty(config.sConnect) || string.IsNullOrEmpty(config.ConexionDBOAuth))
                throw new Exception("Faltan cadenas de conexión en la configuración.");

            _connectionStringMain = Criptografia.Desencriptar(config.sConnect);
            _connectionStringAuth = Criptografia.Desencriptar(config.ConexionDBOAuth);
        }

        // Métodos para obtener la que necesites
        public string GetConnectionString() => _connectionStringMain;
        public string GetOAuthConnection() => _connectionStringAuth;
    }
}
