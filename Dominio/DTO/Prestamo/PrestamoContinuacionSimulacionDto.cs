using System.Collections.Generic;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoContinuacionSimulacionDto
    {
        public PrestamoContinuacionResumenDto Resumen { get; set; } = new();
        public List<PrestamoContinuacionDetalleDto> Detalle { get; set; } = new();
    }
}
