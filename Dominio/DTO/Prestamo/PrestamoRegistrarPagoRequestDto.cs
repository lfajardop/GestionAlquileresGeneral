using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoRegistrarPagoRequestDto
    {
        public int IdPrestamo { get; set; }
        public string NroCobranza { get; set; } = string.Empty;
        public DateTime FecPago { get; set; }
        public int IdFormaPago { get; set; }
        public string CodCajaChica { get; set; } = string.Empty;
        public decimal ImportePago { get; set; }
        public string? GlosaPago { get; set; }
        public bool PermitirExcedente { get; set; }
        public string Cod_Concepto { get; set; } = string.Empty;

    }
}
