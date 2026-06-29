using System;

namespace Dominio.DTO.Prestamo
{
    public class PagoGlobalDetalleDto
    {
        public int OrdenAplicacion { get; set; }
        public int Id_Prestamo { get; set; }
        public string Cliente { get; set; } = string.Empty;
        public string NroCobranza { get; set; } = string.Empty;
        public int NumCuota { get; set; }
        public string Cod_Almacen { get; set; } = string.Empty;
        public DateTime? Fec_Venc { get; set; }
        public decimal DeudaAntes { get; set; }
        public decimal ImporteAplicado { get; set; }
        public decimal SaldoDespues { get; set; }
    }
}
