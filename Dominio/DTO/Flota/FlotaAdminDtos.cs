namespace Dominio.DTO.Flota;

public class FlotaContratoFinalizarDto
{
    public int IdContrato{get;set;}
    public DateTime FechaFin{get;set;}
    public string MotivoCierre{get;set;}="";
    public string? Observacion{get;set;}
}

public class FlotaContratoDetalleDto
{
    public int IdContrato{get;set;}
    public string Numero{get;set;}="";
    public string Placa{get;set;}="";
    public string Chofer{get;set;}="";
    public int IdVehiculo{get;set;}
    public int IdChofer{get;set;}
    public string Modalidad{get;set;}="";
    public string Periodicidad{get;set;}="";
    public DateTime FechaInicio{get;set;}
    public DateTime? FechaFin{get;set;}
    public decimal TarifaDia{get;set;}
    public string Estado{get;set;}="";
    public string CobraDomingo{get;set;}="N";
    public string ControlKm{get;set;}="N";
    public string Observacion{get;set;}="";
}

public class FlotaUsuarioMobileAdminDto
{
    public int IdUsuarioMobile{get;set;}
    public string Telefono{get;set;}="";
    public string Nombre{get;set;}="";
    public int? IdChofer{get;set;}
    public string ChoferNombre{get;set;}="";
    public string DocumentoChofer{get;set;}="";
    public int? IdContrato{get;set;}
    public string NumeroContrato{get;set;}="";
    public string Placa{get;set;}="";
    public string FlgEstado{get;set;}="A";
    public DateTime? FecCreacion{get;set;}
    public DateTime? FecUltimoLogin{get;set;}
}

public class FlotaUsuarioMobileCrearDto
{
    public int IdChofer{get;set;}
    public int? IdContrato{get;set;}
    public string Telefono{get;set;}="";
    public string Nombre{get;set;}="";
    public string Pin{get;set;}="";
    public string ConfirmarPin{get;set;}="";
    public string FlgEstado{get;set;}="A";
}

public class FlotaUsuarioMobileActualizarDto
{
    public int IdUsuarioMobile{get;set;}
    public int IdChofer{get;set;}
    public int? IdContrato{get;set;}
    public string Telefono{get;set;}="";
    public string Nombre{get;set;}="";
}

public class FlotaUsuarioMobileCambiarEstadoDto
{
    public int IdUsuarioMobile{get;set;}
    public string FlgEstado{get;set;}="";
}

public class FlotaUsuarioMobileCambiarContratoDto
{
    public int IdUsuarioMobile{get;set;}
    public int? IdContrato{get;set;}
}

public class FlotaUsuarioMobileResetPinDto
{
    public int IdUsuarioMobile{get;set;}
    public string Pin{get;set;}="";
    public string ConfirmarPin{get;set;}="";
}

public class FlotaChoferDeudaResumenDto
{
    public int IdChofer{get;set;}
    public string Chofer{get;set;}="";
    public string Documento{get;set;}="";
    public string Telefono{get;set;}="";
    public int TotalContratos{get;set;}
    public int ContratosActivos{get;set;}
    public int ContratosCerrados{get;set;}
    public decimal TotalGeneradoRecibos{get;set;}
    public decimal TotalPagadoRecibos{get;set;}
    public decimal SaldoRecibos{get;set;}
    public decimal PagoDeclaradoPendiente{get;set;}
    public decimal PagoDeclaradoValidadoNoAplicado{get;set;}
    public DateTime? UltimaFechaDeuda{get;set;}
}
