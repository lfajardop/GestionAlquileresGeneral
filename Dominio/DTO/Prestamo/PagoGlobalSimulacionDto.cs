using System.Collections.Generic;

namespace Dominio.DTO.Prestamo
{
    public class PagoGlobalSimulacionDto
    {
        public PagoGlobalResumenDto Resumen { get; set; } = new();
        public List<PagoGlobalDetalleDto> Detalle { get; set; } = new();
    }
}
