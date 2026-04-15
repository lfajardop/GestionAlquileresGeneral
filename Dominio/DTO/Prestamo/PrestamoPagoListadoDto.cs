using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoPagoListadoDto
    {
        public int NumCuota { get; set; }
        public DateTime? FecPago { get; set; }
        public string FormaPago { get; set; } = string.Empty;
        public string CajaBanco { get; set; } = string.Empty;
        public decimal Importe { get; set; }
        public decimal Deuda { get; set; }
        public decimal Saldo { get; set; }
        public string Glosa { get; set; } = string.Empty;
    }
}
