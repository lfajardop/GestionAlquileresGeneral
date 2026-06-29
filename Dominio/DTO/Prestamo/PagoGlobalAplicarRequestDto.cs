using System;
using System.Collections.Generic;

namespace Dominio.DTO.Prestamo
{
    public class PagoGlobalAplicarRequestDto
    {
        public string Cod_TipAnex { get; set; } = string.Empty;
        public string Cod_Anxo { get; set; } = string.Empty;
        public decimal ImportePago { get; set; }
        public DateTime FecPago { get; set; }
        public int IdFormaPago { get; set; }
        public string CodCajaChica { get; set; } = string.Empty;
        public string? Glosa { get; set; }
        public bool PermitirExcedente { get; set; }
        public List<PagoGlobalFormaPagoDto> FormasPago { get; set; } = new();
    }
}
