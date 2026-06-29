using Dominio.DTO.Refinanciamiento;

namespace Infraestructura.Interfaces;

public interface IRefinanciamientoRepository
{
    Task<List<RefinanciamientoPrestamoDto>> PrestamosClienteAsync(int empresa, string est, string tipo, string anexo, DateTime corte, CancellationToken ct);
    Task<RefinanciamientoCalculoDto?> CalcularAsync(int empresa, string est, RefinanciamientoCalcularRequestDto request, CancellationToken ct);
    Task<RefinanciamientoAplicarResultadoDto> AplicarAsync(int empresa, string est, int usuario, RefinanciamientoAplicarRequestDto request, CancellationToken ct);
    Task<List<RefinanciamientoListaDto>> ListarAsync(int empresa, string est, CancellationToken ct);
    Task<RefinanciamientoDocumentoDto?> ObtenerAsync(int empresa, string est, int id, CancellationToken ct);
    Task<RefinanciamientoCronogramaDto?> SimularCronogramaAsync(RefinanciamientoCronogramaRequestDto request, CancellationToken ct);
}
