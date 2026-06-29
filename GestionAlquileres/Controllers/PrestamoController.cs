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

        private string ObtenerUsuarioTemporal()
        {
            var usuario = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return string.IsNullOrWhiteSpace(usuario) || usuario == "0" ? "1007" : usuario;
        }

        public IActionResult Index()
        {
            return View();
        }
        [HttpGet]
        public IActionResult CuentaCorriente()
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
        public IActionResult PagoGlobal()
        {
            return View();
        }

        [HttpGet]
        public IActionResult Continuacion()
        {
            return View();
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
                var usuario = ObtenerUsuarioTemporal();
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
                var usuario = ObtenerUsuarioTemporal();
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
                var usuario = ObtenerUsuarioTemporal();
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

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SimularPagoGlobal([FromForm] PagoGlobalSimularRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var result = await _prestamoService.SimularPagoGlobalAsync(request, cancellationToken);
                return Json(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al simular pago global");

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudo simular el pago global.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AplicarPagoGlobal([FromForm] PagoGlobalAplicarRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var usuario = ObtenerUsuarioTemporal();
                var estacion = HttpContext.Connection.RemoteIpAddress?.ToString();

                var result = await _prestamoService.AplicarPagoGlobalAsync(request, usuario, estacion, cancellationToken);

                return Json(new JsonResponse<object>
                {
                    Success = result.Ok,
                    Mensaje = result.Mensaje,
                    Data = result,
                    Errors = result.Ok ? new List<string>() : new List<string> { result.Mensaje }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al aplicar pago global");

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudo aplicar el pago global.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SimularContinuacion([FromForm] PrestamoContinuacionSimularRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var result = await _prestamoService.SimularContinuacionAsync(request, cancellationToken);
                return Json(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al simular continuidad");

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudo simular la continuidad.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AplicarContinuacion([FromForm] PrestamoContinuacionAplicarRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var usuario = ObtenerUsuarioTemporal();
                var result = await _prestamoService.AplicarContinuacionAsync(request, usuario, cancellationToken);

                return Json(new JsonResponse<object>
                {
                    Success = result.Ok,
                    Mensaje = result.Mensaje,
                    Data = result,
                    Errors = result.Ok ? new List<string>() : new List<string> { result.Mensaje }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al aplicar continuidad");

                return Json(new JsonResponse<object>
                {
                    Success = false,
                    Mensaje = "No se pudo aplicar la continuidad.",
                    Errors = new List<string> { ex.Message }
                });
            }
        }

        [HttpGet]
        public async Task<IActionResult> ListarContinuaciones(CancellationToken cancellationToken)
            => Json(await _prestamoService.ListarContinuacionesAsync(cancellationToken));

        [HttpGet]
        public async Task<IActionResult> ObtenerContinuacion(int idContinuacion, CancellationToken cancellationToken)
            => Json(await _prestamoService.ObtenerContinuacionAsync(idContinuacion, cancellationToken));

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SimularEdicionContinuacion([FromForm] PrestamoContinuacionEditarSimularRequestDto request, CancellationToken cancellationToken)
            => Json(await _prestamoService.SimularEdicionContinuacionAsync(request, cancellationToken));

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> GuardarEdicionContinuacion([FromForm] PrestamoContinuacionEditarGuardarRequestDto request, CancellationToken cancellationToken)
        {
            var result = await _prestamoService.GuardarEdicionContinuacionAsync(request, ObtenerUsuarioTemporal(), cancellationToken);
            return Json(new JsonResponse<object> { Success = result.Ok, Mensaje = result.Mensaje, Data = result });
        }

        [HttpGet]
        public async Task<IActionResult> ExportarContinuacionPdf(int idContinuacion, CancellationToken cancellationToken)
        {
            var result = await _prestamoService.ExportarContinuacionPdfAsync(idContinuacion, cancellationToken);
            if (!string.IsNullOrWhiteSpace(result.MensajeError)) return BadRequest(result.MensajeError);
            return File(result.Archivo, result.ContentType, result.NombreArchivo);
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
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SimularEdicion([FromForm] PrestamoEditarSimularRequestDto request)
        {
            var result = await _prestamoService.SimularEdicionAsync(request);
            return Json(result);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> GuardarEdicion([FromForm] PrestamoEditarGuardarRequestDto request)
        {
            var usuario = ObtenerUsuarioTemporal();
            var result = await _prestamoService.GuardarEdicionAsync(request, usuario);
            return Json(result);
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerCtacteClienteResumen(string codTipAnex, string codAnxo)
        {
            var result = await _prestamoService.ObtenerCtacteClienteResumenAsync(codTipAnex, codAnxo);
            return Json(result);
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerCtacteClienteDetalle(string codTipAnex, string codAnxo)
        {
            var result = await _prestamoService.ObtenerCtacteClienteDetalleAsync(codTipAnex, codAnxo);
            return Json(result);
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerCtacteClienteCuotas(string codTipAnex, string codAnxo)
        {
            var result = await _prestamoService.ObtenerCtacteClienteCuotasAsync(codTipAnex, codAnxo);
            return Json(result);
        }
        [HttpGet]
        public async Task<IActionResult> ObtenerCtacteClientesResumenGeneral()
        {
            var result = await _prestamoService.ObtenerCtacteClientesResumenGeneralAsync();
            return Json(result);
        }

        [HttpGet]
        public async Task<IActionResult> ExportarCtacteClienteDetalleExcel(string codTipAnex, string codAnxo)
        {
            var result = await _prestamoService.ExportarCtacteClienteDetalleExcelAsync(codTipAnex, codAnxo);

            if (!string.IsNullOrWhiteSpace(result.MensajeError))
                return BadRequest(result.MensajeError);

            return File(result.Archivo, result.ContentType, result.NombreArchivo);
        }

    }
}
