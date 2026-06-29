using System.Globalization;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Xml.Linq;
using Aplicacion.Interfaces;
using Dominio.DTO.Common;
using Dominio.DTO.Yape;
using Infraestructura.Interfaces;

namespace Aplicacion.CasosUso;

public class YapeImportacionService : IYapeImportacionService
{
    private readonly IYapeImportacionRepository _repo;
    private const long MaxFileSize = 10 * 1024 * 1024;
    public YapeImportacionService(IYapeImportacionRepository repo) => _repo = repo;

    public Task<List<YapeCajaActivaDto>> ListarCajasActivasAsync(CancellationToken ct) => _repo.ListarCajasActivasAsync(ct);
    public Task<List<YapeConceptoDto>> ListarConceptosAsync(CancellationToken ct) => _repo.ListarConceptosAsync(ct);
    public Task<YapePreviewDto?> ObtenerPreviewAsync(int idLote, CancellationToken ct) => _repo.ObtenerPreviewAsync(idLote, ct);

    public async Task<DbActionResult> CargarAsync(Stream archivo, string nombreArchivo, long longitud, string codCaja, string usuario, CancellationToken ct)
    {
        if (longitud <= 0 || longitud > MaxFileSize) throw new InvalidOperationException("El archivo debe pesar entre 1 byte y 10 MB.");
        if (!string.Equals(Path.GetExtension(nombreArchivo), ".xlsx", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Solo se admiten archivos .xlsx exportados por Yape.");
        var caja = (await _repo.ListarCajasActivasAsync(ct)).FirstOrDefault(x => x.CodCajaChica == codCaja)
                   ?? throw new InvalidOperationException("La caja seleccionada no está abierta.");

        await using var ms = new MemoryStream();
        await archivo.CopyToAsync(ms, ct);
        var bytes = ms.ToArray();
        var hashArchivo = Convert.ToHexString(SHA256.HashData(bytes));
        var filas = LeerExcel(bytes);
        var periodo = filas.Where(x => x.FechaYape.Date >= caja.FechaDesde.Date && x.FechaYape.Date <= caja.FechaHasta.Date).ToList();
        if (periodo.Count == 0)
            throw new InvalidOperationException($"El Excel no contiene movimientos de {caja.FechaDesde:MMMM yyyy}.");
        return await _repo.CrearLoteAsync(Path.GetFileName(nombreArchivo), hashArchivo, codCaja, usuario, periodo, ct);
    }

    public async Task<DbActionResult> ActualizarMovimientoAsync(YapeActualizarRequestDto request, CancellationToken ct)
    {
        request.FlgSeleccionado = request.FlgSeleccionado == "S" ? "S" : "N";
        if (request.FlgSeleccionado == "S" && string.IsNullOrWhiteSpace(request.CodConceptoCaja))
            return new DbActionResult { Ok=false, Mensaje="Selecciona un concepto de caja." };
        await _repo.ActualizarMovimientoAsync(request, ct);
        return new DbActionResult { Ok=true, Mensaje="Movimiento actualizado." };
    }

    public Task<DbActionResult> ConfirmarAsync(int idLote, string usuario, string estacion, CancellationToken ct)
        => _repo.ConfirmarAsync(idLote, usuario, estacion, ct);

    private static List<YapeMovimientoCargaDto> LeerExcel(byte[] bytes)
    {
        using var ms = new MemoryStream(bytes);
        using var zip = new ZipArchive(ms, ZipArchiveMode.Read);
        var sheetEntry = zip.GetEntry("xl/worksheets/sheet1.xml") ?? throw new InvalidOperationException("El Excel no contiene una hoja válida.");
        var shared = LeerSharedStrings(zip);
        using var sheetStream = sheetEntry.Open();
        var doc = XDocument.Load(sheetStream);
        XNamespace ns = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
        var rows = doc.Descendants(ns + "row").ToList();
        var headerRow = rows.FirstOrDefault(r =>
        {
            var values = ValoresFila(r, ns, shared);
            return values.Any(v => Normalizar(v) == "TIPO DE TRANSACCION") && values.Any(v => Normalizar(v) == "FECHA DE OPERACION");
        }) ?? throw new InvalidOperationException("No se encontraron los encabezados del reporte Yape.");

        var headers = Celdas(headerRow, ns, shared).ToDictionary(x => Normalizar(x.Value), x => Columna(x.Reference));
        var required = new[] { "TIPO DE TRANSACCION", "ORIGEN", "DESTINO", "MONTO", "MENSAJE", "FECHA DE OPERACION" };
        var missing = required.Where(x => !headers.ContainsKey(x)).ToList();
        if (missing.Count > 0) throw new InvalidOperationException("Faltan columnas obligatorias: " + string.Join(", ", missing));

        var result = new List<YapeMovimientoCargaDto>();
        foreach (var row in rows.Where(r => (int?)r.Attribute("r") > (int?)headerRow.Attribute("r")))
        {
            var map = Celdas(row, ns, shared).ToDictionary(x => Columna(x.Reference), x => x.Value);
            string V(string h) => map.TryGetValue(headers[h], out var v) ? v.Trim() : "";
            var tipo = V("TIPO DE TRANSACCION");
            var fechaTexto = V("FECHA DE OPERACION");
            var montoTexto = V("MONTO");
            if (string.IsNullOrWhiteSpace(tipo) && string.IsNullOrWhiteSpace(fechaTexto) && string.IsNullOrWhiteSpace(montoTexto)) continue;
            if (!DateTime.TryParseExact(fechaTexto, new[] { "dd/MM/yyyy HH:mm:ss", "dd/MM/yyyy H:mm:ss", "dd/MM/yyyy" }, CultureInfo.InvariantCulture, DateTimeStyles.None, out var fecha))
                throw new InvalidOperationException($"Fila {row.Attribute("r")}: fecha inválida '{fechaTexto}'.");
            if (!decimal.TryParse(montoTexto, NumberStyles.Number, CultureInfo.InvariantCulture, out var monto) &&
                !decimal.TryParse(montoTexto, NumberStyles.Number, CultureInfo.GetCultureInfo("es-PE"), out monto))
                throw new InvalidOperationException($"Fila {row.Attribute("r")}: monto inválido '{montoTexto}'.");
            if (monto <= 0) throw new InvalidOperationException($"Fila {row.Attribute("r")}: el monto debe ser mayor a cero.");
            var tipoNorm = Normalizar(tipo) == "PAGASTE" ? "SALIDA" : Normalizar(tipo).StartsWith("TE PAGO") ? "ENTRADA" : "";
            if (tipoNorm == "") throw new InvalidOperationException($"Fila {row.Attribute("r")}: tipo Yape no reconocido '{tipo}'.");
            var origen=V("ORIGEN"); var destino=V("DESTINO"); var glosa=V("MENSAJE");
            var beneficiario=tipoNorm=="SALIDA"?destino:origen;
            var key=$"{fecha:yyyyMMddHHmmss}|{monto:0.00}|{Normalizar(tipo)}|{Normalizar(origen)}|{Normalizar(destino)}|{Normalizar(glosa)}";
            result.Add(new YapeMovimientoCargaDto
            {
                NumFilaExcel=(int?)row.Attribute("r")??0,FechaYape=fecha,TipoYape=tipo,TipoNormalizado=tipoNorm,
                Origen=Limitar(origen,200),Destino=Limitar(destino,200),Monto=monto,Glosa=Limitar(glosa,500),
                Beneficiario=Limitar(beneficiario,200),HashMovimiento=Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(key)))
            });
        }
        if (result.Count == 0) throw new InvalidOperationException("El Excel no contiene movimientos válidos.");
        return result;
    }

