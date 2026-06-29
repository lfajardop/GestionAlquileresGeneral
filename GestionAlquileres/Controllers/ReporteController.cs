using Aplicacion.Interfaces;
using Dominio.DTO.Reporte;
using Microsoft.AspNetCore.Mvc;

namespace GestionAlquileres.Controllers
{
    public class ReporteController : Controller
    {
        private readonly IReporteService _reporteService;
        private readonly ILogger<ReporteController> _logger;

        public ReporteController(
            IReporteService reporteService,
            ILogger<ReporteController> logger)
        {
            _reporteService = reporteService;
            _logger = logger;
        }

        [HttpGet]
        public IActionResult DeudaActual()
        {
            return View();
        }

        [HttpGet]
        public IActionResult EstadoCuentaCliente()
        {
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerEstadoCuentaCliente(string codTipAnex, string codAnxo, CancellationToken cancellationToken)
        {
            var result = await _reporteService.ObtenerEstadoCuentaClienteAsync(codTipAnex, codAnxo, cancellationToken);
            return Json(result);
        }

        [HttpGet]
        public async Task<IActionResult> ExportarEstadoCuentaClienteExcel(string codTipAnex, string codAnxo, CancellationToken cancellationToken)
        {
            var result = await _reporteService.ExportarEstadoCuentaClienteExcelAsync(codTipAnex, codAnxo, cancellationToken);
            if (!string.IsNullOrWhiteSpace(result.MensajeError)) return BadRequest(result.MensajeError);
            return File(result.Archivo, result.ContentType, result.NombreArchivo);
        }

        [HttpGet]
        public async Task<IActionResult> ExportarEstadoCuentaClientePdf(string codTipAnex, string codAnxo, CancellationToken cancellationToken)
        {
            var result = await _reporteService.ExportarEstadoCuentaClientePdfAsync(codTipAnex, codAnxo, cancellationToken);
            if (!string.IsNullOrWhiteSpace(result.MensajeError)) return BadRequest(result.MensajeError);
            return File(result.Archivo, result.ContentType, result.NombreArchivo);
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerDeudaActual([FromQuery] ReporteDeudaActualFiltroDto filtro, CancellationToken cancellationToken)
        {
            var result = await _reporteService.ObtenerDeudaActualAsync(filtro, cancellationToken);
            return Json(result);
        }

        [HttpGet]
        public async Task<IActionResult> ExportarDeudaActualExcel([FromQuery] ReporteDeudaActualFiltroDto filtro, CancellationToken cancellationToken)
        {
            var result = await _reporteService.ExportarDeudaActualExcelAsync(filtro, cancellationToken);

            if (!string.IsNullOrWhiteSpace(result.MensajeError))
                return BadRequest(result.MensajeError);

            return File(result.Archivo, result.ContentType, result.NombreArchivo);
        }

        [HttpGet]
        public async Task<IActionResult> ExportarDeudaActualPdf([FromQuery] ReporteDeudaActualFiltroDto filtro, CancellationToken cancellationToken)
        {
            var result = await _reporteService.ExportarDeudaActualPdfAsync(filtro, cancellationToken);

            if (!string.IsNullOrWhiteSpace(result.MensajeError))
                return BadRequest(result.MensajeError);

            return File(result.Archivo, result.ContentType, result.NombreArchivo);
        }
    }
}
