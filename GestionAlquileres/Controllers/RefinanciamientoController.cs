using System.Security.Claims;
using Aplicacion.Interfaces;
using Dominio.DTO.Refinanciamiento;
using Microsoft.AspNetCore.Mvc;

namespace GestionAlquileres.Controllers;
public class RefinanciamientoController : Controller
{
    private readonly IRefinanciamientoService _service;
    public RefinanciamientoController(IRefinanciamientoService service)=>_service=service;
    [HttpGet] public IActionResult Index()=>View();
    [HttpGet] public async Task<IActionResult> PrestamosCliente(string codTipAnex,string codAnxo,DateTime fechaCorte,CancellationToken ct)=>Json(await _service.PrestamosClienteAsync(codTipAnex,codAnxo,fechaCorte,ct));
    [HttpGet] public async Task<IActionResult> Listar(CancellationToken ct)=>Json(await _service.ListarAsync(ct));
    [HttpPost][ValidateAntiForgeryToken] public async Task<IActionResult> Calcular([FromBody] RefinanciamientoCalcularRequestDto request,CancellationToken ct)=>Json(await _service.CalcularAsync(request,ct));
    [HttpPost][ValidateAntiForgeryToken] public async Task<IActionResult> Aplicar([FromBody] RefinanciamientoAplicarRequestDto request,CancellationToken ct){var raw=User.FindFirst(ClaimTypes.NameIdentifier)?.Value;var user=int.TryParse(raw,out var id)&&id>0?id:1007;return Json(await _service.AplicarAsync(user,request,ct));}
    [HttpGet] public async Task<IActionResult> Pdf(int id,CancellationToken ct){var x=await _service.ExportarPdfAsync(id,ct);return x.Error==null?File(x.Archivo,x.Tipo,x.Nombre):BadRequest(x.Error);}
    [HttpGet] public async Task<IActionResult> Excel(int id,CancellationToken ct){var x=await _service.ExportarExcelAsync(id,ct);return x.Error==null?File(x.Archivo,x.Tipo,x.Nombre):BadRequest(x.Error);}
    [HttpPost][ValidateAntiForgeryToken] public async Task<IActionResult> SimularCronograma([FromBody] RefinanciamientoCronogramaRequestDto request,CancellationToken ct)=>Json(await _service.SimularCronogramaAsync(request,ct));
}