    private static List<string> LeerSharedStrings(ZipArchive zip)
    {
        var entry=zip.GetEntry("xl/sharedStrings.xml"); if(entry==null)return new();
        using var s=entry.Open();var d=XDocument.Load(s);XNamespace n="http://schemas.openxmlformats.org/spreadsheetml/2006/main";
        return d.Descendants(n+"si").Select(x=>string.Concat(x.Descendants(n+"t").Select(t=>t.Value))).ToList();
    }
    private static IEnumerable<(string Reference,string Value)> Celdas(XElement row,XNamespace ns,List<string> shared)
        => row.Elements(ns+"c").Select(c=>(c.Attribute("r")?.Value??"",ValorCelda(c,ns,shared)));
    private static List<string> ValoresFila(XElement row,XNamespace ns,List<string> shared)=>Celdas(row,ns,shared).Select(x=>x.Value).ToList();
    private static string ValorCelda(XElement c,XNamespace ns,List<string> shared)
    {
        if((string?)c.Attribute("t")=="inlineStr")return string.Concat(c.Descendants(ns+"t").Select(x=>x.Value));
        var v=c.Element(ns+"v")?.Value??"";
        if((string?)c.Attribute("t")=="s"&&int.TryParse(v,out var i)&&i>=0&&i<shared.Count)return shared[i];
        return v;
    }
    private static string Columna(string reference)=>new(reference.TakeWhile(char.IsLetter).ToArray());
    private static string Limitar(string value,int max)=>value.Length<=max?value:value[..max];
    private static string Normalizar(string value)
    {
        var form=value.Trim().ToUpperInvariant().Normalize(NormalizationForm.FormD);
        return new string(form.Where(c=>CharUnicodeInfo.GetUnicodeCategory(c)!=UnicodeCategory.NonSpacingMark).ToArray()).Normalize(NormalizationForm.FormC);
    }
}
