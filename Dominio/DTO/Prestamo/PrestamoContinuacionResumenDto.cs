using System;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoContinuacionResumenDto
    {
        public bool Ok { get; set; }
        public string Mensaje { get; set; } = string.Empty;
        public int Id_Prestamo { get; set; }
        public string Cliente { get; set; } = string.Empty;
        public string NroCobranza { get; set; } = string.Empty;
        public string Cod_Almacen { get; set; } = string.Empty;
        public DateTime FechaDesde { get; set; }
        public DateTime FechaHasta { get; set; }
        public decimal CapitalBase { get; set; }
        public decimal PorcInteresMensual { get; set; }
        public string FrecuenciaPago { get; set; } = string.Empty;
        public int NroCuotas { get; set; }
        public decimal InteresTotal { get; set; }
        public decimal TotalGenerado { get; set; }
    }
}
