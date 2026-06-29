using Dominio.DTO.Prestamo;
using System.Globalization;
using System.Text;

namespace Aplicacion.CasosUso
{
    internal static class PrestamoContinuacionPdfBuilder
    {
        public static byte[] Build(PrestamoContinuacionEdicionDto data)
        {
            const decimal width = 842, height = 595, margin = 34;
            var pages = new List<StringBuilder>();
            var rows = data.Detalle.OrderBy(x => x.Num_Secuencia).ToList();
            var index = 0; var page = 1;
            do
            {
                var sb = new StringBuilder();
                Rect(sb, 0, 0, width, height, "F5F7FA"); Rect(sb, margin, 28, width - margin * 2, height - 56, "FFFFFF", "DFE5EC");
                Rect(sb, margin, 485, width - margin * 2, 82, "183153"); Rect(sb, margin, 485, 6, 82, "2F80C9");
                Text(sb, "CONTINUACION DE PRESTAMO", margin + 22, 535, 19, "FFFFFF", true);
                Text(sb, Cut(data.Cliente, 58), margin + 22, 513, 10, "DCEBFA", true);
                Right(sb, $"Documento #{data.IdContinuacion}", width - margin - 18, 535, 9, "FFFFFF", true);
                Right(sb, $"Prestamo #{data.IdPrestamo}", width - margin - 18, 514, 8, "DCEBFA", false);

                var metrics = new[] { ("DESDE", data.FechaDesde.ToString("dd/MM/yyyy")), ("HASTA", data.FechaHasta.ToString("dd/MM/yyyy")),
                    ("CAPITAL BASE", Money(data.CapitalBase)), ("INTERES", $"{data.PorcInteresMensual:0.####}%"),
                    ("TOTAL GENERADO", Money(data.ImporteInteresTotal)) };
                for (var i = 0; i < metrics.Length; i++)
                {
                    var x = margin + i * 155.6m; Rect(sb, x, 421, 145, 51, "FFFFFF", "DFE5EC");
                    Text(sb, metrics[i].Item1, x + 10, 451, 7, "64748B", true); Text(sb, metrics[i].Item2, x + 10, 432, 12, i == 4 ? "B45309" : "172033", true);
                }
                Text(sb, $"Frecuencia: {Frequency(data.FrecuenciaPago)}   |   Cuotas: {data.NroCuotasGeneradas}   |   Emitido: {DateTime.Now:dd/MM/yyyy HH:mm}", margin, 398, 8, "526174", false);
                Text(sb, "CRONOGRAMA DE LA CONTINUACION", margin, 374, 10, "183153", true);
                Rect(sb, margin, 342, 774, 24, "EAF0F7", "D8E1EC");
                Text(sb, "CUOTA", margin + 10, 351, 8, "526174", true); Text(sb, "VENCIMIENTO", margin + 105, 351, 8, "526174", true);
                Right(sb, "CAPITAL", margin + 420, 351, 8, "526174", true); Right(sb, "INTERES", margin + 570, 351, 8, "526174", true); Right(sb, "IMPORTE", margin + 754, 351, 8, "526174", true);
                var line = 0;
                while (index < rows.Count && line < 11)
                {
                    var r = rows[index++]; var y = 316 - line * 25;
                    Rect(sb, margin, y, 774, 25, line % 2 == 0 ? "FFFFFF" : "F8FAFC", "EDF1F5");
                    Text(sb, r.Num_Secuencia.ToString(), margin + 12, y + 9, 8, "172033", true); Text(sb, r.Fec_Venc.ToString("dd/MM/yyyy"), margin + 105, y + 9, 8, "334155", false);
                    Right(sb, Money(r.Imp_Base), margin + 420, y + 9, 8, "334155", false); Right(sb, Money(r.Imp_Interes), margin + 570, y + 9, 8, "B45309", true); Right(sb, Money(r.Imp_Cuota), margin + 754, y + 9, 8, "172033", true);
                    line++;
                }
                Text(sb, "Sistema Gestion de Alquileres", margin + 10, 16, 7, "94A3B8", false); Right(sb, $"Pagina {page++}", width - margin - 10, 16, 7, "94A3B8", false);
                pages.Add(sb);
            } while (index < rows.Count || pages.Count == 0);
            return Document(pages, width, height);
        }

