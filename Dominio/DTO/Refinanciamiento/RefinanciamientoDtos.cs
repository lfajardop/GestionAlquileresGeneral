namespace Dominio.DTO.Refinanciamiento;

public class RefinanciamientoPrestamoDto
{
    public int IdPrestamo { get; set; }
    public DateTime Fecha { get; set; }
    public decimal Capital { get; set; }
    public decimal TotalCobrar { get; set; }
    public decimal PorcInteresMensual { get; set; }
    public string FrecuenciaPago { get; set; } = "";
    public DateTime FechaFinCobro { get; set; }
    public string Concepto { get; set; } = "";
    public decimal CapitalPendiente { get; set; }
    public decimal InteresVencido { get; set; }
    public decimal InteresFuturoExcluido { get; set; }
    public decimal SaldoProgramado { get; set; }
    public decimal TotalPagado { get; set; }
    public int CuotasVencidas { get; set; }
}

public class RefinanciamientoCalcularRequestDto
{
    public string CodTipAnex { get; set; } = "";
    public string CodAnxo { get; set; } = "";
    public List<int> IdsPrestamo { get; set; } = new();
    public DateTime FechaCorte { get; set; }
    public decimal Mora { get; set; }
    public decimal CondonacionInteres { get; set; }
    public decimal CondonacionMora { get; set; }
    public decimal PagoInicial { get; set; }
}

public class RefinanciamientoCalculoDto
{
    public int CantPrestamos { get; set; }
    public decimal CapitalPendiente { get; set; }
    public decimal InteresVencido { get; set; }
    public decimal InteresFuturoExcluido { get; set; }
    public decimal Mora { get; set; }
    public decimal CondonacionInteres { get; set; }
    public decimal CondonacionMora { get; set; }
    public decimal PagoInicial { get; set; }
    public decimal CapitalRefinanciado { get; set; }
    public List<RefinanciamientoPrestamoDto> Detalle { get; set; } = new();
}

public class RefinanciamientoAplicarRequestDto : RefinanciamientoCalcularRequestDto
{
    public string Alcance { get; set; } = "E";
    public string CodMotivo { get; set; } = "CON";
    public decimal PorcInteresMensual { get; set; }
    public string FrecuenciaPago { get; set; } = "M";
    public string TipoModalidad { get; set; } = "C";
    public DateTime FechaInicio { get; set; }
    public DateTime FechaFin { get; set; }
    public string CodGracia { get; set; } = "N";
    public int MesesGracia { get; set; }
    public decimal? TasaReferencia { get; set; }
    public string? JustificacionTasa { get; set; }
    public string? Observacion { get; set; }
}

public class RefinanciamientoAplicarResultadoDto
{
    public bool Ok { get; set; }
    public string Mensaje { get; set; } = "";
    public int IdRefinanciamiento { get; set; }
    public int IdPrestamoNuevo { get; set; }
}

public class RefinanciamientoListaDto
{
    public int IdRefinanciamiento { get; set; }
    public DateTime FechaCorte { get; set; }
    public string Cliente { get; set; } = "";
    public decimal CapitalRefinanciado { get; set; }
    public decimal InteresNuevo { get; set; }
    public decimal TotalNuevo { get; set; }
    public decimal PorcInteresMensual { get; set; }
    public int NroCuotas { get; set; }
    public int CantPrestamos { get; set; }
    public int IdPrestamoNuevo { get; set; }
    public string Estado { get; set; } = "";
}

public class RefinanciamientoDocumentoDto : RefinanciamientoListaDto
{
    public string Documento { get; set; } = "";
    public string Motivo { get; set; } = "";
    public DateTime FechaInicio { get; set; }
    public DateTime FechaFin { get; set; }
    public decimal CapitalPendiente { get; set; }
    public decimal InteresVencido { get; set; }
    public decimal Mora { get; set; }
    public decimal CondonacionInteres { get; set; }
    public decimal CondonacionMora { get; set; }
    public string FrecuenciaPago { get; set; } = "";
    public string TipoModalidad { get; set; } = "";
    public string Observacion { get; set; } = "";
    public string TextoMarcaAgua { get; set; } = "REFINANCIADO";
    public List<RefinanciamientoPrestamoDto> Origenes { get; set; } = new();
    public List<RefinanciamientoCuotaDto> Cuotas { get; set; } = new();
}

public class RefinanciamientoCuotaDto
{
    public int Numero { get; set; }
    public DateTime Vencimiento { get; set; }
    public decimal Capital { get; set; }
    public decimal Interes { get; set; }
    public decimal Importe { get; set; }
}

public class RefinanciamientoCronogramaRequestDto
{
    public decimal Capital { get; set; }
    public decimal PorcInteresMensual { get; set; }
    public string FrecuenciaPago { get; set; } = "M";
    public string TipoModalidad { get; set; } = "C";
    public DateTime FechaInicio { get; set; }
    public DateTime FechaFin { get; set; }
}

public class RefinanciamientoCronogramaDto
{
    public int NroCuotas { get; set; }
    public decimal Capital { get; set; }
    public decimal InteresTotal { get; set; }
    public decimal TotalCobrar { get; set; }
    public decimal TeaReferencial { get; set; }
    public List<RefinanciamientoCuotaDto> Cuotas { get; set; } = new();
}
