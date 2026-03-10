using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Common
{
    public class DbActionResult
    {
        public bool Ok { get; set; }

        public int RowsAffected { get; set; }

        public string Mensaje { get; set; } = string.Empty;

        public int? IdGenerado { get; set; }

        public string? CodigoGenerado { get; set; }
    }
}
