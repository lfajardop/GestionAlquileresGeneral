using Aplicacion.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GestionAlquileres.Controllers
{
    public class CobranzaController : Controller
    {
        private readonly ICobranzaService _cobranzaService;
        private readonly ILogger<CobranzaController> _logger;

        public CobranzaController(
            ICobranzaService cobranzaService,
            ILogger<CobranzaController> logger)
        {
            _cobranzaService = cobranzaService;
            _logger = logger;
        }


        public IActionResult Index()
        {
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> ListarPrestamosPendientes(CancellationToken cancellationToken)
        {
            var result = await _cobranzaService.ListarPrestamosPendientesAsync(cancellationToken);
            return Json(result);
        }

        [HttpGet]
        public async Task<IActionResult> ListarAlquileresPendientes(CancellationToken cancellationToken)
        {
            var result = await _cobranzaService.ListarAlquileresPendientesAsync(cancellationToken);
            return Json(result);
        }

        [HttpGet]
        public async Task<IActionResult> ListarRentasPorVencer(CancellationToken cancellationToken)
        {
            var result = await _cobranzaService.ListarRentasPorVencerAsync(cancellationToken);
            return Json(result);
        }
    }
}
