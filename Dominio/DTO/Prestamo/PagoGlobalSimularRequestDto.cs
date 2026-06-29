namespace Dominio.DTO.Prestamo
{
    public class PagoGlobalSimularRequestDto
    {
        public string Cod_TipAnex { get; set; } = string.Empty;
        public string Cod_Anxo { get; set; } = string.Empty;
        public decimal ImportePago { get; set; }
        public string SoloVencidas { get; set; } = "N";
    }
}
