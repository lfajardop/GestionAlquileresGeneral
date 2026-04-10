using Aplicacion.Interfaces;
using Dominio.DTO.FormaPago;
using Infraestructura.Interfaces;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Aplicacion.CasosUso
{
    public class FormaPagoService:IFormaPagoService
    {
        private readonly IFormaPagoRepository  _formaPagoRepository;
        private readonly ILogger<FormaPagoService> _logger;

        public FormaPagoService(
            IFormaPagoRepository formaPagoRepository,
            ILogger<FormaPagoService> logger)
        {
            _formaPagoRepository = formaPagoRepository;
            _logger = logger;
        }
        public async Task<List<FormaPagoDto>> ListarFormasPagoAsync(CancellationToken cancellationToken)
        {
            return await _formaPagoRepository.ListarFormasPagoAsync(cancellationToken);
        }

    }
}
