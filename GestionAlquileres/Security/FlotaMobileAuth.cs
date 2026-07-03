using System.Security.Claims;
using Dominio.DTO.Flota;

namespace GestionAlquileres.Security;
public static class FlotaMobileAuth
{
    public const string Scheme = "FlotaMobileAuth";
    public const string ClaimMarker = "flota_mobile";
    public const string ClaimTelefono = "flota_mobile_telefono";
    public const string ClaimChofer = "flota_mobile_chofer";
    public const string ClaimContrato = "flota_mobile_contrato";

    public static ClaimsPrincipal CreatePrincipal(FlotaUsuarioMobileSesionDto sesion)
    {
        var claims = new List<Claim>
        {
            new(ClaimMarker,"1"),
            new(ClaimTypes.NameIdentifier,sesion.IdUsuarioMobile.ToString()),
            new(ClaimTypes.Name,string.IsNullOrWhiteSpace(sesion.Nombre)?sesion.Telefono:sesion.Nombre),
            new(ClaimTelefono,sesion.Telefono ?? "")
        };
        if (sesion.IdChofer.HasValue && sesion.IdChofer.Value > 0)
            claims.Add(new Claim(ClaimChofer,sesion.IdChofer.Value.ToString()));
        if (sesion.IdContrato.HasValue && sesion.IdContrato.Value > 0)
            claims.Add(new Claim(ClaimContrato,sesion.IdContrato.Value.ToString()));
        var identity = new ClaimsIdentity(claims,Scheme);
        return new ClaimsPrincipal(identity);
    }

    public static FlotaUsuarioMobileSesionDto? ReadSession(ClaimsPrincipal user)
    {
        if (user?.Identity?.IsAuthenticated != true || user.FindFirstValue(ClaimMarker) != "1")
            return null;
        return new FlotaUsuarioMobileSesionDto
        {
            IdUsuarioMobile = ParseInt(user.FindFirstValue(ClaimTypes.NameIdentifier)),
            IdChofer = ParseNullableInt(user.FindFirstValue(ClaimChofer)),
            IdContrato = ParseNullableInt(user.FindFirstValue(ClaimContrato)),
            Telefono = user.FindFirstValue(ClaimTelefono) ?? "",
            Nombre = user.FindFirstValue(ClaimTypes.Name) ?? ""
        };
    }

    static int ParseInt(string? value)=>int.TryParse(value,out var n)?n:0;
    static int? ParseNullableInt(string? value)=>int.TryParse(value,out var n)&&n>0?n:null;
}
