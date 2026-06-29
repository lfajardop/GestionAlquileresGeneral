using Aplicacion.Common;using Dominio.DTO.Compensacion;
namespace Aplicacion.Interfaces;
public interface ICompensacionService
{
 Task<JsonResponseRequest<List<CompensacionConceptoDto>>> CatalogosAsync(CancellationToken ct);Task<JsonResponseRequest<CompensacionResultadoDto>> CrearObligacionAsync(int usuario,CompensacionObligacionCrearDto x,CancellationToken ct);Task<JsonResponseRequest<List<CompensacionObligacionDto>>> ObligacionesAsync(string tipo,string anexo,CancellationToken ct);Task<JsonResponseRequest<List<CompensacionPrestamoDto>>> PrestamosAsync(string tipo,string anexo,DateTime corte,CancellationToken ct);Task<JsonResponseRequest<CompensacionSimulacionDto>> SimularAsync(CompensacionSimularRequestDto x,CancellationToken ct);Task<JsonResponseRequest<CompensacionResultadoDto>> AplicarAsync(int usuario,CompensacionAplicarRequestDto x,CancellationToken ct);Task<JsonResponseRequest<CompensacionResultadoDto>> RevertirAsync(int usuario,CompensacionRevertirDto x,CancellationToken ct);Task<JsonResponseRequest<List<CompensacionListaDto>>> ListarAsync(CancellationToken ct);Task<(byte[] Archivo,string Nombre,string Tipo,string? Error)> PdfAsync(int id,CancellationToken ct);
}
