namespace Dominio.DTO.Flota;
public class FlotaAdjuntoDto
{
    public int IdAdjunto{get;set;}
    public string TipoEntidad{get;set;}="";
    public int IdEntidad{get;set;}
    public string TipoAdjunto{get;set;}="";
    public string RutaArchivo{get;set;}="";
    public string NombreOriginal{get;set;}="";
    public string MimeType{get;set;}="";
    public long TamanoBytes{get;set;}
    public string Observacion{get;set;}="";
    public string FlgEstado{get;set;}="A";
    public DateTime? FecCreacion{get;set;}
    public DateTime? FecAnula{get;set;}
    public string MotivoAnula{get;set;}="";
}
public class FlotaAdjuntoRegistrarDto
{
    public string TipoEntidad{get;set;}="";
    public int IdEntidad{get;set;}
    public string TipoAdjunto{get;set;}="";
    public string? Observacion{get;set;}
    public string? RutaArchivo{get;set;}
    public string? NombreOriginal{get;set;}
    public string? MimeType{get;set;}
    public long? TamanoBytes{get;set;}
}
public class FlotaCombustibleRegistrarDto
{
    public int IdContrato{get;set;}
    public int IdChofer{get;set;}
    public int IdVehiculo{get;set;}
    public int? IdOperacionDia{get;set;}
    public DateTime Fecha{get;set;}
    public decimal Galones{get;set;}
    public decimal Importe{get;set;}
    public string? FlgPagoCombustible{get;set;}
    public string? Observacion{get;set;}
}
public class FlotaCombustibleAnularDto
{
    public int IdCombustibleOperacion{get;set;}
    public string Motivo{get;set;}="";
}
public class FlotaCombustibleDto
{
    public int IdCombustibleOperacion{get;set;}
    public int IdContrato{get;set;}
    public int IdChofer{get;set;}
    public int IdVehiculo{get;set;}
    public int? IdOperacionDia{get;set;}
    public DateTime Fecha{get;set;}
    public DateTime? FechaRegistro{get;set;}
    public decimal Galones{get;set;}
    public decimal Importe{get;set;}
    public string FlgPagoCombustible{get;set;}="";
    public string FlgPagoCombustibleTexto{get;set;}="";
    public string Observacion{get;set;}="";
    public string FlgEstado{get;set;}="A";
    public DateTime? FecCreacion{get;set;}
    public string Chofer{get;set;}="";
    public string Placa{get;set;}="";
    public List<FlotaAdjuntoDto> Adjuntos{get;set;}=new();
}
public class FlotaCombustibleResumenDto
{
    public DateTime Fecha{get;set;}
    public decimal TotalGalones{get;set;}
    public decimal TotalImporte{get;set;}
    public int TotalCargas{get;set;}
}
public class FlotaCombustibleListadoDto
{
    public List<FlotaCombustibleDto> Cargas{get;set;}=new();
    public FlotaCombustibleResumenDto Resumen{get;set;}=new();
}
public class FlotaAdjuntoAnularDto
{
    public int IdAdjunto{get;set;}
    public string Motivo{get;set;}="";
}
public class FlotaPagoContratoRegistrarDto
{
    public int IdContrato{get;set;}
    public int IdChofer{get;set;}
    public int IdVehiculo{get;set;}
    public int? IdOperacionDia{get;set;}
    public DateTime FechaPago{get;set;}
    public decimal Importe{get;set;}
    public int IdFormaPago{get;set;}
    public string? OperacionReferencia{get;set;}
    public string? Observacion{get;set;}
}
public class FlotaPagoContratoEditarMobileDto
{
    public int IdPagoContrato{get;set;}
    public DateTime FechaPago{get;set;}
    public decimal Importe{get;set;}
    public int IdFormaPago{get;set;}
    public string? OperacionReferencia{get;set;}
    public string? Observacion{get;set;}
}
public class FlotaPagoContratoDto
{
    public int IdPagoContrato{get;set;}
    public int IdContrato{get;set;}
    public int IdChofer{get;set;}
    public int IdVehiculo{get;set;}
    public int? IdOperacionDia{get;set;}
    public DateTime FechaPago{get;set;}
    public decimal Importe{get;set;}
    public int IdFormaPago{get;set;}
    public string FormaPago{get;set;}="";
    public string FormaPagoTexto{get;set;}="";
    public string FormaPagoAbrev{get;set;}="";
    public string OperacionReferencia{get;set;}="";
    public string Observacion{get;set;}="";
    public string FlgValidado{get;set;}="N";
    public string FlgEstado{get;set;}="A";
    public decimal ImporteAplicado{get;set;}
    public decimal ImporteDisponible{get;set;}
    public DateTime? FecCreacion{get;set;}
    public DateTime? FecValida{get;set;}
    public string MotivoValidacion{get;set;}="";
    public DateTime? FecAnula{get;set;}
    public string MotivoAnula{get;set;}="";
    public string ContratoNumero{get;set;}="";
    public string Placa{get;set;}="";
    public string Chofer{get;set;}="";
    public List<FlotaAdjuntoDto> Adjuntos{get;set;}=new();
}
public class FlotaPagoContratoListItemDto
{
    public int IdPagoContrato{get;set;}
    public int IdContrato{get;set;}
    public string ContratoNumero{get;set;}="";
    public int IdChofer{get;set;}
    public string Chofer{get;set;}="";
    public int IdVehiculo{get;set;}
    public string Placa{get;set;}="";
    public DateTime FechaPago{get;set;}
    public decimal Importe{get;set;}
    public int? IdOperacionDia{get;set;}
    public decimal ImporteAplicado{get;set;}
    public decimal ImporteDisponible{get;set;}
    public int IdFormaPago{get;set;}
    public string FormaPago{get;set;}="";
    public string FormaPagoTexto{get;set;}="";
    public string OperacionReferencia{get;set;}="";
    public string Observacion{get;set;}="";
    public string FlgValidado{get;set;}="N";
    public string FlgEstado{get;set;}="A";
    public DateTime? FecCreacion{get;set;}
    public DateTime? FecValida{get;set;}
}
public class FlotaPagoContratoValidarDto
{
    public int IdPagoContrato{get;set;}
    public string FlgValidado{get;set;}="N";
    public string Motivo{get;set;}="";
}
public class FlotaPagoContratoAnularDto
{
    public int IdPagoContrato{get;set;}
    public string Motivo{get;set;}="";
}
public class FlotaOperacionMobileGuardarDto
{
    public int IdContrato{get;set;}
    public DateTime Fecha{get;set;}
    public string? ModoRegistro{get;set;}
    public string FlgTrabajo{get;set;}="N";
    public string CodMotivo{get;set;}="";
    public string FlgCobrable{get;set;}="N";
    public decimal? KmInicial{get;set;}
    public decimal? KmFinal{get;set;}
    public decimal GalonesCargados{get;set;}
    public decimal ImporteCombustible{get;set;}
    public string? FlgPagoCombustible{get;set;}
    public DateTime? FechaHoraInicio{get;set;}
    public DateTime? FechaHoraFin{get;set;}
    public string? Observacion{get;set;}
}
public class FlotaOperacionMobileConsultaDto
{
    public int IdContrato{get;set;}
    public DateTime Fecha{get;set;}
}
public class FlotaIntervaloDto
{
    public int IdIntervalo{get;set;}
    public int IdOperacionDia{get;set;}
    public int IdContrato{get;set;}
    public int IdChofer{get;set;}
    public int IdVehiculo{get;set;}
    public DateTime FechaOperativa{get;set;}
    public DateTime FechaHoraInicio{get;set;}
    public DateTime? FechaHoraFin{get;set;}
    public decimal? KmInicio{get;set;}
    public decimal? KmFin{get;set;}
    public decimal? HorasCalculadas{get;set;}
    public string Observacion{get;set;}="";
    public string FlgEstado{get;set;}="A";
    public DateTime? FecCreacion{get;set;}
    public DateTime? FecModif{get;set;}
}
public class FlotaIntervaloAbrirRequestDto
{
    public int IdContrato{get;set;}
    public int IdChofer{get;set;}
    public int IdVehiculo{get;set;}
    public DateTime FechaHoraInicio{get;set;}
    public decimal? KmInicio{get;set;}
    public string? Observacion{get;set;}
}
public class FlotaIntervaloCerrarRequestDto
{
    public int IdContrato{get;set;}
    public int IdChofer{get;set;}
    public int IdVehiculo{get;set;}
    public DateTime FechaHoraFin{get;set;}
    public decimal? KmFin{get;set;}
    public string? Observacion{get;set;}
}
public class FlotaIntervaloAnularRequestDto
{
    public int IdIntervalo{get;set;}
    public int IdContrato{get;set;}
    public string Motivo{get;set;}="";
}
public class FlotaIntervaloResumenDto
{
    public int IdOperacionDia{get;set;}
    public int IdContrato{get;set;}
    public int IdChofer{get;set;}
    public int IdVehiculo{get;set;}
    public DateTime FechaOperativa{get;set;}
    public decimal TotalHorasDia{get;set;}
    public bool TieneIntervaloAbierto{get;set;}
    public string AlertaExcesoHoras{get;set;}="N";
    public string Mensaje{get;set;}="";
    public int CantidadIntervalos{get;set;}
}
public class FlotaOperacionMobileContratoDto
{
    public int IdContrato{get;set;}
    public string Numero{get;set;}="";
    public string Modalidad{get;set;}="";
    public string Periodicidad{get;set;}="";
    public DateTime FechaInicio{get;set;}
    public DateTime? FechaFin{get;set;}
    public decimal TarifaDia{get;set;}
    public string FlgControlKm{get;set;}="N";
    public string FlgCobraDomingo{get;set;}="N";
    public string Observacion{get;set;}="";
    public int IdVehiculo{get;set;}
    public string Placa{get;set;}="";
    public string Marca{get;set;}="";
    public string Modelo{get;set;}="";
    public decimal GalonesTanque{get;set;}
    public decimal PrecioGalon{get;set;}
    public decimal RendimientoTanqueKm{get;set;}
    public int IdChofer{get;set;}
    public string Chofer{get;set;}="";
}
public class FlotaOperacionMobileDiaDto
{
    public int IdOperacionDia{get;set;}
    public DateTime Fecha{get;set;}
    public DateTime? FechaHoraInicio{get;set;}
    public DateTime? FechaHoraFin{get;set;}
    public string FlgTrabajo{get;set;}="N";
    public string CodMotivo{get;set;}="";
    public string FlgCobrable{get;set;}="N";
    public decimal ImporteGenerado{get;set;}
    public decimal? KmInicial{get;set;}
    public decimal? KmFinal{get;set;}
    public decimal KmRecorrido{get;set;}
    public decimal ImporteCombustible{get;set;}
    public decimal GalonesCargados{get;set;}
    public string FlgPagoCombustible{get;set;}="";
    public decimal CostoConsumoEstimado{get;set;}
    public string Observacion{get;set;}="";
    public DateTime? FecCreacion{get;set;}
    public DateTime? FecModif{get;set;}
}
public class FlotaFormaPagoDto
{
    public int IdFormaPago{get;set;}
    public string Tipo{get;set;}="";
    public string Abrev{get;set;}="";
    public string Descripcion{get;set;}="";
}
public class FlotaOperacionMobileDetalleDto
{
    public FlotaOperacionMobileContratoDto? Contrato{get;set;}
    public FlotaOperacionMobileDiaDto? Operacion{get;set;}
    public List<FlotaIntervaloDto> Intervalos{get;set;}=new();
    public FlotaIntervaloResumenDto? ResumenHoras{get;set;}
    public List<FlotaAdjuntoDto> Adjuntos{get;set;}=new();
    public List<FlotaFormaPagoDto> FormasPago{get;set;}=new();
    public FlotaCombustibleResumenDto ResumenCombustible{get;set;}=new();
}
public class FlotaEstacionMobileDto
{
    public List<FlotaContratoAdminDto> Contratos{get;set;}=new();
    public DateTime FechaOperacion{get;set;}
}
public class FlotaChoferResumenGlobalMobileDto
{
    public int IdChofer{get;set;}
    public string Chofer{get;set;}="";
    public string Documento{get;set;}="";
    public string Telefono{get;set;}="";
    public decimal DeudaGlobal{get;set;}
    public decimal PagadoGlobal{get;set;}
    public decimal SaldoGlobal{get;set;}
    public decimal DeudaRealPorRecibos{get;set;}
    public decimal PagoDeclaradoPendiente{get;set;}
    public decimal PagoDeclaradoValidadoNoAplicado{get;set;}
    public int TotalContratos{get;set;}
    public int ContratosActivos{get;set;}
    public int ContratosCerrados{get;set;}
    public DateTime? UltimaFechaDeuda{get;set;}
}
public class FlotaChoferReciboGlobalItemDto
{
    public int IdContrato{get;set;}
    public string ContratoNumero{get;set;}="";
    public string Placa{get;set;}="";
    public int IdReciboAlquiler{get;set;}
    public string ReciboNumero{get;set;}="";
    public DateTime FechaInicio{get;set;}
    public DateTime FechaFin{get;set;}
    public decimal ImporteRecibo{get;set;}
    public decimal Pagado{get;set;}
    public decimal Saldo{get;set;}
    public string Estado{get;set;}="";
    public string EstadoCodigo{get;set;}="";
    public string Origen{get;set;}="";
}
public class FlotaChoferPagoDeclaradoGlobalItemDto
{
    public int IdPagoContrato{get;set;}
    public int IdContrato{get;set;}
    public string ContratoNumero{get;set;}="";
    public string Placa{get;set;}="";
    public DateTime FechaPago{get;set;}
    public decimal Importe{get;set;}
    public decimal ImporteDisponible{get;set;}
    public string FormaPagoTexto{get;set;}="";
    public string OperacionReferencia{get;set;}="";
    public string Observacion{get;set;}="";
    public string FlgValidado{get;set;}="N";
    public string FlgEstado{get;set;}="A";
}
public class FlotaChoferDetalleGlobalMobileDto
{
    public FlotaChoferResumenGlobalMobileDto Resumen{get;set;}=new();
    public List<FlotaChoferReciboGlobalItemDto> Recibos{get;set;}=new();
    public List<FlotaChoferPagoDeclaradoGlobalItemDto> PagosDeclarados{get;set;}=new();
}
public class FlotaMobileLoginDto
{
    public string Telefono{get;set;}="";
    public string Pin{get;set;}="";
}
public class FlotaMobileLoginResultDto
{
    public int IdUsuarioMobile{get;set;}
    public int? IdChofer{get;set;}
    public int? IdContrato{get;set;}
    public string Telefono{get;set;}="";
    public string Nombre{get;set;}="";
    public string PasswordHash{get;set;}="";
    public string PasswordSalt{get;set;}="";
    public string FlgEstado{get;set;}="A";
    public DateTime? FecUltimoLogin{get;set;}
}
public class FlotaUsuarioMobileSesionDto
{
    public int IdUsuarioMobile{get;set;}
    public int? IdChofer{get;set;}
    public int? IdContrato{get;set;}
    public string Telefono{get;set;}="";
    public string Nombre{get;set;}="";
    public bool TieneContratoAsignado=>IdContrato.HasValue&&IdContrato.Value>0;
}
