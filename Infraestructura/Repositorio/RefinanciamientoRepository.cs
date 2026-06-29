using System.Data;
using Dominio.DTO.Refinanciamiento;
using Infraestructura.Data;
using Infraestructura.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Infraestructura.Repositorio;

public class RefinanciamientoRepository : ClsConexion, IRefinanciamientoRepository
{
    private readonly ILogger<RefinanciamientoRepository> _logger;
    public RefinanciamientoRepository(IOptions<SqlConfig> config, ILogger<RefinanciamientoRepository> logger) : base(config) => _logger = logger;

    public async Task<List<RefinanciamientoPrestamoDto>> PrestamosClienteAsync(int empresa, string est, string tipo, string anexo, DateTime corte, CancellationToken ct)
    {
        var list = new List<RefinanciamientoPrestamoDto>();
        await using var cn = new SqlConnection(GetConnectionString());
        await using var cmd = new SqlCommand("prest.p_refinanciamiento_prestamos_cliente", cn) { CommandType = CommandType.StoredProcedure };
        cmd.Parameters.AddWithValue("@id_empresa", empresa); cmd.Parameters.AddWithValue("@id_est", est);
        cmd.Parameters.AddWithValue("@Cod_TipAnex", tipo); cmd.Parameters.AddWithValue("@Cod_Anxo", anexo); cmd.Parameters.AddWithValue("@FechaCorte", corte);
        await cn.OpenAsync(ct); await using var dr = await cmd.ExecuteReaderAsync(ct);
        while (await dr.ReadAsync(ct)) list.Add(MapPrestamo(dr));
        return list;
    }

    public async Task<RefinanciamientoCalculoDto?> CalcularAsync(int empresa, string est, RefinanciamientoCalcularRequestDto r, CancellationToken ct)
    {
        await using var cn = new SqlConnection(GetConnectionString());
        await using var cmd = new SqlCommand("prest.p_refinanciamiento_calcular", cn) { CommandType = CommandType.StoredProcedure };
        AddCalculo(cmd, empresa, est, r); await cn.OpenAsync(ct); await using var dr = await cmd.ExecuteReaderAsync(ct);
        if (!await dr.ReadAsync(ct) || !Convert.ToBoolean(dr["Ok"])) return null;
        var dto = new RefinanciamientoCalculoDto { CantPrestamos=I(dr,"CantPrestamos"),CapitalPendiente=D(dr,"CapitalPendiente"),InteresVencido=D(dr,"InteresVencido"),InteresFuturoExcluido=D(dr,"InteresFuturoExcluido"),Mora=D(dr,"Mora"),CondonacionInteres=D(dr,"CondonacionInteres"),CondonacionMora=D(dr,"CondonacionMora"),PagoInicial=D(dr,"PagoInicial"),CapitalRefinanciado=D(dr,"CapitalRefinanciado") };
        if (await dr.NextResultAsync(ct)) while (await dr.ReadAsync(ct)) dto.Detalle.Add(MapPrestamo(dr));
        return dto;
    }

    public async Task<RefinanciamientoAplicarResultadoDto> AplicarAsync(int empresa, string est, int usuario, RefinanciamientoAplicarRequestDto r, CancellationToken ct)
    {
        await using var cn = new SqlConnection(GetConnectionString());
        await using var cmd = new SqlCommand("prest.p_refinanciamiento_aplicar", cn) { CommandType = CommandType.StoredProcedure };
        AddCalculo(cmd, empresa, est, r); cmd.Parameters.AddWithValue("@Alcance", r.Alcance); cmd.Parameters.AddWithValue("@Cod_Motivo", r.CodMotivo);
        cmd.Parameters.AddWithValue("@PorcInteresMensual",r.PorcInteresMensual);cmd.Parameters.AddWithValue("@FrecuenciaPago",r.FrecuenciaPago);cmd.Parameters.AddWithValue("@TipoModalidad",r.TipoModalidad);
        cmd.Parameters.AddWithValue("@FechaInicio",r.FechaInicio);cmd.Parameters.AddWithValue("@FechaFin",r.FechaFin);cmd.Parameters.AddWithValue("@Cod_Gracia",r.CodGracia);cmd.Parameters.AddWithValue("@MesesGracia",r.MesesGracia);
        cmd.Parameters.AddWithValue("@TasaReferencia",(object?)r.TasaReferencia??DBNull.Value);cmd.Parameters.AddWithValue("@JustificacionTasa",(object?)r.JustificacionTasa??DBNull.Value);cmd.Parameters.AddWithValue("@Observacion",(object?)r.Observacion??DBNull.Value);cmd.Parameters.AddWithValue("@CodUsuario",usuario);
        var ok=cmd.Parameters.Add("@Ok",SqlDbType.Bit);ok.Direction=ParameterDirection.Output;var msg=cmd.Parameters.Add("@Mensaje",SqlDbType.VarChar,500);msg.Direction=ParameterDirection.Output;var id=cmd.Parameters.Add("@IdRefinanciamiento",SqlDbType.Int);id.Direction=ParameterDirection.Output;var nuevo=cmd.Parameters.Add("@IdPrestamoNuevo",SqlDbType.Int);nuevo.Direction=ParameterDirection.Output;
        await cn.OpenAsync(ct); await cmd.ExecuteNonQueryAsync(ct);
        return new(){Ok=ok.Value!=DBNull.Value&&Convert.ToBoolean(ok.Value),Mensaje=msg.Value?.ToString()??"",IdRefinanciamiento=id.Value==DBNull.Value?0:Convert.ToInt32(id.Value),IdPrestamoNuevo=nuevo.Value==DBNull.Value?0:Convert.ToInt32(nuevo.Value)};
    }

