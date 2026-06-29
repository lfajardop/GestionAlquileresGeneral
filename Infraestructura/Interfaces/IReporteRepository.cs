using Dominio.DTO.Reporte;

namespace Infraestructura.Interfaces
{
    public interface IReporteRepository
    {
        Task<ReporteDeudaActualResponseDto> ObtenerDeudaActualAsync(
            ReporteDeudaActualFiltroDto filtro,
            CancellationToken cancellationToken);

        Task<ReporteEstadoCuentaClienteDto?> ObtenerEstadoCuentaClienteAsync(
            string codTipAnex,
            string codAnxo,
            CancellationToken cancellationToken);
    }
}
