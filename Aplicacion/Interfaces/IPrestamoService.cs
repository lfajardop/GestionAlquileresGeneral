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
        Task<JsonResponse<List<PrestamoListDto>>> ListarAsync(CancellationToken cancellationToken);
        Task<JsonResponse<DbActionResult>> GuardarAsync(PrestamoCreateRequestDto request, string usuario, CancellationToken cancellationToken);
        Task<JsonResponse<List<ClienteAnexoSelectDto>>> BuscarClientesAsync(string texto, CancellationToken cancellationToken);
        Task<JsonResponse<PrestamoSimulacionDto>> SimularAsync(PrestamoSimulacionRequestDto request, CancellationToken cancellationToken);
        Task<JsonResponse<List<AlmacenSelectDto>>> ListarAlmacenesAsync(CancellationToken cancellationToken);
    }
}
