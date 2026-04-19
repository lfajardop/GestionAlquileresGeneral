using Aplicacion.Common;
using Dominio.DTO.Common;
using Dominio.DTO.Prestamo;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Aplicacion.Interfaces
{
    public interface IPrestamoService
    {
        Task<JsonResponseRequest<List<PrestamoListDto>>> ListarAsync(CancellationToken cancellationToken);
        Task<JsonResponseRequest<DbActionResult>> GuardarAsync(PrestamoCreateRequestDto request, string usuario, CancellationToken cancellationToken);
        Task<JsonResponseRequest<List<ClienteAnexoSelectDto>>> BuscarClientesAsync(string texto, CancellationToken cancellationToken);
        Task<JsonResponseRequest<PrestamoSimulacionDto>> SimularAsync(PrestamoSimulacionRequestDto request, CancellationToken cancellationToken);
        Task<JsonResponseRequest<List<AlmacenSelectDto>>> ListarAlmacenesAsync(CancellationToken cancellationToken);
        Task<List<PrestamoDesembolsoListadoDto>> ListarDesembolsosAsync(
    int idPrestamo,
    CancellationToken cancellationToken);

        Task<DbActionResult> RegistrarDesembolsoAsync(
            PrestamoRegistrarDesembolsoRequestDto request,
            string usuario,
            string? estacion,
            CancellationToken cancellationToken);

        Task<List<PrestamoPagoListadoDto>> ListarPagosAsync(
    int idPrestamo,
    CancellationToken cancellationToken);

        Task<DbActionResult> RegistrarPagoAsync(
    PrestamoRegistrarPagoRequestDto request,
    string usuario,
    string? estacion,
    CancellationToken cancellationToken);

        Task<List<PrestamoConceptoDto>> ListarConceptosAsync(CancellationToken cancellationToken);
        Task<JsonResponseRequest<PrestamoDetalleDto>> ObtenerDetalleAsync(int idPrestamo);
        Task<JsonResponseRequest<PrestamoEdicionDto>> ObtenerEdicionAsync(int idPrestamo);
        Task<JsonResponseRequest<PrestamoSimulacionDto>> SimularEdicionAsync(PrestamoEditarSimularRequestDto req);
        Task<JsonResponseRequest<int>> GuardarEdicionAsync(PrestamoEditarGuardarRequestDto request,string usuario);

        Task<JsonResponseRequest<PrestamoCtacteClienteResumenDto>> ObtenerCtacteClienteResumenAsync(string codTipAnex, string codAnxo);

        Task<JsonResponseRequest<List<PrestamoCtacteClienteDetalleDto>>> ObtenerCtacteClienteDetalleAsync(string codTipAnex, string codAnxo);

        Task<JsonResponseRequest<PrestamoCtacteClienteCuotasResponseDto>> ObtenerCtacteClienteCuotasAsync(string codTipAnex, string codAnxo);
        Task<JsonResponseRequest<PrestamoCtacteClientesResumenGeneralResponseDto>> ObtenerCtacteClientesResumenGeneralAsync();
    }


}
