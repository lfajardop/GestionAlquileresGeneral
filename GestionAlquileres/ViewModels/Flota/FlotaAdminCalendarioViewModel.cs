namespace GestionAlquileres.ViewModels.Flota;

public class FlotaAdminCalendarioViewModel
{
    public string Titulo { get; set; } = "Calendario y recibos de alquiler";
    public int Anio { get; set; } = DateTime.Today.Year;
    public int Mes { get; set; } = DateTime.Today.Month;
    public DateTime FechaPago { get; set; } = DateTime.Today;
    public DateTime FechaEdicionPago { get; set; } = DateTime.Today;
    public string MotivoPlaceholder { get; set; } = "Ingresa el motivo obligatorio.";
}
