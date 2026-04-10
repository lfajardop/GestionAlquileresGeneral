using Dominio.CajaChica;
using Dominio.DTO.FormaPago;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infraestructura.Interfaces
{
    public interface IFormaPagoRepository
    {
        Task<List<FormaPagoDto>> ListarFormasPagoAsync(CancellationToken cancellationToken);
    }
}
