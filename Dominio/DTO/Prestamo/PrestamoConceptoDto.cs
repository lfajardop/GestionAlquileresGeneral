using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoConceptoDto
    {
        public string Cod_Concepto { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string Flag_Activo { get; set; }
        public int OrdenVisual { get; set; }
        
    }
}
