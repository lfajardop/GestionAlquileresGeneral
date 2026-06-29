using System.Security.Claims;using Aplicacion.Interfaces;using Dominio.DTO.Flota;using GestionAlquileres.ViewModels.Flota;using Microsoft.AspNetCore.Mvc;
namespace GestionAlquileres.Controllers;
public class FlotaController:Controller
{readonly IFlotaService _s;readonly IWebHostEnvironment _env;public FlotaController(IFlotaService s,IWebHostEnvironment env){_s=s;_env=env;}int Usuario()=>int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value,out var id)&&id>0?id:1007;
 [HttpGet]public IActionResult Index()=>View();[HttpGet]public async Task<IActionResult> Catalogos(CancellationToken ct)=>Json(await _s.CatalogosAsync(ct));[HttpGet]public async Task<IActionResult> Dashboard(DateTime? fecha,CancellationToken ct)=>Json(await _s.DashboardAsync(fecha??DateTime.Today,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> CrearVehiculo([FromBody]FlotaVehiculoCrearDto x,CancellationToken ct)=>Json(await _s.CrearVehiculoAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> CrearChofer([FromBody]FlotaChoferCrearDto x,CancellationToken ct)=>Json(await _s.CrearChoferAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> CrearContrato([FromBody]FlotaContratoCrearDto x,CancellationToken ct)=>Json(await _s.CrearContratoAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> GuardarDia([FromBody]FlotaTrabajoDiaDto x,CancellationToken ct)=>Json(await _s.GuardarDiaAsync(Usuario(),x,ct));
 [HttpGet]public IActionResult AdminCalendario()=>View(new FlotaAdminCalendarioViewModel());
 [HttpGet]public async Task<IActionResult> ContratosAdmin(CancellationToken ct)=>Json(await _s.ContratosAdminAsync(ct));
 [HttpGet]public async Task<IActionResult> ObtenerCalendario(int idContrato,int anio,int mes,CancellationToken ct)=>Json(await _s.CalendarioAsync(idContrato,anio,mes,ct));
 [HttpGet]public async Task<IActionResult> ListarRecibos(int idContrato,int? anio,int? mes,CancellationToken ct)=>Json(await _s.ListarRecibosAsync(idContrato,anio,mes,ct));
 [HttpGet]public async Task<IActionResult> ObtenerRecibo(int id,CancellationToken ct)=>Json(await _s.ObtenerReciboAsync(id,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> GenerarRecibo([FromBody]FlotaReciboGenerarDto x,CancellationToken ct)=>Json(await _s.GenerarReciboAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> GenerarReciboManual([FromBody]FlotaReciboManualDto x,CancellationToken ct)=>Json(await _s.GenerarManualAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> AnularRecibo([FromBody]FlotaReciboAnularDto x,CancellationToken ct)=>Json(await _s.AnularReciboAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> QuitarDiaRecibo([FromBody]FlotaReciboQuitarDiaDto x,CancellationToken ct)=>Json(await _s.QuitarDiaReciboAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> EditarPagoRecibo([FromBody]FlotaPagoReciboEditarDto x,CancellationToken ct)=>Json(await _s.EditarPagoReciboAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> AnularPagoRecibo([FromBody]FlotaPagoReciboAnularDto x,CancellationToken ct)=>Json(await _s.AnularPagoReciboAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> ValidarPagoRecibo([FromBody]FlotaPagoReciboValidarDto x,CancellationToken ct)=>Json(await _s.ValidarPagoReciboAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken]public async Task<IActionResult> CorregirOperacionDia([FromBody]FlotaOperacionDiaCorregirDto x,CancellationToken ct)=>Json(await _s.CorregirOperacionDiaAsync(Usuario(),x,ct));
 [HttpPost][ValidateAntiForgeryToken][RequestSizeLimit(6_000_000)]public async Task<IActionResult> RegistrarPago([FromForm]FlotaPagoReciboDto x,IFormFile? voucher,CancellationToken ct){if(voucher is{Length:>0}){var ext=Path.GetExtension(voucher.FileName).ToLowerInvariant();if(voucher.Length>5_000_000||!new[]{".jpg",".jpeg",".png",".webp",".pdf"}.Contains(ext))return BadRequest(new{success=false,message="Voucher invalido. Usa imagen o PDF de hasta 5 MB."});var dir=Path.Combine(_env.WebRootPath,"uploads","flota","vouchers");Directory.CreateDirectory(dir);var name=$"voucher_{DateTime.Now:yyyyMMddHHmmss}_{Guid.NewGuid():N}{ext}";await using var fs=System.IO.File.Create(Path.Combine(dir,name));await voucher.CopyToAsync(fs,ct);x.FotoVoucher=$"/uploads/flota/vouchers/{name}";}return Json(await _s.RegistrarPagoAsync(Usuario(),x,ct));}
}
