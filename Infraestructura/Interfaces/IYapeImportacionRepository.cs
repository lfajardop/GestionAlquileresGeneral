using Dominio.DTO.Common;
using Dominio.DTO.Yape;

namespace Infraestructura.Interfaces;

public interface IYapeImportacionRepository
{
    Task<List<YapeCajaActivaDto>> ListarCajasActivasAsync(CancellationToken ct);
    Task<List<YapeConceptoDto>> ListarConceptosAsync(CancellationToken ct);
    Task<DbActionResult> CrearLoteAsync(string archivo, string hash, string caja, string usuario, IReadOnlyCollection<YapeMovimientoCargaDto> movimientos, CancellationToken ct);
    Task<YapePreviewDto?> ObtenerPreviewAsync(int idLote, CancellationToken ct);
    Task ActualizarMovimientoAsync(YapeActualizarRequestDto request, CancellationToken ct);
    Task<DbActionResult> ConfirmarAsync(int idLote, string usuario, string estacion, CancellationToken ct);
}
