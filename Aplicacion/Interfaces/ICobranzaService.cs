using Aplicacion.Common;
using Dominio.DTO.Cobranza;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Aplicacion.Interfaces
{
    public interface ICobranzaService
    {
        Task<JsonResponse<CobranzaResumenDto>> ObtenerResumenAsync(CancellationToken cancellationToken);
        Task<JsonResponse<List<CobranzaPendienteDto>>> ListarPrestamosPendientesAsync(CancellationToken cancellationToken);
        Task<JsonResponse<List<CobranzaPendienteDto>>> ListarAlquileresPendientesAsync(CancellationToken cancellationToken);
        Task<JsonResponse<List<CobranzaPendienteDto>>> ListarRentasPorVencerAsync(CancellationToken cancellationToken);
    }
}
