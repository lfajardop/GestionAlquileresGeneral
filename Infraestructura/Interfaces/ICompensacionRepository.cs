using Dominio.DTO.Compensacion;
namespace Infraestructura.Interfaces;
public interface ICompensacionRepository
{
 Task<List<CompensacionConceptoDto>> CatalogosAsync(CancellationToken ct);
 Task<CompensacionResultadoDto> CrearObligacionAsync(int empresa,string est,int usuario,CompensacionObligacionCrearDto request,CancellationToken ct);
 Task<List<CompensacionObligacionDto>> ObligacionesAsync(int empresa,string est,string tipo,string anexo,CancellationToken ct);
 Task<List<CompensacionPrestamoDto>> PrestamosAsync(int empresa,string tipo,string anexo,DateTime corte,CancellationToken ct);
 Task<CompensacionSimulacionDto?> SimularAsync(int empresa,string est,CompensacionSimularRequestDto request,CancellationToken ct);
 Task<CompensacionResultadoDto> AplicarAsync(int empresa,string est,int usuario,CompensacionAplicarRequestDto request,CancellationToken ct);
 Task<CompensacionResultadoDto> RevertirAsync(int empresa,string est,int usuario,CompensacionRevertirDto request,CancellationToken ct);
 Task<List<CompensacionListaDto>> ListarAsync(int empresa,string est,CancellationToken ct);
 Task<CompensacionDocumentoDto?> ObtenerAsync(int empresa,string est,int id,CancellationToken ct);
}
