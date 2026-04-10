using Aplicacion.Interfaces;
using Dominio.CajaChica;
using Infraestructura.Interfaces;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Aplicacion.CasosUso
{
    public class CajaService:ICajaService
    {
        private readonly ICajaRepository _cajaRepository;
        private readonly ILogger<CobranzaService> _logger;

        public CajaService(
            ICajaRepository repo,
            ILogger<CobranzaService> logger)
        {
            _cajaRepository = repo;
            _logger = logger;
        }

        public async Task<List<CajaChicaDto>> ListarCajasPorBancoAsync(string flgEsBanco, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(flgEsBanco))
                throw new ArgumentException("Flg_EsBanco es obligatorio.", nameof(flgEsBanco));

            flgEsBanco = flgEsBanco.Trim().ToUpperInvariant();

            if (flgEsBanco != "S" && flgEsBanco != "N")
                throw new ArgumentException("Flg_EsBanco debe ser S o N.", nameof(flgEsBanco));

            return await _cajaRepository.ListarCajasPorBancoAsync(flgEsBanco, cancellationToken);
        }
    }
}
