namespace Dominio.DTO.Prestamo
{
    public class PrestamoContinuacionListadoDto
    {
        public int IdContinuacion { get; set; }
        public int IdPrestamo { get; set; }
        public string Cliente { get; set; } = "";
        public DateTime FechaDesde { get; set; }
        public DateTime FechaHasta { get; set; }
        public string FrecuenciaPago { get; set; } = "";
        public decimal PorcInteresMensual { get; set; }
        public decimal CapitalBase { get; set; }
        public int NroCuotasGeneradas { get; set; }
        public decimal ImporteInteresTotal { get; set; }
        public string Observacion { get; set; } = "";
        public string Estado { get; set; } = "";
        public bool PuedeEditar { get; set; }
        public string MotivoBloqueo { get; set; } = "";
    }

    public class PrestamoContinuacionEdicionDto : PrestamoContinuacionListadoDto
    {
        public int NumSecuenciaDesde { get; set; }
        public int NumSecuenciaHasta { get; set; }
        public List<PrestamoContinuacionDetalleDto> Detalle { get; set; } = new();
    }

    public class PrestamoContinuacionEditarSimularRequestDto
    {
        public int IdContinuacion { get; set; }
        public DateTime FechaHasta { get; set; }
        public decimal PorcInteresMensual { get; set; }
        public string FrecuenciaPago { get; set; } = "";
        public decimal CapitalBase { get; set; }
    }

    public class PrestamoContinuacionEditarGuardarRequestDto : PrestamoContinuacionEditarSimularRequestDto
    {
        public string Observacion { get; set; } = "";
    }
}
