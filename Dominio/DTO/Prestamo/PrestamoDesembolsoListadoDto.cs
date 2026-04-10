using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoDesembolsoListadoDto
    {
        public int IdDesembolso { get; set; }
        public int IdPrestamo { get; set; }
        public int Secuencia { get; set; }
        public DateTime FecDesembolso { get; set; }
        public string CodCajaChica { get; set; } = string.Empty;
        public string DesCajaChica { get; set; } = string.Empty;
        public decimal Importe { get; set; }
        public string CodTipDoc { get; set; } = string.Empty;
        public string SerDocum { get; set; } = string.Empty;
        public string NumDocum { get; set; } = string.Empty;
        public string Documento { get; set; } = string.Empty;
        public string Glosa { get; set; } = string.Empty;
        public string NroCobranza { get; set; } = string.Empty;
        public int? NumCuota { get; set; }
        public string CodAlmacen { get; set; } = string.Empty;
        public int? NumMovstk { get; set; }
        public int? NumTransaccion { get; set; }
        public int? SecMovimiento { get; set; }
        public int? CodUsuarioCreacion { get; set; }
        public DateTime? FecCreacion { get; set; }
        public string CodEstacion { get; set; } = string.Empty;
    }
}
