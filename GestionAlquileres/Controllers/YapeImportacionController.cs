using System.Security.Claims;
using Aplicacion.Interfaces;
using Dominio.DTO.Common;
using Dominio.DTO.Yape;
using Microsoft.AspNetCore.Mvc;

namespace GestionAlquileres.Controllers;

public class YapeImportacionController : Controller
{
    private readonly IYapeImportacionService _service;
    private readonly ILogger<YapeImportacionController> _logger;
    public YapeImportacionController(IYapeImportacionService service, ILogger<YapeImportacionController> logger)
    { _service=service; _logger=logger; }

    public IActionResult Index() => View();

    [HttpGet]
    public async Task<IActionResult> CajasActivas(CancellationToken ct)
        => Json(Ok(await _service.ListarCajasActivasAsync(ct), "Cajas activas."));

    [HttpGet]
    public async Task<IActionResult> Conceptos(CancellationToken ct)
        => Json(Ok(await _service.ListarConceptosAsync(ct), "Conceptos disponibles."));

    [HttpGet]
    public async Task<IActionResult> Preview(int idLote, CancellationToken ct)
    {
        var data=await _service.ObtenerPreviewAsync(idLote,ct);
        return data==null?NotFound(Err("No se encontró el lote.")):Json(Ok(data,"Vista previa."));
    }

    [HttpPost,ValidateAntiForgeryToken,RequestSizeLimit(10*1024*1024)]
    public async Task<IActionResult> Cargar(IFormFile? archivo,string codCajaChica,CancellationToken ct)
    {
        try
        {
            if(archivo==null)return BadRequest(Err("Selecciona un archivo Excel."));
            await using var stream=archivo.OpenReadStream();
            var result=await _service.CargarAsync(stream,archivo.FileName,archivo.Length,codCajaChica,Usuario(),ct);
            return Json(new JsonResponse<DbActionResult>{Success=result.Ok,Mensaje=result.Mensaje,Data=result});
        }
        catch(Exception ex){return Error(ex,"cargar el Excel Yape");}
    }

    [HttpPost,ValidateAntiForgeryToken]
    public async Task<IActionResult> Actualizar([FromBody] YapeActualizarRequestDto request,CancellationToken ct)
    {
        try
        {
            var result=await _service.ActualizarMovimientoAsync(request,ct);
            return Json(new JsonResponse<DbActionResult>{Success=result.Ok,Mensaje=result.Mensaje,Data=result});
        }
        catch(Exception ex){return Error(ex,"actualizar el movimiento");}
    }

    [HttpPost,ValidateAntiForgeryToken]
    public async Task<IActionResult> Confirmar(int idLote,CancellationToken ct)
    {
        try
        {
            var result=await _service.ConfirmarAsync(idLote,Usuario(),HttpContext.Connection.RemoteIpAddress?.ToString()??"WEB",ct);
            return Json(new JsonResponse<DbActionResult>{Success=result.Ok,Mensaje=result.Mensaje,Data=result});
        }
        catch(Exception ex){return Error(ex,"confirmar la importación");}
    }

    private string Usuario()=>User.FindFirst(ClaimTypes.NameIdentifier)?.Value is {Length:>0} u&&u!="0"?u:"1007";
    private IActionResult Error(Exception ex,string action)
    {
        var id=Guid.NewGuid();_logger.LogError(ex,"ErrorId {ErrorId} al {Action}",id,action);
        return BadRequest(Err($"{ex.Message} (ErrorId: {id})"));
    }
    private static JsonResponse<T> Ok<T>(T data,string msg)=>new(){Success=true,Mensaje=msg,Data=data};
    private static JsonResponse<object> Err(string msg)=>new(){Success=false,Mensaje=msg,Errors=new(){msg}};
}
