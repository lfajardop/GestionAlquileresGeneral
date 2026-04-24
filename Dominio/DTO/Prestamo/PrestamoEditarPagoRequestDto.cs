using System;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoEditarPagoRequestDto
    {
        public int IdPrestamo { get; set; }
        public int IdPago { get; set; }
        public decimal Importe { get; set; }
        public DateTime FecPago { get; set; }
        public string? Glosa { get; set; }
        public bool PermitirExcedente { get; set; }
    }
}