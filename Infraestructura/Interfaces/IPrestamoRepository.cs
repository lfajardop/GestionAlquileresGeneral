using Dominio.DTO;
using Dominio.DTO.Common;
using Dominio.DTO.Prestamo;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infraestructura.Interfaces
{
    public interface IPrestamoRepository
    {
        Task<List<PrestamoListDto>> ListarAsync(CancellationToken cancellationToken);
        Task<DbActionResult> GuardarAsync(PrestamoCreateRequestDto request, string usuario, CancellationToken cancellationToken);

        Task<List<ClienteAnexoSelectDto>> BuscarClientesAsync(string texto, CancellationToken cancellationToken);
        Task<PrestamoSimulacionDto?> SimularAsync(PrestamoSimulacionRequestDto request, CancellationToken cancellationToken);
        Task<List<AlmacenSelectDto>> ListarAlmacenesAsync(CancellationToken cancellationToken);
      
        Task<SpResultDto?> InsertarGarantiaAsync(PrestamoCreateRequestDto request, int idPrestamo, CancellationToken cancellationToken);
        Task<DbActionResult> RegistrarDesembolsoAsync(PrestamoRegistrarDesembolsoRequestDto request,string usuario, string? estacion, CancellationToken cancellationToken);
        Task<List<PrestamoDesembolsoListadoDto>> ListarDesembolsosAsync(int idPrestamo,CancellationToken cancellationToken);

        Task<List<PrestamoPagoListadoDto>> ListarPagosAsync(int idPrestamo,CancellationToken cancellationToken);

        Task<DbActionResult> RegistrarPagoAsync(PrestamoRegistrarPagoRequestDto request, string usuario, string? estacion,CancellationToken cancellationToken);
        Task<List<PrestamoConceptoDto>> ListarConceptosAsync(CancellationToken cancellationToken);
       Task<PrestamoDetalleDto> ObtenerDetalleAsync(int idPrestamo, CancellationToken cancellationToken);

        Task<PrestamoEdicionDto?> ObtenerEdicionAsync(int idPrestamo, CancellationToken cancellationToken);
        Task<PrestamoSimulacionDto?> SimularEdicionAsync(PrestamoEditarSimularRequestDto req, CancellationToken cancellationToken);
        Task<DbActionResult> GuardarEdicionAsync(PrestamoEditarGuardarRequestDto request,string usuario, CancellationToken cancellationToken);

        Task<PrestamoCtacteClienteResumenDto?> ObtenerCtacteClienteResumenAsync(string codTipAnex,string codAnxo,CancellationToken cancellationToken);

        Task<List<PrestamoCtacteClienteDetalleDto>> ObtenerCtacteClienteDetalleAsync(string codTipAnex,string codAnxo,CancellationToken cancellationToken);

        Task<PrestamoCtacteClienteCuotasResponseDto> ObtenerCtacteClienteCuotasAsync(string codTipAnex, string codAnxo,CancellationToken cancellationToken);

        Task<PrestamoCtacteClientesResumenGeneralResponseDto> ObtenerCtacteClientesResumenGeneralAsync( CancellationToken cancellationToken);

    }
}
