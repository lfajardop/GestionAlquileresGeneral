using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infraestructura.Data
{
    public class SqlConfig
    {
        public string sConnect { get; set; }
        public string ConexionDBOAuth { get; set; }
        public int CommandTimeoutSegundos { get; set; }
    }
}
