using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoSimulacionDto
    {
        public bool Ok { get; set; }
        public int NroCuotas { get; set; }
        public int NroCuotasCompletas { get; set; }
        public int DiasProrrateados { get; set; }
        public decimal InteresMensual { get; set; }
        public decimal InteresDiario { get; set; }
        public decimal InteresTotal { get; set; }
        public decimal TotalCobrar { get; set; }
        public decimal ImporteCuota { get; set; }
        public decimal ImporteUltimaCuota { get; set; }
        public decimal TeaReferencial { get; set; }
        public string Mensaje { get; set; } = string.Empty;
    }
}
