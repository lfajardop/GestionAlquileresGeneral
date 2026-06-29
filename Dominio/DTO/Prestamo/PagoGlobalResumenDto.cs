namespace Dominio.DTO.Prestamo
{
    public class PagoGlobalResumenDto
    {
        public bool Ok { get; set; }
        public string Mensaje { get; set; } = string.Empty;
        public decimal ImportePago { get; set; }
        public decimal ImporteAplicado { get; set; }
        public decimal ImporteExcedente { get; set; }
        public int CuotasAplicadas { get; set; }
        public int PrestamosAplicados { get; set; }
    }
}
