using Aplicacion.Common;
using Dominio.DTO.Reporte;

namespace Aplicacion.Interfaces
{
    public interface IReporteService
    {
        Task<JsonResponseRequest<ReporteDeudaActualResponseDto>> ObtenerDeudaActualAsync(
            ReporteDeudaActualFiltroDto filtro,
            CancellationToken cancellationToken);

        Task<(byte[] Archivo, string NombreArchivo, string ContentType, string? MensajeError)> ExportarDeudaActualExcelAsync(
            ReporteDeudaActualFiltroDto filtro,
            CancellationToken cancellationToken);

        Task<(byte[] Archivo, string NombreArchivo, string ContentType, string? MensajeError)> ExportarDeudaActualPdfAsync(
            ReporteDeudaActualFiltroDto filtro,
            CancellationToken cancellationToken);

        Task<JsonResponseRequest<ReporteEstadoCuentaClienteDto>> ObtenerEstadoCuentaClienteAsync(
            string codTipAnex, string codAnxo, CancellationToken cancellationToken);

        Task<(byte[] Archivo, string NombreArchivo, string ContentType, string? MensajeError)> ExportarEstadoCuentaClienteExcelAsync(
            string codTipAnex, string codAnxo, CancellationToken cancellationToken);

        Task<(byte[] Archivo, string NombreArchivo, string ContentType, string? MensajeError)> ExportarEstadoCuentaClientePdfAsync(
            string codTipAnex, string codAnxo, CancellationToken cancellationToken);
    }
}
