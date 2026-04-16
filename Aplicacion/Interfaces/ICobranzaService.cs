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
        Task<JsonResponseRequest<CobranzaResumenDto>> ObtenerResumenAsync(CancellationToken cancellationToken);
        Task<JsonResponseRequest<List<CobranzaPendienteDto>>> ListarPrestamosPendientesAsync(CancellationToken cancellationToken);
        Task<JsonResponseRequest<List<CobranzaPendienteDto>>> ListarAlquileresPendientesAsync(CancellationToken cancellationToken);
        Task<JsonResponseRequest<List<CobranzaPendienteDto>>> ListarRentasPorVencerAsync(CancellationToken cancellationToken);
    }
}
