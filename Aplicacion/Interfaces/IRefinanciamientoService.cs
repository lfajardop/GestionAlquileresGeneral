using Aplicacion.Common;
using Dominio.DTO.Refinanciamiento;

namespace Aplicacion.Interfaces;
public interface IRefinanciamientoService
{
    Task<JsonResponseRequest<List<RefinanciamientoPrestamoDto>>> PrestamosClienteAsync(string tipo,string anexo,DateTime corte,CancellationToken ct);
    Task<JsonResponseRequest<RefinanciamientoCalculoDto>> CalcularAsync(RefinanciamientoCalcularRequestDto request,CancellationToken ct);
    Task<JsonResponseRequest<RefinanciamientoAplicarResultadoDto>> AplicarAsync(int usuario,RefinanciamientoAplicarRequestDto request,CancellationToken ct);
    Task<JsonResponseRequest<List<RefinanciamientoListaDto>>> ListarAsync(CancellationToken ct);
    Task<(byte[] Archivo,string Nombre,string Tipo,string? Error)> ExportarPdfAsync(int id,CancellationToken ct);
    Task<(byte[] Archivo,string Nombre,string Tipo,string? Error)> ExportarExcelAsync(int id,CancellationToken ct);
    Task<JsonResponseRequest<RefinanciamientoCronogramaDto>> SimularCronogramaAsync(RefinanciamientoCronogramaRequestDto request,CancellationToken ct);
}
