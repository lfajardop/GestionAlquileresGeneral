using Dominio.DTO.Cobranza;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infraestructura.Interfaces
{
    public interface ICobranzaRepository
    {
        Task<CobranzaResumenDto?> ObtenerResumenAsync(CancellationToken cancellationToken);
        Task<List<CobranzaPendienteDto>> ListarPrestamosPendientesAsync(CancellationToken cancellationToken);
        Task<List<CobranzaPendienteDto>> ListarAlquileresPendientesAsync(CancellationToken cancellationToken);
        Task<List<CobranzaPendienteDto>> ListarRentasPorVencerAsync(CancellationToken cancellationToken);
    }
}