    public async Task<List<RefinanciamientoListaDto>> ListarAsync(int empresa, string est, CancellationToken ct)
    {
        var list=new List<RefinanciamientoListaDto>();await using var cn=new SqlConnection(GetConnectionString());await using var cmd=new SqlCommand("prest.p_refinanciamiento_listar",cn){CommandType=CommandType.StoredProcedure};cmd.Parameters.AddWithValue("@id_empresa",empresa);cmd.Parameters.AddWithValue("@id_est",est);await cn.OpenAsync(ct);await using var dr=await cmd.ExecuteReaderAsync(ct);
        while(await dr.ReadAsync(ct)) list.Add(new(){IdRefinanciamiento=I(dr,"Id_Refinanciamiento"),FechaCorte=DT(dr,"FechaCorte"),Cliente=S(dr,"Cliente"),CapitalRefinanciado=D(dr,"CapitalRefinanciado"),InteresNuevo=D(dr,"InteresNuevo"),TotalNuevo=D(dr,"TotalNuevo"),PorcInteresMensual=D(dr,"PorcInteresMensual"),NroCuotas=I(dr,"NroCuotas"),CantPrestamos=I(dr,"CantPrestamos"),IdPrestamoNuevo=I(dr,"Id_Prestamo_Nuevo"),Estado=S(dr,"Estado")});return list;
    }

    public async Task<RefinanciamientoDocumentoDto?> ObtenerAsync(int empresa,string est,int id,CancellationToken ct)
    {
        await using var cn=new SqlConnection(GetConnectionString());await using var cmd=new SqlCommand("prest.p_refinanciamiento_obtener",cn){CommandType=CommandType.StoredProcedure};cmd.Parameters.AddWithValue("@id_empresa",empresa);cmd.Parameters.AddWithValue("@id_est",est);cmd.Parameters.AddWithValue("@IdRefinanciamiento",id);await cn.OpenAsync(ct);await using var r=await cmd.ExecuteReaderAsync(ct);if(!await r.ReadAsync(ct))return null;
        var d=new RefinanciamientoDocumentoDto{IdRefinanciamiento=I(r,"Id_Refinanciamiento"),FechaCorte=DT(r,"FechaCorte"),Cliente=S(r,"Cliente"),Documento=S(r,"Documento"),CapitalPendiente=D(r,"CapitalPendiente"),InteresVencido=D(r,"InteresVencido"),Mora=D(r,"Mora"),CondonacionInteres=D(r,"CondonacionInteres"),CondonacionMora=D(r,"CondonacionMora"),CapitalRefinanciado=D(r,"CapitalRefinanciado"),PorcInteresMensual=D(r,"PorcInteresMensual"),FrecuenciaPago=S(r,"FrecuenciaPago"),TipoModalidad=S(r,"TipoModalidad"),FechaInicio=DT(r,"FechaInicio"),FechaFin=DT(r,"FechaFin"),InteresNuevo=D(r,"InteresNuevo"),TotalNuevo=D(r,"TotalNuevo"),NroCuotas=I(r,"NroCuotas"),IdPrestamoNuevo=I(r,"Id_Prestamo_Nuevo"),Estado=S(r,"Estado"),Motivo=S(r,"Motivo"),Observacion=S(r,"Observacion"),TextoMarcaAgua=S(r,"TextoMarcaAgua")};
        if(await r.NextResultAsync(ct))while(await r.ReadAsync(ct))d.Origenes.Add(new(){IdPrestamo=I(r,"Id_Prestamo"),CapitalPendiente=D(r,"CapitalPendiente"),InteresVencido=D(r,"InteresVencido"),InteresFuturoExcluido=D(r,"InteresFuturoExcluido"),SaldoProgramado=D(r,"SaldoProgramado"),TotalPagado=D(r,"TotalPagado")});
        if(await r.NextResultAsync(ct))while(await r.ReadAsync(ct))d.Cuotas.Add(new(){Numero=I(r,"Num_Secuencia"),Vencimiento=DT(r,"Fec_vencDocum"),Capital=D(r,"ImporteBase"),Interes=D(r,"ImporteInteres"),Importe=D(r,"ImpCuota")});return d;
    }

