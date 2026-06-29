using System;
using System.Collections.Generic;

namespace Dominio.DTO.Reporte
{
    public class ReporteDeudaActualFiltroDto
    {
        public DateTime? FechaDesde { get; set; }
        public DateTime? FechaHasta { get; set; }
        public string Cliente { get; set; } = string.Empty;
        public string Estado { get; set; } = string.Empty;
    }

    public class ReporteDeudaActualClienteDto
    {
        public string CodTipAnex { get; set; } = string.Empty;
        public string CodAnxo { get; set; } = string.Empty;
        public string Cliente { get; set; } = string.Empty;
        public string Documento { get; set; } = string.Empty;
        public int CantPrestamos { get; set; }
        public int CuotasPendientes { get; set; }
        public int CuotasVencidas { get; set; }
        public decimal TotalProgramado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal TotalSaldo { get; set; }
        public decimal TotalVencido { get; set; }
        public DateTime? PrimerVencimiento { get; set; }
        public int DiasAtraso { get; set; }
    }

    public class ReporteDeudaActualTotalesDto
    {
        public int TotalClientes { get; set; }
        public int TotalPrestamos { get; set; }
        public int TotalCuotasPendientes { get; set; }
        public int TotalCuotasVencidas { get; set; }
        public decimal TotalProgramado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal TotalSaldo { get; set; }
        public decimal TotalVencido { get; set; }
    }

    public class ReporteDeudaActualResponseDto
    {
        public List<ReporteDeudaActualClienteDto> Detalle { get; set; } = new();
        public ReporteDeudaActualTotalesDto Totales { get; set; } = new();
    }
}
