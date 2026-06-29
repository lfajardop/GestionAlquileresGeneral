using System;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoContinuacionDetalleDto
    {
        public int Num_Secuencia { get; set; }
        public DateTime Fecha_Desde { get; set; }
        public DateTime Fecha_Hasta { get; set; }
        public DateTime Fec_Venc { get; set; }
        public decimal Imp_Base { get; set; }
        public decimal Imp_Interes { get; set; }
        public decimal Imp_Cuota { get; set; }
    }
}
