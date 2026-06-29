using Dominio.DTO.Common;
using Dominio.DTO.Yape;

namespace Aplicacion.Interfaces;

public interface IYapeImportacionService
{
    Task<List<YapeCajaActivaDto>> ListarCajasActivasAsync(CancellationToken ct);
    Task<List<YapeConceptoDto>> ListarConceptosAsync(CancellationToken ct);
    Task<DbActionResult> CargarAsync(Stream archivo, string nombreArchivo, long longitud, string codCaja, string usuario, CancellationToken ct);
    Task<YapePreviewDto?> ObtenerPreviewAsync(int idLote, CancellationToken ct);
    Task<DbActionResult> ActualizarMovimientoAsync(YapeActualizarRequestDto request, CancellationToken ct);
    Task<DbActionResult> ConfirmarAsync(int idLote, string usuario, string estacion, CancellationToken ct);
}