        private static string Frequency(string value) => value == "D" ? "Diaria" : value == "S" ? "Semanal" : "Mensual";
        private static string Money(decimal value) => "S/." + value.ToString("#,##0.00", CultureInfo.GetCultureInfo("en-US"));
        private static string Cut(string value, int max) => string.IsNullOrEmpty(value) || value.Length <= max ? value : value[..(max - 3)] + "...";
        private static void Rect(StringBuilder s, decimal x, decimal y, decimal w, decimal h, string fill, string? stroke = null)
        { var f = Color(fill); s.AppendLine("q").AppendLine($"{N(f.r)} {N(f.g)} {N(f.b)} rg"); if (stroke != null) { var c = Color(stroke); s.AppendLine($"{N(c.r)} {N(c.g)} {N(c.b)} RG").AppendLine($"{N(x)} {N(y)} {N(w)} {N(h)} re B"); } else s.AppendLine($"{N(x)} {N(y)} {N(w)} {N(h)} re f"); s.AppendLine("Q"); }
        private static void Text(StringBuilder s, string value, decimal x, decimal y, decimal size, string color, bool bold)
        { var c = Color(color); s.AppendLine("BT").AppendLine($"{N(c.r)} {N(c.g)} {N(c.b)} rg").AppendLine($"/{(bold ? "F2" : "F1")} {N(size)} Tf").AppendLine($"{N(x)} {N(y)} Td").AppendLine($"({Escape(value)}) Tj").AppendLine("ET"); }
        private static void Right(StringBuilder s, string value, decimal right, decimal y, decimal size, string color, bool bold) => Text(s, value, right - value.Length * size * (bold ? .56m : .52m), y, size, color, bold);
        private static (decimal r, decimal g, decimal b) Color(string h) => (int.Parse(h[..2], NumberStyles.HexNumber) / 255m, int.Parse(h.Substring(2, 2), NumberStyles.HexNumber) / 255m, int.Parse(h.Substring(4, 2), NumberStyles.HexNumber) / 255m);
        private static string N(decimal v) => v.ToString("0.###", CultureInfo.InvariantCulture);
        private static string Escape(string v) => Remove(v).Replace("\\", "\\\\").Replace("(", "\\(").Replace(")", "\\)");
        private static string Remove(string v) { var b = new StringBuilder(); foreach (var c in v.Normalize(NormalizationForm.FormD)) if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark && c <= 127) b.Append(c); return b.ToString(); }
        private static byte[] Document(List<StringBuilder> pages, decimal width, decimal height)
        {
            var objs = new SortedDictionary<int, string>(); var ids = new List<int>(); var next = 3; var regular = 3 + pages.Count * 2; var bold = regular + 1;
            objs[1] = "1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n";
            foreach (var page in pages) { var pid = next++; var cid = next++; ids.Add(pid); var stream = page.ToString(); objs[pid] = $"{pid} 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 {N(width)} {N(height)}] /Resources << /Font << /F1 {regular} 0 R /F2 {bold} 0 R >> >> /Contents {cid} 0 R >> endobj\n"; objs[cid] = $"{cid} 0 obj << /Length {Encoding.ASCII.GetByteCount(stream)} >> stream\n{stream}endstream endobj\n"; }
            objs[2] = $"2 0 obj << /Type /Pages /Kids [{string.Join(" ", ids.Select(x => $"{x} 0 R"))}] /Count {pages.Count} >> endobj\n";
            objs[regular] = $"{regular} 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n"; objs[bold] = $"{bold} 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >> endobj\n";
            var output = new StringBuilder("%PDF-1.4\n"); var offsets = new Dictionary<int, int>(); foreach (var o in objs) { offsets[o.Key] = Encoding.ASCII.GetByteCount(output.ToString()); output.Append(o.Value); }
            var xref = Encoding.ASCII.GetByteCount(output.ToString()); var max = objs.Keys.Max(); output.AppendLine("xref").AppendLine($"0 {max + 1}").AppendLine("0000000000 65535 f "); for (var i = 1; i <= max; i++) output.AppendLine(offsets.TryGetValue(i, out var off) ? $"{off:0000000000} 00000 n " : "0000000000 65535 f "); output.AppendLine("trailer").AppendLine($"<< /Size {max + 1} /Root 1 0 R >>").AppendLine("startxref").AppendLine(xref.ToString()).AppendLine("%%EOF"); return Encoding.ASCII.GetBytes(output.ToString());
        }
    }
}
