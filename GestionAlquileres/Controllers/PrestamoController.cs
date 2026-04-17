using Aplicacion.CasosUso;
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
        private readonly IFormaPagoService _formaPagoService;
        private readonly ICajaService _cajaService;
        private readonly ILogger<PrestamoController> _logger;

        public PrestamoController(
            IPrestamoService prestamoService, IFormaPagoService formaPagoService, ICajaService cajaService,
            ILogger<PrestamoController> logger)
        {
            _prestamoService = prestamoService;
            _formaPagoService = formaPagoService;
            _cajaService = cajaService;
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

        [HttpGet]
        public async Task<IActionResult> ListarDesembolsos(int idPrestamo, CancellationToken cancellationToken)
        {
            try
            {
                var data = await _prestamoService.ListarDesembolsosAsync(idPrestamo, cancellationToken);
                return Json(new JsonResponse<object>
                {
                    Success = true,
                    Data = data
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al listar desembolsos");
                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudo listar los desembolsos.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> RegistrarDesembolso([FromForm] PrestamoRegistrarDesembolsoRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var usuario = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0";
                var estacion = HttpContext.Connection.RemoteIpAddress?.ToString();

                var result = await _prestamoService.RegistrarDesembolsoAsync(request, usuario, estacion, cancellationToken);
                return Json(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al registrar desembolso");
                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudo registrar el desembolso.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpGet]
        public async Task<IActionResult> ListarFormasPago(CancellationToken cancellationToken)
        {
            try
            {
                var data = await _formaPagoService.ListarFormasPagoAsync(cancellationToken);

                return Json(new JsonResponse<object>
                {
                    Success = true,
                    Data = data
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoController.ListarFormasPago");

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudieron listar las formas de pago.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpGet]
        public async Task<IActionResult> ListarCajasPorBanco(string flgEsBanco, CancellationToken cancellationToken)
        {
            try
            {
                var data = await _cajaService.ListarCajasPorBancoAsync(flgEsBanco, cancellationToken);

                return Json(new JsonResponse<object>
                {
                    Success = true,
                    Data = data
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoController.ListarCajasPorBanco");

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudieron listar las cajas.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpGet]
        public async Task<IActionResult> ListarPagos(int idPrestamo, CancellationToken cancellationToken)
        {
            try
            {
                var data = await _prestamoService.ListarPagosAsync(idPrestamo, cancellationToken);

                return Json(new JsonResponse<object>
                {
                    Success = true,
                    Data = data
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoController.ListarPagos");

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudieron listar los pagos.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> RegistrarPago([FromForm] PrestamoRegistrarPagoRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var usuario = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0";
                var estacion = HttpContext.Connection.RemoteIpAddress?.ToString();

                var result = await _prestamoService.RegistrarPagoAsync(request, usuario, estacion, cancellationToken);
                return Json(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al registrar pago");

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudo registrar el pago.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpGet]
        public async Task<IActionResult> ListarConceptos(CancellationToken cancellationToken)
        {
            try
            {
                var data = await _prestamoService.ListarConceptosAsync(cancellationToken);

                return Json(new JsonResponse<object>
                {
                    Success = true,
                    Data = data
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en PrestamoController.ListarConceptos");

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudieron listar los conceptos.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerDetalle(int idPrestamo)
        {
            var result = await _prestamoService.ObtenerDetalleAsync(idPrestamo);
            return Json(result);
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerEdicion(int idPrestamo)
        {
            var result = await _prestamoService.ObtenerEdicionAsync(idPrestamo);
            return Json(result);
        }
    }
}
