namespace Dominio.DTO.Reporte
{
    public class ReporteEstadoCuentaClienteDto
    {
        public string CodTipAnex { get; set; } = "";
        public string CodAnxo { get; set; } = "";
        public string Cliente { get; set; } = "";
        public string Documento { get; set; } = "";
        public DateTime FechaEmision { get; set; } = DateTime.Now;
        public ReporteEstadoCuentaResumenDto Resumen { get; set; } = new();
        public List<ReporteEstadoCuentaPrestamoDto> Prestamos { get; set; } = new();
        public List<ReporteEstadoCuentaCuotaDto> Cuotas { get; set; } = new();
        public List<ReporteEstadoCuentaPagoDto> Pagos { get; set; } = new();
        public List<ReporteEstadoCuentaCompensacionDto> Compensaciones { get; set; } = new();
    }

    public class ReporteEstadoCuentaResumenDto
    {
        public int CantPrestamos { get; set; }
        public decimal TotalCapital { get; set; }
        public decimal TotalInteres { get; set; }
        public decimal TotalProgramado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal TotalPagosRecibidos { get; set; }
        public decimal TotalCompensado { get; set; }
        public decimal SaldoPendiente { get; set; }
        public decimal SaldoVencido { get; set; }
        public int CuotasVencidas { get; set; }
        public int DiasAtraso { get; set; }
        public DateTime? ProximoVencimiento { get; set; }
    }

    public class ReporteEstadoCuentaPrestamoDto
    {
        public int IdPrestamo { get; set; }
        public DateTime Fecha { get; set; }
        public string Concepto { get; set; } = "";
        public decimal Capital { get; set; }
        public decimal Interes { get; set; }
        public decimal TotalProgramado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal SaldoPendiente { get; set; }
        public int NroCuotas { get; set; }
        public int CuotasVencidas { get; set; }
        public int DiasAtraso { get; set; }
        public string Estado { get; set; } = "";
    }

    public class ReporteEstadoCuentaCuotaDto
    {
        public int IdPrestamo { get; set; }
        public int NumCuota { get; set; }
        public DateTime? FechaVencimiento { get; set; }
        public decimal Capital { get; set; }
        public decimal Interes { get; set; }
        public decimal Importe { get; set; }
        public decimal Pagado { get; set; }
        public decimal Saldo { get; set; }
        public string Estado { get; set; } = "";
        public int DiasAtraso { get; set; }
    }

    public class ReporteEstadoCuentaPagoDto
    {
        public int IdPrestamo { get; set; }
        public int NumCuota { get; set; }
        public DateTime? FechaPago { get; set; }
        public string FormaPago { get; set; } = "";
        public string CajaBanco { get; set; } = "";
        public decimal Importe { get; set; }
        public string Glosa { get; set; } = "";
    }

    public class ReporteEstadoCuentaCompensacionDto
    {
        public int IdCompensacion { get; set; }
        public string Numero { get; set; } = "";
        public DateTime Fecha { get; set; }
        public string Concepto { get; set; } = "";
        public string Referencia { get; set; } = "";
        public string Prestamos { get; set; } = "";
        public int CuotasAfectadas { get; set; }
        public decimal Importe { get; set; }
        public string EstadoCodigo { get; set; } = "";
        public string Estado { get; set; } = "";
        public string Observacion { get; set; } = "";
    }
}
