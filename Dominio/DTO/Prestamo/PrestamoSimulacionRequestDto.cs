using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoSimulacionRequestDto
    {
        public decimal Capital { get; set; }
        public string TipoInteres { get; set; } = "M";
        public string TipoModalidad { get; set; } = "C";
     
        public decimal PorcInteresMensual { get; set; }
        public string FrecuenciaPago { get; set; } = "M";
        public DateTime FechaInicioCobro { get; set; }
        public DateTime FechaFinCobro { get; set; }
    }
}
