using System.Globalization;
using System.Text;
using Dominio.DTO.Refinanciamiento;

namespace Aplicacion.CasosUso;

internal static class RefinanciamientoPdfBuilder
{
    public static byte[] Build(RefinanciamientoDocumentoDto d)
    {
        const decimal w=595,h=842,m=42;var pages=new List<StringBuilder>();var idx=0;var page=1;
        do
        {
            var s=new StringBuilder();Rect(s,0,0,w,h,"F4F7FA");Rect(s,m,35,w-m*2,h-70,"FFFFFF","D9E2EC");
            Watermark(s,string.IsNullOrWhiteSpace(d.TextoMarcaAgua)?"REFINANCIADO":d.TextoMarcaAgua,w,h);
            Rect(s,m,h-145,w-m*2,110,"17345B");Rect(s,m,h-145,7,110,"2493D8");
            Text(s,"ACUERDO DE REFINANCIACION",m+24,h-78,18,"FFFFFF",true);Text(s,$"Operacion #{d.IdRefinanciamiento}  |  Prestamo nuevo #{d.IdPrestamoNuevo}",m+24,h-103,9,"D9EAF8",false);Right(s,$"Emitido {DateTime.Now:dd/MM/yyyy}",w-m-18,h-78,8,"FFFFFF",false);
            if(page==1)
            {
                Text(s,"DATOS DEL TITULAR",m+18,670,9,"17345B",true);Text(s,Cut(d.Cliente,70),m+18,649,12,"172033",true);Text(s,$"Documento: {d.Documento}   |   Fecha de corte: {d.FechaCorte:dd/MM/yyyy}",m+18,630,8,"53657A",false);
                Metric(s,m+18,570,"CAPITAL CONSOLIDADO",Money(d.CapitalRefinanciado),"156B4A");Metric(s,m+185,570,"INTERES NUEVO",Money(d.InteresNuevo),"A85B00");Metric(s,m+352,570,"TOTAL ACORDADO",Money(d.TotalNuevo),"17345B");
                Text(s,"CONDICIONES",m+18,535,9,"17345B",true);Line(s,$"Tasa mensual: {d.PorcInteresMensual:0.####}%",m+18,512);Line(s,$"Frecuencia: {Freq(d.FrecuenciaPago)}",m+260,512);Line(s,$"Periodo: {d.FechaInicio:dd/MM/yyyy} al {d.FechaFin:dd/MM/yyyy}",m+18,491);Line(s,$"Cuotas: {d.NroCuotas}",m+260,491);Line(s,$"Motivo: {d.Motivo}",m+18,470);
                Text(s,"DECLARACION",m+18,435,9,"17345B",true);
                Paragraph(s,"Las partes dejan constancia de que los prestamos detallados en el sustento han sido consolidados. El capital refinanciado incluye capital pendiente, interes compensatorio vencido y los ajustes autorizados; excluye el interes futuro no ganado.",m+18,412,475);
                Paragraph(s,"El titular reconoce el nuevo cronograma y se obliga a efectuar los pagos en las fechas pactadas. Los prestamos de origen quedan identificados como refinanciados, sin duplicar su saldo dentro de las cuentas por cobrar activas.",m+18,360,475);
                Text(s,"RESUMEN DE ORIGENES",m+18,305,9,"17345B",true);Rect(s,m+18,278,475,22,"EAF0F7","D7E0EA");Text(s,"PRESTAMO",m+28,286,7,"53657A",true);Right(s,"CAPITAL",m+245,286,7,"53657A",true);Right(s,"INTERES VENCIDO",m+370,286,7,"53657A",true);Right(s,"FUTURO EXCLUIDO",m+485,286,7,"53657A",true);var y=255;foreach(var o in d.Origenes.Take(5)){Text(s,"#"+o.IdPrestamo,m+28,y,8,"172033",true);Right(s,Money(o.CapitalPendiente),m+245,y,8,"172033",false);Right(s,Money(o.InteresVencido),m+370,y,8,"9B3D3D",false);Right(s,"-"+Money(o.InteresFuturoExcluido),m+485,y,8,"156B4A",false);y-=22;}
                Text(s,"________________________________",m+35,112,8,"64748B",false);Text(s,"Titular / firma",m+90,94,7,"64748B",false);Text(s,"________________________________",w-m-220,112,8,"64748B",false);Text(s,"Responsable autorizado",w-m-170,94,7,"64748B",false);
            }
            else
            {
                Text(s,"CRONOGRAMA DEL NUEVO PRESTAMO",m+18,670,10,"17345B",true);Rect(s,m+18,638,475,24,"EAF0F7","D7E0EA");Text(s,"CUOTA",m+28,647,7,"53657A",true);Text(s,"VENCIMIENTO",m+90,647,7,"53657A",true);Right(s,"CAPITAL",m+300,647,7,"53657A",true);Right(s,"INTERES",m+390,647,7,"53657A",true);Right(s,"IMPORTE",m+485,647,7,"53657A",true);var y=614;var line=0;while(idx<d.Cuotas.Count&&line<22){var q=d.Cuotas[idx++];if(q.Vencimiento==default)continue;Rect(s,m+18,y-7,475,22,line%2==0?"FFFFFF":"F7F9FC","EDF1F5");Text(s,q.Numero.ToString(),m+30,y,8,"172033",true);Text(s,q.Vencimiento.ToString("dd/MM/yyyy"),m+90,y,8,"334155",false);Right(s,Money(q.Capital),m+300,y,8,"334155",false);Right(s,Money(q.Interes),m+390,y,8,"A85B00",false);Right(s,Money(q.Importe),m+485,y,8,"172033",true);y-=23;line++;}
            }
            Text(s,"Documento generado por el sistema - Empresa 6 / Establecimiento 4",m+16,53,7,"8593A6",false);Right(s,$"Pagina {page++}",w-m-16,53,7,"8593A6",false);pages.Add(s);
            if(page==2&&d.Cuotas.Count>0)continue;
        }while(idx<d.Cuotas.Count||pages.Count==1&&d.Cuotas.Count>0);
        return Document(pages,w,h);
    }
    private static void Metric(StringBuilder s,decimal x,decimal y,string label,string val,string color){Rect(s,x,y-5,153,51,"F6F8FB","DFE6EE");Text(s,label,x+10,y+28,7,"64748B",true);Text(s,val,x+10,y+8,12,color,true);}private static void Line(StringBuilder s,string t,decimal x,decimal y)=>Text(s,t,x,y,8,"334155",false);
    private static void Paragraph(StringBuilder s,string t,decimal x,decimal y,decimal width){var words=t.Split(' ');var line="";foreach(var word in words){if((line+" "+word).Length>92){Text(s,line,x,y,8,"334155",false);y-=14;line=word;}else line=string.IsNullOrEmpty(line)?word:line+" "+word;}if(line.Length>0)Text(s,line,x,y,8,"334155",false);}
    private static void Watermark(StringBuilder s,string t,decimal w,decimal h){var c=Color("E7EDF4");s.AppendLine("q").AppendLine($"{N(c.r)} {N(c.g)} {N(c.b)} rg").AppendLine("0.707 0.707 -0.707 0.707 145 310 cm").AppendLine("BT /F2 44 Tf 0 0 Td").AppendLine($"({Escape(Cut(t.ToUpperInvariant(),22))}) Tj ET Q");}
    private static string Freq(string v)=>v=="D"?"Diaria":v=="S"?"Semanal":"Mensual";private static string Money(decimal v)=>"S/."+v.ToString("#,##0.00",CultureInfo.GetCultureInfo("en-US"));private static string Cut(string v,int n)=>string.IsNullOrEmpty(v)||v.Length<=n?v:v[..(n-3)]+"...";
    private static void Rect(StringBuilder s,decimal x,decimal y,decimal w,decimal h,string fill,string? stroke=null){var f=Color(fill);s.AppendLine("q").AppendLine($"{N(f.r)} {N(f.g)} {N(f.b)} rg");if(stroke!=null){var c=Color(stroke);s.AppendLine($"{N(c.r)} {N(c.g)} {N(c.b)} RG").AppendLine($"{N(x)} {N(y)} {N(w)} {N(h)} re B");}else s.AppendLine($"{N(x)} {N(y)} {N(w)} {N(h)} re f");s.AppendLine("Q");}
    private static void Text(StringBuilder s,string v,decimal x,decimal y,decimal z,string color,bool bold){var c=Color(color);s.AppendLine("BT").AppendLine($"{N(c.r)} {N(c.g)} {N(c.b)} rg").AppendLine($"/{(bold?"F2":"F1")} {N(z)} Tf").AppendLine($"{N(x)} {N(y)} Td").AppendLine($"({Escape(v)}) Tj ET");}private static void Right(StringBuilder s,string v,decimal r,decimal y,decimal z,string c,bool b)=>Text(s,v,r-v.Length*z*(b?.56m:.52m),y,z,c,b);
    private static (decimal r,decimal g,decimal b) Color(string h)=>(int.Parse(h[..2],NumberStyles.HexNumber)/255m,int.Parse(h.Substring(2,2),NumberStyles.HexNumber)/255m,int.Parse(h.Substring(4,2),NumberStyles.HexNumber)/255m);private static string N(decimal v)=>v.ToString("0.###",CultureInfo.InvariantCulture);private static string Escape(string v)=>Remove(v).Replace("\\","\\\\").Replace("(","\\(").Replace(")","\\)");private static string Remove(string v){var b=new StringBuilder();foreach(var c in v.Normalize(NormalizationForm.FormD))if(CharUnicodeInfo.GetUnicodeCategory(c)!=UnicodeCategory.NonSpacingMark&&c<=127)b.Append(c);return b.ToString();}
    private static byte[] Document(List<StringBuilder> pages,decimal w,decimal h){var o=new SortedDictionary<int,string>();var ids=new List<int>();var next=3;var reg=3+pages.Count*2;var bold=reg+1;o[1]="1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n";foreach(var p in pages){var pid=next++;var cid=next++;ids.Add(pid);var stream=p.ToString();o[pid]=$"{pid} 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 {N(w)} {N(h)}] /Resources << /Font << /F1 {reg} 0 R /F2 {bold} 0 R >> >> /Contents {cid} 0 R >> endobj\n";o[cid]=$"{cid} 0 obj << /Length {Encoding.ASCII.GetByteCount(stream)} >> stream\n{stream}endstream endobj\n";}o[2]=$"2 0 obj << /Type /Pages /Kids [{string.Join(" ",ids.Select(x=>$"{x} 0 R"))}] /Count {pages.Count} >> endobj\n";o[reg]=$"{reg} 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n";o[bold]=$"{bold} 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >> endobj\n";var outp=new StringBuilder("%PDF-1.4\n");var offs=new Dictionary<int,int>();foreach(var x in o){offs[x.Key]=Encoding.ASCII.GetByteCount(outp.ToString());outp.Append(x.Value);}var xr=Encoding.ASCII.GetByteCount(outp.ToString());var max=o.Keys.Max();outp.AppendLine("xref").AppendLine($"0 {max+1}").AppendLine("0000000000 65535 f ");for(var i=1;i<=max;i++)outp.AppendLine(offs.TryGetValue(i,out var of)?$"{of:0000000000} 00000 n ":"0000000000 65535 f ");outp.AppendLine("trailer").AppendLine($"<< /Size {max+1} /Root 1 0 R >>").AppendLine("startxref").AppendLine(xr.ToString()).AppendLine("%%EOF");return Encoding.ASCII.GetBytes(outp.ToString());}
}
