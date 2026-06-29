using System.Security.Claims;
using Aplicacion.Interfaces;
using Dominio.DTO.Compensacion;
using Microsoft.AspNetCore.Mvc;
namespace GestionAlquileres.Controllers;
public class CompensacionController:Controller
{
 readonly ICompensacionService _s;public CompensacionController(ICompensacionService s)=>_s=s;
 int Usuario(){var v=User.FindFirst(ClaimTypes.NameIdentifier)?.Value;return int.TryParse(v,out var id)&&id>0?id:1007;}
 [HttpGet]public IActionResult Index()=>View();
 [HttpGet]public async Task<IActionResult> Catalogos(CancellationToken ct)=>Json(await _s.CatalogosAsync(ct));
 [HttpGet]public async Task<IActionResult> Obligaciones(string codTipAnex,string codAnxo,CancellationToken ct)=>Json(await _s.ObligacionesAsync(codTipAnex,codAnxo,ct));
 [HttpGet]public async Task<IActionResult> Prestamos(string codTipAnex,string codAnxo,DateTime fechaCorte,CancellationToken ct)=>Json(await _s.PrestamosAsync(codTipAnex,codAnxo,fechaCorte,ct));
 [HttpGet]public async Task<IActionResult> Listar(CancellationToken ct)=>Json(await _s.ListarAsync(ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> CrearObligacion([FromBody]CompensacionObligacionCrearDto x,CancellationToken ct)=>Json(await _s.CrearObligacionAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> Simular([FromBody]CompensacionSimularRequestDto x,CancellationToken ct)=>Json(await _s.SimularAsync(x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> Aplicar([FromBody]CompensacionAplicarRequestDto x,CancellationToken ct)=>Json(await _s.AplicarAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> Revertir([FromBody]CompensacionRevertirDto x,CancellationToken ct)=>Json(await _s.RevertirAsync(Usuario(),x,ct));
 [HttpGet]public async Task<IActionResult> Pdf(int id,CancellationToken ct){var x=await _s.PdfAsync(id,ct);return x.Error==null?File(x.Archivo,x.Tipo,x.Nombre):BadRequest(x.Error);}
}
