using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Cobranza
{
    public class CobranzaPendienteDto
    {
        public string NroCobranza { get; set; } = string.Empty;
        public string TipoOrigen { get; set; } = string.Empty; // PR, CU, AU, DI
        public string Cliente { get; set; } = string.Empty;
        public string Documento { get; set; } = string.Empty;
        public DateTime FechaVencimiento { get; set; }
        public decimal ImporteCuota { get; set; }
        public decimal ImporteCancelado { get; set; }
        public decimal Saldo { get; set; }
        public int DiasAtraso { get; set; }
        public string Estado { get; set; } = string.Empty;
        public string Glosa { get; set; } = string.Empty;
    }
}
