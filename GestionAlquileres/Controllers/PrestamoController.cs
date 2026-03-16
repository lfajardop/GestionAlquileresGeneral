using Aplicacion.Interfaces;
using Dominio.DTO.Common;
using Dominio.DTO.Prestamo;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GestionAlquileres.Controllers
{
    public class PrestamoController : Controller
    {
        private readonly IPrestamoService _prestamoService;
        private readonly ILogger<PrestamoController> _logger;

        public PrestamoController(
            IPrestamoService prestamoService,
            ILogger<PrestamoController> logger)
        {
            _prestamoService = prestamoService;
            _logger = logger;
        }
        public IActionResult Index()
        {
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> Listar(CancellationToken cancellationToken)
        {
            var result = await _prestamoService.ListarAsync(cancellationToken);
            return Json(result);
        }
        [HttpGet]
        public async Task<IActionResult> BuscarClientes(string texto, CancellationToken cancellationToken)
        {
            var result = await _prestamoService.BuscarClientesAsync(texto ?? string.Empty, cancellationToken);
            return Json(result);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Simular([FromForm] PrestamoSimulacionRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var result = await _prestamoService.SimularAsync(request, cancellationToken);
                return Json(result);
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Error en PrestamoController.Simular", errorId);

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = $"Ocurrió un error al simular el préstamo. ErrorId: {errorId}",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Guardar([FromForm] PrestamoCreateRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var usuario = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0";
                var result = await _prestamoService.GuardarAsync(request, usuario, cancellationToken);
                return Json(result);
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Error en PrestamoController.Guardar", errorId);

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = $"Ocurrió un error al guardar el préstamo. ErrorId: {errorId}",
                    Errors = new List<string> { ex.Message }
                });
            }
        }
        [HttpGet]
        public async Task<IActionResult> ListarAlmacenes(CancellationToken cancellationToken)
        {
            var result = await _prestamoService.ListarAlmacenesAsync(cancellationToken);
            return Json(result);
        }
    }
}
