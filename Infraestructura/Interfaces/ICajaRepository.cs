using Dominio.CajaChica;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infraestructura.Interfaces
{
    public interface ICajaRepository
    {
        Task<List<CajaChicaDto>> ListarCajasPorBancoAsync(string flgEsBanco, CancellationToken cancellationToken);
    }
}
