using System;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoContinuacionSimularRequestDto
    {
        public int Id_Prestamo { get; set; }
        public DateTime FechaHasta { get; set; }
        public decimal? PorcInteresMensual { get; set; }
        public string? FrecuenciaPago { get; set; }
        public decimal? CapitalBase { get; set; }
    }
}
