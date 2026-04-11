using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoRegistrarDesembolsoRequestDto
    {
        public int IdPrestamo { get; set; }
        public int? FormaPagoDesembolso { get; set; }
        public string? CodCajaChicaDesembolso { get; set; }
        public DateTime FecDesembolso { get; set; }
        public decimal ImpDesembolso { get; set; }
        public string? GlosaDesembolso { get; set; }
    }
}
