using System.Data;
using Dominio.DTO.Common;
using Dominio.DTO.Yape;
using Infraestructura.Data;
using Infraestructura.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Infraestructura.Repositorio;

public class YapeImportacionRepository : ClsConexion, IYapeImportacionRepository
{
    private readonly ILogger<YapeImportacionRepository> _logger;

    public YapeImportacionRepository(IOptions<SqlConfig> config, ILogger<YapeImportacionRepository> logger) : base(config)
        => _logger = logger;

    public async Task<List<YapeCajaActivaDto>> ListarCajasActivasAsync(CancellationToken ct)
    {
        var result = new List<YapeCajaActivaDto>();
        await using var cn = new SqlConnection(GetConnectionString());
        await using var cmd = new SqlCommand("dbo.CJ_Yape_CajaActiva_Listar", cn) { CommandType = CommandType.StoredProcedure };
        await cn.OpenAsync(ct);
        await using var dr = await cmd.ExecuteReaderAsync(ct);
        while (await dr.ReadAsync(ct))
            result.Add(new YapeCajaActivaDto
            {
                CodCajaChica = Convert.ToString(dr["Cod_CajaChica"])?.Trim() ?? "",
                DesCajaChica = Convert.ToString(dr["Des_CajaChica"])?.Trim() ?? "",
                NumMovstk = Convert.ToInt32(dr["Num_Movstk"]),
                NumTransaccion = Convert.ToInt32(dr["Num_Transaccion"]),
                FechaDesde = Convert.ToDateTime(dr["FechaDesde"]),
                FechaHasta = Convert.ToDateTime(dr["FechaHasta"]),
                Observaciones = Convert.ToString(dr["Observaciones"])?.Trim() ?? ""
            });
        return result;
    }

    public async Task<List<YapeConceptoDto>> ListarConceptosAsync(CancellationToken ct)
    {
        var result = new List<YapeConceptoDto>();
        await using var cn = new SqlConnection(GetConnectionString());
        await using var cmd = new SqlCommand("dbo.CJ_Yape_Concepto_Listar", cn) { CommandType = CommandType.StoredProcedure };
        await cn.OpenAsync(ct);
        await using var dr = await cmd.ExecuteReaderAsync(ct);
        while (await dr.ReadAsync(ct))
            result.Add(new YapeConceptoDto
            {
                Codigo = Convert.ToString(dr["Cod_Concepto_Caja"])?.Trim() ?? "",
                Descripcion = Convert.ToString(dr["Des_Concepto_Caja"])?.Trim() ?? "",
                Tipo = Convert.ToString(dr["Tip_Concepto"])?.Trim() ?? ""
            });
        return result;
    }

    public async Task<DbActionResult> CrearLoteAsync(string archivo, string hash, string caja, string usuario, IReadOnlyCollection<YapeMovimientoCargaDto> movimientos, CancellationToken ct)
    {
        var table = new DataTable();
        table.Columns.Add("NumFilaExcel", typeof(int));
        table.Columns.Add("FechaYape", typeof(DateTime));
        table.Columns.Add("TipoYape", typeof(string));
        table.Columns.Add("TipoNormalizado", typeof(string));
        table.Columns.Add("Origen", typeof(string));
        table.Columns.Add("Destino", typeof(string));
        table.Columns.Add("Monto", typeof(decimal));
        table.Columns.Add("Glosa", typeof(string));
        table.Columns.Add("Beneficiario", typeof(string));
        table.Columns.Add("HashMovimiento", typeof(string));
        foreach (var x in movimientos)
            table.Rows.Add(x.NumFilaExcel, x.FechaYape, x.TipoYape, x.TipoNormalizado, x.Origen, x.Destino,
                x.Monto, x.Glosa, x.Beneficiario, x.HashMovimiento);

        await using var cn = new SqlConnection(GetConnectionString());
        await using var cmd = new SqlCommand("dbo.CJ_Yape_Importacion_Web_Crear", cn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 300 };
        cmd.Parameters.Add("@NombreArchivo", SqlDbType.VarChar, 260).Value = archivo;
        cmd.Parameters.Add("@HashArchivo", SqlDbType.VarChar, 64).Value = hash;
        cmd.Parameters.Add("@Cod_CajaChica", SqlDbType.Char, 2).Value = caja;
        cmd.Parameters.Add("@Cod_Usuario", SqlDbType.VarChar, 50).Value = usuario;
        cmd.Parameters.Add(new SqlParameter("@Movimientos", SqlDbType.Structured) { TypeName = "dbo.CJ_Yape_MovimientoWebType", Value = table });
        var id = cmd.Parameters.Add("@IdLote", SqlDbType.Int); id.Direction = ParameterDirection.Output;
        var msg = cmd.Parameters.Add("@Mensaje", SqlDbType.VarChar, 500); msg.Direction = ParameterDirection.Output;
        await cn.OpenAsync(ct);
        await cmd.ExecuteNonQueryAsync(ct);
        return new DbActionResult { Ok = true, IdGenerado = Convert.ToInt32(id.Value), RowsAffected = movimientos.Count, Mensaje = Convert.ToString(msg.Value) ?? "" };
    }

