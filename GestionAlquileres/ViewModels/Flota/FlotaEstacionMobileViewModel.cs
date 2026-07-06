namespace GestionAlquileres.ViewModels.Flota;
public class FlotaEstacionMobileViewModel
{
    public string TituloPantalla{get;set;}="Estacion mobile Flota";
    public DateTime FechaOperacionInicial{get;set;}
    public DateTime FechaOperacionMaxima{get;set;}
    public string ExtensionesPermitidas{get;set;}=".jpg, .jpeg, .png, .webp, .pdf";
    public int MaxUploadMb{get;set;}=5;
    public string TodoSeguridad{get;set;}="TODO: no exponer esta pantalla sin login, PIN o token real.";
    public bool EsSesionMobile{get;set;}
    public string NombreSesion{get;set;}="";
    public string TelefonoSesion{get;set;}="";
    public int? IdContratoAsignado{get;set;}
    public bool PuedeCambiarContrato{get;set;}=true;
    public string TabInicial{get;set;}="inicio";
}
