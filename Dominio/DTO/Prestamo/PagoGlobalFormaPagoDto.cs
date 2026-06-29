namespace Dominio.DTO.Prestamo
{
    public class PagoGlobalFormaPagoDto
    {
        public int IdFormaPago { get; set; }
        public string CodCajaChica { get; set; } = string.Empty;
        public decimal Importe { get; set; }
    }
}
