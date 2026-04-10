using Dominio.DTO.FormaPago;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Aplicacion.Interfaces
{
    public interface IFormaPagoService
    {
        Task<List<FormaPagoDto>> ListarFormasPagoAsync(CancellationToken cancellationToken);
    }
}