    public async Task<RefinanciamientoCronogramaDto?> SimularCronogramaAsync(RefinanciamientoCronogramaRequestDto x,CancellationToken ct)
    {
        await using var cn=new SqlConnection(GetConnectionString());await using var cmd=new SqlCommand("prest.p_refinanciamiento_simular_cronograma",cn){CommandType=CommandType.StoredProcedure};cmd.Parameters.AddWithValue("@Capital",x.Capital);cmd.Parameters.AddWithValue("@PorcInteresMensual",x.PorcInteresMensual);cmd.Parameters.AddWithValue("@FrecuenciaPago",x.FrecuenciaPago);cmd.Parameters.AddWithValue("@TipoModalidad",x.TipoModalidad);cmd.Parameters.AddWithValue("@FechaInicio",x.FechaInicio);cmd.Parameters.AddWithValue("@FechaFin",x.FechaFin);await cn.OpenAsync(ct);await using var r=await cmd.ExecuteReaderAsync(ct);if(!await r.ReadAsync(ct)||!Convert.ToBoolean(r["Ok"]))return null;var d=new RefinanciamientoCronogramaDto{NroCuotas=I(r,"NroCuotas"),Capital=D(r,"Capital"),InteresTotal=D(r,"InteresTotal"),TotalCobrar=D(r,"TotalCobrar"),TeaReferencial=D(r,"TeaReferencial")};if(await r.NextResultAsync(ct))while(await r.ReadAsync(ct))d.Cuotas.Add(new(){Numero=I(r,"Numero"),Vencimiento=DT(r,"Vencimiento"),Capital=D(r,"Capital"),Interes=D(r,"Interes"),Importe=D(r,"Importe")});return d;
    }

    private static void AddCalculo(SqlCommand c,int e,string est,RefinanciamientoCalcularRequestDto r){c.Parameters.AddWithValue("@id_empresa",e);c.Parameters.AddWithValue("@id_est",est);c.Parameters.AddWithValue("@Cod_TipAnex",r.CodTipAnex);c.Parameters.AddWithValue("@Cod_Anxo",r.CodAnxo);c.Parameters.AddWithValue("@IdsPrestamo",string.Join(',',r.IdsPrestamo));c.Parameters.AddWithValue("@FechaCorte",r.FechaCorte);c.Parameters.AddWithValue("@Mora",r.Mora);c.Parameters.AddWithValue("@CondonacionInteres",r.CondonacionInteres);c.Parameters.AddWithValue("@CondonacionMora",r.CondonacionMora);c.Parameters.AddWithValue("@PagoInicial",r.PagoInicial);}
    private static RefinanciamientoPrestamoDto MapPrestamo(SqlDataReader r)=>new(){IdPrestamo=I(r,"Id_Prestamo"),Fecha=DT(r,"Fecha"),Capital=Has(r,"Capital")?D(r,"Capital"):0,TotalCobrar=Has(r,"TotalCobrar")?D(r,"TotalCobrar"):0,PorcInteresMensual=Has(r,"PorcInteresMensual")?D(r,"PorcInteresMensual"):0,FrecuenciaPago=Has(r,"FrecuenciaPago")?S(r,"FrecuenciaPago"):"",FechaFinCobro=Has(r,"FechaFinCobro")?DT(r,"FechaFinCobro"):default,Concepto=Has(r,"Concepto")?S(r,"Concepto"):"",CapitalPendiente=D(r,"CapitalPendiente"),InteresVencido=D(r,"InteresVencido"),InteresFuturoExcluido=D(r,"InteresFuturoExcluido"),SaldoProgramado=D(r,"SaldoProgramado"),TotalPagado=D(r,"TotalPagado"),CuotasVencidas=Has(r,"CuotasVencidas")?I(r,"CuotasVencidas"):0};
    private static bool Has(SqlDataReader r,string n){for(var i=0;i<r.FieldCount;i++)if(r.GetName(i).Equals(n,StringComparison.OrdinalIgnoreCase))return true;return false;}private static string S(SqlDataReader r,string n)=>r[n]==DBNull.Value?"":r[n].ToString()!.Trim();private static int I(SqlDataReader r,string n)=>r[n]==DBNull.Value?0:Convert.ToInt32(r[n]);private static decimal D(SqlDataReader r,string n)=>r[n]==DBNull.Value?0:Convert.ToDecimal(r[n]);private static DateTime DT(SqlDataReader r,string n)=>r[n]==DBNull.Value?default:Convert.ToDateTime(r[n]);
}