    public async Task<YapePreviewDto?> ObtenerPreviewAsync(int idLote, CancellationToken ct)
    {
        await using var cn = new SqlConnection(GetConnectionString());
        await using var cmd = new SqlCommand("dbo.CJ_Yape_Importacion_Web_Preview", cn) { CommandType = CommandType.StoredProcedure };
        cmd.Parameters.Add("@IdLote", SqlDbType.Int).Value = idLote;
        await cn.OpenAsync(ct);
        await using var dr = await cmd.ExecuteReaderAsync(ct);
        if (!await dr.ReadAsync(ct)) return null;
        var result = new YapePreviewDto
        {
            Lote = new YapeLoteDto
            {
                IdLote = Convert.ToInt32(dr["IdLote"]), NombreArchivo = S(dr,"NombreArchivo"), Periodo = S(dr,"Periodo"),
                CodCajaChica = S(dr,"Cod_CajaChica"), NumMovstk = I(dr,"Num_Movstk"), NumTransaccion = I(dr,"Num_Transaccion"),
                FechaDesde = D(dr,"FechaDesde"), FechaHasta = D(dr,"FechaHasta"), Estado = S(dr,"Flg_Estado"),
                TotalFilas = I(dr,"TotalFilas"), TotalInsertadas = I(dr,"TotalInsertadas"),
                TotalDuplicadas = I(dr,"TotalDuplicadas"), TotalRevision = I(dr,"TotalRevision")
            }
        };
        await dr.NextResultAsync(ct);
        while (await dr.ReadAsync(ct))
            result.Movimientos.Add(new YapeMovimientoPreviewDto
            {
                IdDetalle=I(dr,"IdDetalleImportacion"),NumFilaExcel=I(dr,"NumFilaExcel"),FechaYape=D(dr,"FechaYape"),
                TipoYape=S(dr,"TipoYape"),TipoNormalizado=S(dr,"TipoNormalizado"),Origen=S(dr,"Origen"),Destino=S(dr,"Destino"),
                Beneficiario=S(dr,"Beneficiario"),Monto=M(dr,"Monto"),Glosa=S(dr,"Glosa"),CodConceptoCaja=S(dr,"Cod_Concepto_Caja"),
                DesConceptoCaja=S(dr,"Des_Concepto_Caja"),Score=I(dr,"Score"),RequiereRevision=B(dr,"RequiereRevision"),
                FueDuplicado=B(dr,"FueDuplicado"),FlgSeleccionado=S(dr,"Flg_Seleccionado"),Estado=S(dr,"Flg_Estado"),
                Observacion=S(dr,"Observacion"),MotivoResultado=S(dr,"MotivoResultado"),
                SecMovimientoExistente=dr["Sec_Movimiento_Existente"]==DBNull.Value?null:Convert.ToInt32(dr["Sec_Movimiento_Existente"])
            });
        return result;
    }

    public async Task ActualizarMovimientoAsync(YapeActualizarRequestDto request, CancellationToken ct)
    {
        await using var cn = new SqlConnection(GetConnectionString());
        await using var cmd = new SqlCommand("dbo.CJ_Yape_Importacion_Web_Actualizar", cn) { CommandType = CommandType.StoredProcedure };
        cmd.Parameters.Add("@IdLote",SqlDbType.Int).Value=request.IdLote;
        cmd.Parameters.Add("@IdDetalle",SqlDbType.Int).Value=request.IdDetalle;
        cmd.Parameters.Add("@Flg_Seleccionado",SqlDbType.VarChar,1).Value=request.FlgSeleccionado;
        cmd.Parameters.Add("@Cod_Concepto_Caja",SqlDbType.VarChar,10).Value=request.CodConceptoCaja;
        cmd.Parameters.Add("@Observacion",SqlDbType.VarChar,300).Value=(object?)request.Observacion??DBNull.Value;
        await cn.OpenAsync(ct); await cmd.ExecuteNonQueryAsync(ct);
    }

    public async Task<DbActionResult> ConfirmarAsync(int idLote, string usuario, string estacion, CancellationToken ct)
    {
        await using var cn = new SqlConnection(GetConnectionString());
        await using var cmd = new SqlCommand("dbo.CJ_Yape_Importacion_Web_Confirmar", cn) { CommandType=CommandType.StoredProcedure,CommandTimeout=300 };
        cmd.Parameters.Add("@IdLote",SqlDbType.Int).Value=idLote;
        cmd.Parameters.Add("@Cod_Usuario",SqlDbType.VarChar,50).Value=usuario;
        cmd.Parameters.Add("@Cod_Estacion",SqlDbType.VarChar,15).Value=estacion.Length>15?estacion[..15]:estacion;
        var ok=cmd.Parameters.Add("@Ok",SqlDbType.Bit);ok.Direction=ParameterDirection.Output;
        var msg=cmd.Parameters.Add("@Mensaje",SqlDbType.VarChar,500);msg.Direction=ParameterDirection.Output;
        await cn.OpenAsync(ct); await cmd.ExecuteNonQueryAsync(ct);
        return new DbActionResult{Ok=ok.Value!=DBNull.Value&&Convert.ToBoolean(ok.Value),Mensaje=Convert.ToString(msg.Value)??""};
    }

    private static string S(SqlDataReader r,string n)=>r[n]==DBNull.Value?"":Convert.ToString(r[n])?.Trim()??"";
    private static int I(SqlDataReader r,string n)=>r[n]==DBNull.Value?0:Convert.ToInt32(r[n]);
    private static decimal M(SqlDataReader r,string n)=>r[n]==DBNull.Value?0:Convert.ToDecimal(r[n]);
    private static DateTime D(SqlDataReader r,string n)=>r[n]==DBNull.Value?DateTime.MinValue:Convert.ToDateTime(r[n]);
    private static bool B(SqlDataReader r,string n)=>r[n]!=DBNull.Value&&Convert.ToBoolean(r[n]);
}
