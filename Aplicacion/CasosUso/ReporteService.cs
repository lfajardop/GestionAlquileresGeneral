using Aplicacion.Common;
using Aplicacion.Interfaces;
using ClosedXML.Excel;
using Dominio.DTO.Reporte;
using Infraestructura.Interfaces;
using Microsoft.Extensions.Logging;
using System.Globalization;
using System.Text;

namespace Aplicacion.CasosUso
{
    public class ReporteService : IReporteService
    {
        private readonly IReporteRepository _repo;
        private readonly ILogger<ReporteService> _logger;

        public ReporteService(
            IReporteRepository repo,
            ILogger<ReporteService> logger)
        {
            _repo = repo;
            _logger = logger;
        }

        public async Task<JsonResponseRequest<ReporteDeudaActualResponseDto>> ObtenerDeudaActualAsync(
            ReporteDeudaActualFiltroDto filtro,
            CancellationToken cancellationToken)
        {
            var res = new JsonResponseRequest<ReporteDeudaActualResponseDto>();

            try
            {
                NormalizarFiltro(filtro);
                var data = await _repo.ObtenerDeudaActualAsync(filtro, cancellationToken);

                res.Success = true;
                res.Mensaje = "Reporte de deuda actual obtenido correctamente.";
                res.Data = data;
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Error al obtener deuda actual", errorId);

                res.Success = false;
                res.Mensaje = $"Ocurrió un error al obtener el reporte. ErrorId: {errorId}";
                res.Errors.Add(ex.Message);
            }

            return res;
        }

        public async Task<(byte[] Archivo, string NombreArchivo, string ContentType, string? MensajeError)> ExportarDeudaActualExcelAsync(
            ReporteDeudaActualFiltroDto filtro,
            CancellationToken cancellationToken)
        {
            try
            {
                NormalizarFiltro(filtro);
                var data = await _repo.ObtenerDeudaActualAsync(filtro, cancellationToken);

                using var wb = new XLWorkbook();
                var ws = wb.Worksheets.Add("Deuda Actual");

                ws.Cell(1, 1).Value = "REPORTE DE DEUDA ACTUAL";
                ws.Range(1, 1, 1, 12).Merge();
                ws.Range(1, 1, 1, 12).Style.Font.Bold = true;
                ws.Range(1, 1, 1, 12).Style.Font.FontSize = 16;
                ws.Range(1, 1, 1, 12).Style.Fill.BackgroundColor = XLColor.FromHtml("#0B5CAD");
                ws.Range(1, 1, 1, 12).Style.Font.FontColor = XLColor.White;
                ws.Range(1, 1, 1, 12).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                ws.Cell(3, 1).Value = "Clientes";
                ws.Cell(3, 2).Value = data.Totales.TotalClientes;
                ws.Cell(3, 4).Value = "Saldo";
                ws.Cell(3, 5).Value = data.Totales.TotalSaldo;
                ws.Cell(3, 5).Style.NumberFormat.Format = "\"S/.\"#,##0.00";
                ws.Cell(3, 7).Value = "Vencido";
                ws.Cell(3, 8).Value = data.Totales.TotalVencido;
                ws.Cell(3, 8).Style.NumberFormat.Format = "\"S/.\"#,##0.00";

                var headers = new[]
                {
                    "Cliente", "Documento", "Prestamos", "Cuotas pendientes", "Cuotas vencidas",
                    "Programado", "Pagado", "Saldo", "Vencido", "Primer vencimiento", "Dias atraso", "Codigo"
                };

                var headerRow = 5;
                for (var i = 0; i < headers.Length; i++)
                    ws.Cell(headerRow, i + 1).Value = headers[i];

                var headerRange = ws.Range(headerRow, 1, headerRow, headers.Length);
                headerRange.Style.Font.Bold = true;
                headerRange.Style.Fill.BackgroundColor = XLColor.FromHtml("#E9EEF5");
                headerRange.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                headerRange.Style.Border.InsideBorder = XLBorderStyleValues.Thin;

                var row = headerRow + 1;
                foreach (var item in data.Detalle)
                {
                    ws.Cell(row, 1).Value = item.Cliente;
                    ws.Cell(row, 2).Value = item.Documento;
                    ws.Cell(row, 3).Value = item.CantPrestamos;
                    ws.Cell(row, 4).Value = item.CuotasPendientes;
                    ws.Cell(row, 5).Value = item.CuotasVencidas;
                    ws.Cell(row, 6).Value = item.TotalProgramado;
                    ws.Cell(row, 7).Value = item.TotalPagado;
                    ws.Cell(row, 8).Value = item.TotalSaldo;
                    ws.Cell(row, 9).Value = item.TotalVencido;
                    ws.Cell(row, 10).Value = item.PrimerVencimiento;
                    ws.Cell(row, 11).Value = item.DiasAtraso;
                    ws.Cell(row, 12).Value = $"{item.CodTipAnex}-{item.CodAnxo}";

                    ws.Range(row, 6, row, 9).Style.NumberFormat.Format = "\"S/.\"#,##0.00";
                    ws.Cell(row, 10).Style.DateFormat.Format = "dd/MM/yyyy";

                    if (item.TotalVencido > 0)
                    {
                        ws.Cell(row, 9).Style.Font.FontColor = XLColor.FromHtml("#C00000");
                        ws.Cell(row, 9).Style.Font.Bold = true;
                    }

                    row++;
                }

                if (row > headerRow + 1)
                {
                    var dataRange = ws.Range(headerRow, 1, row - 1, headers.Length);
                    dataRange.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                    dataRange.Style.Border.InsideBorder = XLBorderStyleValues.Thin;
                    dataRange.SetAutoFilter();
                }

                ws.Columns().AdjustToContents();
                ws.SheetView.FreezeRows(headerRow);

                using var ms = new MemoryStream();
                wb.SaveAs(ms);

                return (
                    ms.ToArray(),
                    $"ReporteDeudaActual_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx",
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    null);
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Error al exportar deuda actual Excel", errorId);
                return (Array.Empty<byte>(), "", "", $"Ocurrió un error al exportar Excel. ErrorId: {errorId}");
            }
        }

        public async Task<(byte[] Archivo, string NombreArchivo, string ContentType, string? MensajeError)> ExportarDeudaActualPdfAsync(
            ReporteDeudaActualFiltroDto filtro,
            CancellationToken cancellationToken)
        {
            try
            {
                NormalizarFiltro(filtro);
                var data = await _repo.ObtenerDeudaActualAsync(filtro, cancellationToken);
                var pdf = CrearPdfGerencial(data);

                return (
                    pdf,
                    $"ReporteDeudaActual_{DateTime.Now:yyyyMMdd_HHmmss}.pdf",
                    "application/pdf",
                    null);
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Error al exportar deuda actual PDF", errorId);
                return (Array.Empty<byte>(), "", "", $"Ocurrió un error al exportar PDF. ErrorId: {errorId}");
            }
        }

        public async Task<JsonResponseRequest<ReporteEstadoCuentaClienteDto>> ObtenerEstadoCuentaClienteAsync(
            string codTipAnex, string codAnxo, CancellationToken cancellationToken)
        {
            var response = new JsonResponseRequest<ReporteEstadoCuentaClienteDto>();
            try
            {
                ValidarCliente(codTipAnex, codAnxo);
                var data = await _repo.ObtenerEstadoCuentaClienteAsync(codTipAnex.Trim(), codAnxo.Trim(), cancellationToken);
                response.Success = data != null;
                response.Mensaje = data == null ? "El cliente no tiene prestamos para mostrar." : "Estado de cuenta obtenido correctamente.";
                response.Data = data;
            }
            catch (ArgumentException ex)
            {
                response.Success = false;
                response.Mensaje = ex.Message;
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Estado de cuenta por cliente", errorId);
                response.Success = false;
                response.Mensaje = $"No se pudo obtener el estado de cuenta. ErrorId: {errorId}";
            }

            return response;
        }

        public async Task<(byte[] Archivo, string NombreArchivo, string ContentType, string? MensajeError)> ExportarEstadoCuentaClienteExcelAsync(
            string codTipAnex, string codAnxo, CancellationToken cancellationToken)
        {
            try
            {
                ValidarCliente(codTipAnex, codAnxo);
                var data = await _repo.ObtenerEstadoCuentaClienteAsync(codTipAnex.Trim(), codAnxo.Trim(), cancellationToken);
                if (data == null) return (Array.Empty<byte>(), "", "", "El cliente no tiene informacion para exportar.");

                using var wb = new XLWorkbook();
                CrearHojaResumenCliente(wb, data);
                CrearHojaCuotasCliente(wb, data);
                CrearHojaPagosCliente(wb, data);
                CrearHojaCompensacionesCliente(wb, data);
                using var ms = new MemoryStream();
                wb.SaveAs(ms);
                return (ms.ToArray(), $"EstadoCuenta_{NombreSeguro(data.Cliente)}_{DateTime.Now:yyyyMMdd}.xlsx",
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", null);
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Excel estado de cuenta", errorId);
                return (Array.Empty<byte>(), "", "", $"No se pudo generar el Excel. ErrorId: {errorId}");
            }
        }

        public async Task<(byte[] Archivo, string NombreArchivo, string ContentType, string? MensajeError)> ExportarEstadoCuentaClientePdfAsync(
            string codTipAnex, string codAnxo, CancellationToken cancellationToken)
        {
            try
            {
                ValidarCliente(codTipAnex, codAnxo);
                var data = await _repo.ObtenerEstadoCuentaClienteAsync(codTipAnex.Trim(), codAnxo.Trim(), cancellationToken);
                if (data == null) return (Array.Empty<byte>(), "", "", "El cliente no tiene informacion para exportar.");
                return (CrearPdfEstadoCuenta(data), $"EstadoCuenta_{NombreSeguro(data.Cliente)}_{DateTime.Now:yyyyMMdd}.pdf", "application/pdf", null);
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - PDF estado de cuenta", errorId);
                return (Array.Empty<byte>(), "", "", $"No se pudo generar el PDF. ErrorId: {errorId}");
            }
        }

        private static void ValidarCliente(string codTipAnex, string codAnxo)
        {
            if (string.IsNullOrWhiteSpace(codTipAnex) || string.IsNullOrWhiteSpace(codAnxo))
                throw new ArgumentException("Selecciona un cliente para generar su estado de cuenta.");
        }

        private static string NombreSeguro(string nombre)
        {
            var value = RemoveDiacritics(nombre ?? "Cliente");
            return string.Concat(value.Select(x => char.IsLetterOrDigit(x) ? x : '_')).Trim('_');
        }

        private static void CrearHojaResumenCliente(XLWorkbook wb, ReporteEstadoCuentaClienteDto data)
        {
            var ws = wb.Worksheets.Add("Estado de cuenta");
            ws.Cell("A1").Value = "ESTADO DE CUENTA DEL CLIENTE";
            var title = ws.Range("A1:L2");
            title.Merge(); title.Style.Fill.BackgroundColor = XLColor.FromHtml("#183153");
            title.Style.Font.FontColor = XLColor.White; title.Style.Font.Bold = true; title.Style.Font.FontSize = 18;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Cell("A4").Value = "Cliente"; ws.Cell("B4").Value = data.Cliente;
            ws.Cell("A5").Value = "Documento"; ws.Cell("B5").Value = data.Documento;
            ws.Cell("H4").Value = "Codigo"; ws.Cell("I4").Value = $"{data.CodTipAnex}-{data.CodAnxo}";
            ws.Cell("H5").Value = "Emitido"; ws.Cell("I5").Value = data.FechaEmision; ws.Cell("I5").Style.DateFormat.Format = "dd/MM/yyyy HH:mm";

            var metrics = new[]
            {
                ("Capital prestado", data.Resumen.TotalCapital, "#E8F1FF"),
                ("Interes programado", data.Resumen.TotalInteres, "#FFF4DD"),
                ("Pagos recibidos", data.Resumen.TotalPagosRecibidos, "#E7F8F0"),
                ("Compensaciones", data.Resumen.TotalCompensado, "#F2EDFF"),
                ("Total aplicado", data.Resumen.TotalPagado, "#E7F8F0"),
                ("Saldo pendiente", data.Resumen.SaldoPendiente, "#FDECEC")
            };
            for (var i = 0; i < metrics.Length; i++)
            {
                var col = 1 + (i * 2);
                ws.Range(7, col, 7, col + 1).Merge().Value = metrics[i].Item1;
                ws.Range(8, col, 9, col + 1).Merge().Value = metrics[i].Item2;
                var card = ws.Range(7, col, 9, col + 1);
                card.Style.Fill.BackgroundColor = XLColor.FromHtml(metrics[i].Item3);
                card.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                card.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                ws.Range(8, col, 9, col + 1).Style.Font.Bold = true;
                ws.Range(8, col, 9, col + 1).Style.Font.FontSize = 13;
                ws.Range(8, col, 9, col + 1).Style.NumberFormat.Format = "\"S/.\"#,##0.00";
            }

            var headers = new[] { "Prestamo", "Fecha", "Concepto", "Capital", "Interes", "Programado", "Pagado", "Saldo", "Cuotas", "Vencidas", "Atraso", "Estado" };
            var row = 12;
            for (var i = 0; i < headers.Length; i++) ws.Cell(row, i + 1).Value = headers[i];
            EstiloCabeceraExcel(ws.Range(row, 1, row, headers.Length));
            foreach (var item in data.Prestamos)
            {
                row++;
                ws.Cell(row, 1).Value = item.IdPrestamo; ws.Cell(row, 2).Value = item.Fecha; ws.Cell(row, 3).Value = item.Concepto;
                ws.Cell(row, 4).Value = item.Capital; ws.Cell(row, 5).Value = item.Interes; ws.Cell(row, 6).Value = item.TotalProgramado;
                ws.Cell(row, 7).Value = item.TotalPagado; ws.Cell(row, 8).Value = item.SaldoPendiente; ws.Cell(row, 9).Value = item.NroCuotas;
                ws.Cell(row, 10).Value = item.CuotasVencidas; ws.Cell(row, 11).Value = item.DiasAtraso; ws.Cell(row, 12).Value = item.Estado;
                ws.Cell(row, 2).Style.DateFormat.Format = "dd/MM/yyyy"; ws.Range(row, 4, row, 8).Style.NumberFormat.Format = "\"S/.\"#,##0.00";
                if (item.CuotasVencidas > 0) ws.Range(row, 8, row, 11).Style.Font.FontColor = XLColor.FromHtml("#B42318");
            }
            EstiloDatosExcel(ws.Range(12, 1, Math.Max(12, row), headers.Length));
            ws.SheetView.FreezeRows(12); ws.Range(12, 1, Math.Max(12, row), headers.Length).SetAutoFilter(); ws.Columns().AdjustToContents();
            ws.Column(3).Width = Math.Min(ws.Column(3).Width, 38);
        }

        private static void CrearHojaCuotasCliente(XLWorkbook wb, ReporteEstadoCuentaClienteDto data)
        {
            var ws = wb.Worksheets.Add("Cuotas");
            var headers = new[] { "Prestamo", "Cuota", "Vencimiento", "Capital", "Interes", "Importe", "Pagado", "Saldo", "Estado", "Dias atraso" };
            for (var i = 0; i < headers.Length; i++) ws.Cell(1, i + 1).Value = headers[i];
            EstiloCabeceraExcel(ws.Range(1, 1, 1, headers.Length)); var row = 1;
            foreach (var item in data.Cuotas.OrderBy(x => x.FechaVencimiento))
            {
                row++; ws.Cell(row, 1).Value = item.IdPrestamo; ws.Cell(row, 2).Value = item.NumCuota; ws.Cell(row, 3).Value = item.FechaVencimiento;
                ws.Cell(row, 4).Value = item.Capital; ws.Cell(row, 5).Value = item.Interes; ws.Cell(row, 6).Value = item.Importe;
                ws.Cell(row, 7).Value = item.Pagado; ws.Cell(row, 8).Value = item.Saldo; ws.Cell(row, 9).Value = item.Estado; ws.Cell(row, 10).Value = item.DiasAtraso;
                ws.Cell(row, 3).Style.DateFormat.Format = "dd/MM/yyyy"; ws.Range(row, 4, row, 8).Style.NumberFormat.Format = "\"S/.\"#,##0.00";
            }
            EstiloDatosExcel(ws.Range(1, 1, Math.Max(1, row), headers.Length)); ws.SheetView.FreezeRows(1);
            ws.Range(1, 1, Math.Max(1, row), headers.Length).SetAutoFilter(); ws.Columns().AdjustToContents();
        }

        private static void CrearHojaPagosCliente(XLWorkbook wb, ReporteEstadoCuentaClienteDto data)
        {
            var ws = wb.Worksheets.Add("Pagos recibidos");
            var headers = new[] { "Fecha", "Prestamo", "Cuota", "Forma de pago", "Caja / banco", "Importe", "Glosa" };
            for (var i = 0; i < headers.Length; i++) ws.Cell(1, i + 1).Value = headers[i];
            EstiloCabeceraExcel(ws.Range(1, 1, 1, headers.Length)); var row = 1;
            foreach (var item in data.Pagos.Where(x => x.FormaPago != "COMPENSACION").OrderByDescending(x => x.FechaPago))
            {
                row++; ws.Cell(row, 1).Value = item.FechaPago; ws.Cell(row, 2).Value = item.IdPrestamo; ws.Cell(row, 3).Value = item.NumCuota;
                ws.Cell(row, 4).Value = item.FormaPago; ws.Cell(row, 5).Value = item.CajaBanco; ws.Cell(row, 6).Value = item.Importe; ws.Cell(row, 7).Value = item.Glosa;
                ws.Cell(row, 1).Style.DateFormat.Format = "dd/MM/yyyy HH:mm"; ws.Cell(row, 6).Style.NumberFormat.Format = "\"S/.\"#,##0.00";
            }
            EstiloDatosExcel(ws.Range(1, 1, Math.Max(1, row), headers.Length)); ws.SheetView.FreezeRows(1);
            ws.Range(1, 1, Math.Max(1, row), headers.Length).SetAutoFilter(); ws.Columns().AdjustToContents(); ws.Column(7).Width = Math.Min(ws.Column(7).Width, 45);
        }

        private static void CrearHojaCompensacionesCliente(XLWorkbook wb, ReporteEstadoCuentaClienteDto data)
        {
            var ws = wb.Worksheets.Add("Compensaciones");
            var headers = new[] { "Numero", "Fecha", "Concepto", "Prestamos", "Cuotas afectadas", "Importe", "Estado", "Observacion" };
            for (var i = 0; i < headers.Length; i++) ws.Cell(1, i + 1).Value = headers[i];
            EstiloCabeceraExcel(ws.Range(1, 1, 1, headers.Length)); var row = 1;
            foreach (var item in data.Compensaciones.OrderByDescending(x => x.Fecha).ThenByDescending(x => x.IdCompensacion))
            {
                row++; ws.Cell(row, 1).Value = item.Numero; ws.Cell(row, 2).Value = item.Fecha; ws.Cell(row, 3).Value = item.Concepto;
                ws.Cell(row, 4).Value = item.Prestamos; ws.Cell(row, 5).Value = item.CuotasAfectadas; ws.Cell(row, 6).Value = item.Importe;
                ws.Cell(row, 7).Value = item.Estado; ws.Cell(row, 8).Value = item.Observacion;
                ws.Cell(row, 2).Style.DateFormat.Format = "dd/MM/yyyy"; ws.Cell(row, 6).Style.NumberFormat.Format = "\"S/.\"#,##0.00";
                ws.Cell(row, 7).Style.Font.FontColor = item.EstadoCodigo == "A" ? XLColor.FromHtml("#087253") : XLColor.FromHtml("#B42318");
            }
            EstiloDatosExcel(ws.Range(1, 1, Math.Max(1, row), headers.Length)); ws.SheetView.FreezeRows(1);
            ws.Range(1, 1, Math.Max(1, row), headers.Length).SetAutoFilter(); ws.Columns().AdjustToContents();
            ws.Column(3).Width = Math.Min(ws.Column(3).Width, 38); ws.Column(8).Width = Math.Min(ws.Column(8).Width, 45);
        }

        private static void EstiloCabeceraExcel(IXLRange range)
        {
            range.Style.Fill.BackgroundColor = XLColor.FromHtml("#235B8E"); range.Style.Font.FontColor = XLColor.White;
            range.Style.Font.Bold = true; range.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
        }

        private static void EstiloDatosExcel(IXLRange range)
        {
            range.Style.Border.OutsideBorder = XLBorderStyleValues.Thin; range.Style.Border.InsideBorder = XLBorderStyleValues.Hair;
            range.Style.Border.OutsideBorderColor = XLColor.FromHtml("#D9E2EC");
        }

        private static void NormalizarFiltro(ReporteDeudaActualFiltroDto filtro)
        {
            filtro.Cliente = (filtro.Cliente ?? string.Empty).Trim();
            filtro.Estado = (filtro.Estado ?? string.Empty).Trim().ToUpperInvariant();
        }

        private static byte[] CrearPdfEstadoCuenta(ReporteEstadoCuentaClienteDto data)
        {
            const decimal width = 842m;
            const decimal height = 595m;
            const decimal margin = 32m;
            var pages = new List<StringBuilder>();
            var loans = data.Prestamos.OrderByDescending(x => x.Fecha).ToList();
            var index = 0;
            var pageNo = 1;

            do
            {
                var first = pages.Count == 0;
                var sb = new StringBuilder();
                DrawPageBase(sb, width, height, margin, pageNo++);
                if (first)
                {
                    Rect(sb, 0, height - 82m, width, 82m, "#183153");
                    Rect(sb, 0, height - 82m, 7m, 82m, "#2F80C9");
                    Text(sb, "ESTADO DE CUENTA", margin, height - 40m, 21, "#FFFFFF", true);
                    Text(sb, Cortar(data.Cliente, 58), margin, height - 61m, 11, "#DCEBFA", true);
                    TextRight(sb, $"Emitido {data.FechaEmision:dd/MM/yyyy HH:mm}", width - margin, height - 39m, 8, "#DCEBFA", false);
                    TextRight(sb, $"Doc. {data.Documento.Trim()}", width - margin, height - 58m, 8, "#FFFFFF", true);

                    var cards = new[]
                    {
                        ("CAPITAL PRESTADO", Money(data.Resumen.TotalCapital), "#E8F1FF", "#185FA5"),
                        ("PAGOS RECIBIDOS", Money(data.Resumen.TotalPagosRecibidos), "#E7F8F0", "#087253"),
                        ("COMPENSACIONES", Money(data.Resumen.TotalCompensado), "#F2EDFF", "#6941C6"),
                        ("SALDO ACTUAL", Money(data.Resumen.SaldoPendiente), "#FDECEC", "#C62828")
                    };
                    for (var i = 0; i < cards.Length; i++)
                    {
                        var x = margin + (i * 195m);
                        Rect(sb, x, 432m, 183m, 61m, "#FFFFFF", "#E2E8F0");
                        Rect(sb, x, 432m, 5m, 61m, cards[i].Item4);
                        Rect(sb, x + 15m, 447m, 31m, 31m, cards[i].Item3);
                        Text(sb, cards[i].Item1, x + 56m, 468m, 7, "#64748B", true);
                        Text(sb, cards[i].Item2, x + 56m, 447m, 14, "#172033", true);
                    }
                    Text(sb, $"Interes: {Money(data.Resumen.TotalInteres)}  |  Total aplicado: {Money(data.Resumen.TotalPagado)}  |  Vencido: {Money(data.Resumen.SaldoVencido)}  |  Cuotas vencidas: {data.Resumen.CuotasVencidas}", margin, 412m, 8, data.Resumen.SaldoVencido > 0 ? "#B42318" : "#475569", true);
                }
                else
                {
                    Rect(sb, 0, height - 52m, width, 52m, "#183153");
                    Text(sb, "ESTADO DE CUENTA - PRESTAMOS", margin, height - 32m, 15, "#FFFFFF", true);
                    TextRight(sb, Cortar(data.Cliente, 45), width - margin, height - 31m, 8, "#DCEBFA", true);
                }

                var top = first ? 374m : 500m;
                DrawEstadoCuentaPrestamoHeader(sb, margin, top);
                var max = first ? 10 : 17;
                var row = 0;
                while (index < loans.Count && row < max)
                {
                    DrawEstadoCuentaPrestamoRow(sb, loans[index], margin, top - 24m - (row * 24m), row % 2 == 1);
                    index++; row++;
                }
                pages.Add(sb);
            } while (index < loans.Count || pages.Count == 0);

            var payments = data.Pagos.Where(x => x.FormaPago != "COMPENSACION").OrderByDescending(x => x.FechaPago).ToList();
            index = 0;
            do
            {
                var sb = new StringBuilder();
                DrawPageBase(sb, width, height, margin, pageNo++);
                Rect(sb, 0, height - 60m, width, 60m, "#0F6E56");
                Text(sb, "PAGOS RECIBIDOS", margin, height - 36m, 16, "#FFFFFF", true);
                TextRight(sb, Cortar(data.Cliente, 48), width - margin, height - 35m, 9, "#D9F4EA", true);
                Rect(sb, margin, 485m, 778m, 25m, "#EAF7F2", "#D2E9DF");
                Text(sb, "FECHA", margin + 10m, 494m, 8, "#36564A", true);
                Text(sb, "PRESTAMO / CUOTA", margin + 115m, 494m, 8, "#36564A", true);
                Text(sb, "FORMA DE PAGO", margin + 250m, 494m, 8, "#36564A", true);
                Text(sb, "GLOSA", margin + 420m, 494m, 8, "#36564A", true);
                TextRight(sb, "IMPORTE", margin + 765m, 494m, 8, "#36564A", true);
                var row = 0;
                while (index < payments.Count && row < 17)
                {
                    var item = payments[index++]; var y = 461m - (row * 25m);
                    Rect(sb, margin, y, 778m, 25m, row % 2 == 1 ? "#F8FBFA" : "#FFFFFF", "#EDF2F0");
                    Text(sb, item.FechaPago?.ToString("dd/MM/yyyy") ?? "", margin + 10m, y + 9m, 8, "#334155", false);
                    Text(sb, $"#{item.IdPrestamo} / {item.NumCuota}", margin + 115m, y + 9m, 8, "#334155", true);
                    Text(sb, Cortar(item.FormaPago, 23), margin + 250m, y + 9m, 8, "#334155", false);
                    Text(sb, Cortar(item.Glosa, 38), margin + 420m, y + 9m, 8, "#64748B", false);
                    TextRight(sb, Money(item.Importe), margin + 765m, y + 9m, 8, "#087253", true);
                    row++;
                }
                if (payments.Count == 0) Text(sb, "No se registran pagos aplicados.", margin + 10m, 452m, 10, "#64748B", false);
                pages.Add(sb);
            } while (index < payments.Count);

            var offsets = data.Compensaciones.OrderByDescending(x => x.Fecha).ThenByDescending(x => x.IdCompensacion).ToList();
            index = 0;
            do
            {
                var sb = new StringBuilder();
                DrawPageBase(sb, width, height, margin, pageNo++);
                Rect(sb, 0, height - 60m, width, 60m, "#4B328A");
                Text(sb, "COMPENSACIONES", margin, height - 36m, 16, "#FFFFFF", true);
                TextRight(sb, Cortar(data.Cliente, 48), width - margin, height - 35m, 9, "#E9E1FF", true);
                Rect(sb, margin, 485m, 778m, 25m, "#F2EDFF", "#E2D8FA");
                Text(sb, "NUMERO / FECHA", margin + 10m, 494m, 8, "#4B328A", true);
                Text(sb, "CONCEPTO", margin + 155m, 494m, 8, "#4B328A", true);
                Text(sb, "PRESTAMOS / CUOTAS", margin + 410m, 494m, 8, "#4B328A", true);
                Text(sb, "ESTADO", margin + 590m, 494m, 8, "#4B328A", true);
                TextRight(sb, "IMPORTE", margin + 765m, 494m, 8, "#4B328A", true);
                var row = 0;
                while (index < offsets.Count && row < 17)
                {
                    var item = offsets[index++]; var y = 461m - (row * 25m);
                    Rect(sb, margin, y, 778m, 25m, row % 2 == 1 ? "#FBFAFE" : "#FFFFFF", "#EEEAF5");
                    Text(sb, $"{item.Numero}  {item.Fecha:dd/MM/yyyy}", margin + 10m, y + 9m, 8, "#334155", true);
                    Text(sb, Cortar(string.IsNullOrWhiteSpace(item.Referencia) ? item.Concepto : $"{item.Concepto} - {item.Referencia}", 48), margin + 155m, y + 9m, 8, "#334155", false);
                    Text(sb, $"{item.Prestamos} / {item.CuotasAfectadas}", margin + 410m, y + 9m, 8, "#334155", false);
                    Text(sb, item.Estado, margin + 590m, y + 9m, 8, item.EstadoCodigo == "A" ? "#087253" : "#B42318", true);
                    TextRight(sb, Money(item.Importe), margin + 765m, y + 9m, 8, item.EstadoCodigo == "A" ? "#6941C6" : "#64748B", true);
                    row++;
                }
                if (offsets.Count == 0) Text(sb, "No se registran compensaciones para el cliente.", margin + 10m, 452m, 10, "#64748B", false);
                pages.Add(sb);
            } while (index < offsets.Count);

            return BuildPdfDocument(pages, width, height);
        }

        private static void DrawEstadoCuentaPrestamoHeader(StringBuilder sb, decimal x, decimal y)
        {
            Rect(sb, x, y, 778m, 24m, "#EEF3F9", "#DBE3EF");
            Text(sb, "PRESTAMO / FECHA", x + 10m, y + 8m, 8, "#4B5A6E", true);
            Text(sb, "CONCEPTO", x + 130m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "CAPITAL", x + 430m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "INTERES", x + 525m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "PAGADO", x + 625m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "SALDO", x + 730m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "ATRASO", x + 768m, y + 8m, 7, "#4B5A6E", true);
        }

        private static void DrawEstadoCuentaPrestamoRow(StringBuilder sb, ReporteEstadoCuentaPrestamoDto item, decimal x, decimal y, bool alt)
        {
            Rect(sb, x, y, 778m, 24m, alt ? "#F8FBFF" : "#FFFFFF", "#EDF0F5");
            Text(sb, $"#{item.IdPrestamo}", x + 10m, y + 9m, 8, "#172033", true);
            Text(sb, item.Fecha.ToString("dd/MM/yyyy"), x + 49m, y + 9m, 7, "#64748B", false);
            Text(sb, Cortar(item.Concepto, 35), x + 130m, y + 9m, 8, "#334155", false);
            TextRight(sb, Money(item.Capital), x + 430m, y + 9m, 8, "#334155", true);
            TextRight(sb, Money(item.Interes), x + 525m, y + 9m, 8, "#B45309", false);
            TextRight(sb, Money(item.TotalPagado), x + 625m, y + 9m, 8, "#087253", true);
            TextRight(sb, Money(item.SaldoPendiente), x + 730m, y + 9m, 8, item.SaldoPendiente > 0 ? "#B42318" : "#334155", true);
            TextRight(sb, item.DiasAtraso > 0 ? $"{item.DiasAtraso}d" : "-", x + 768m, y + 9m, 7, item.DiasAtraso > 0 ? "#B42318" : "#64748B", true);
        }

        private static byte[] CrearPdfGerencial(ReporteDeudaActualResponseDto data)
        {
            const decimal pageWidth = 842m;
            const decimal pageHeight = 595m;
            const decimal margin = 32m;
            const decimal rowHeight = 24m;

            var pages = new List<StringBuilder>();
            var rows = data.Detalle.OrderByDescending(x => x.TotalSaldo).ToList();
            var rowIndex = 0;
            var pageNumber = 1;

            while (rowIndex < rows.Count || pages.Count == 0)
            {
                var isFirstPage = pages.Count == 0;
                var content = new StringBuilder();

                DrawPageBase(content, pageWidth, pageHeight, margin, pageNumber);

                var tableTop = isFirstPage ? 350m : 492m;
                if (isFirstPage)
                {
                    DrawReportHeader(content, data, pageWidth, pageHeight, margin);
                    DrawSummaryCards(content, data, margin, 430m);
                    DrawSectionTitle(content, margin, 384m, "Resumen por cliente y saldo vencido");
                }
                else
                {
                    DrawCompactHeader(content, pageWidth, pageHeight, margin);
                }

                DrawTableHeader(content, margin, tableTop);

                var y = tableTop - rowHeight;
                var maxRows = isFirstPage ? 11 : 17;
                var rowsThisPage = 0;

                while (rowIndex < rows.Count && rowsThisPage < maxRows)
                {
                    DrawTableRow(content, rows[rowIndex], margin, y, rowsThisPage % 2 == 1);
                    y -= rowHeight;
                    rowIndex++;
                    rowsThisPage++;
                }

                DrawTableTotal(content, data, margin, y - 4m);
                pages.Add(content);
                pageNumber++;
            }

            return BuildPdfDocument(pages, pageWidth, pageHeight);
        }

        private static void DrawReportHeader(StringBuilder sb, ReporteDeudaActualResponseDto data, decimal pageWidth, decimal pageHeight, decimal margin)
        {
            Rect(sb, 0, pageHeight - 78m, pageWidth, 78m, "#0B1F3A");
            Rect(sb, 0, pageHeight - 78m, 6m, 78m, "#185FA5");
            Text(sb, "REPORTE DE DEUDA ACTUAL", margin, pageHeight - 39m, 20, "#FFFFFF", true);
            Text(sb, "Cuentas por cobrar de prestamos - fuente SQL de cuotas y cobranza", margin, pageHeight - 58m, 9, "#D8E6F7", false);
            TextRight(sb, $"Emitido: {DateTime.Now:dd/MM/yyyy HH:mm}", pageWidth - margin, pageHeight - 38m, 9, "#D8E6F7", false);
            TextRight(sb, "SGA", pageWidth - margin, pageHeight - 57m, 11, "#FFFFFF", true);

            Rect(sb, margin, pageHeight - 108m, pageWidth - (margin * 2m), 22m, "#F4F7FB", "#DDE4EF");
            Text(sb, "Criterio", margin + 12m, pageHeight - 101m, 8, "#6B7280", true);
            Text(sb, "Clientes con saldo pendiente. Vencido = cuota con fecha menor a hoy y saldo por cobrar.", margin + 75m, pageHeight - 101m, 8, "#374151", false);
        }

        private static void DrawCompactHeader(StringBuilder sb, decimal pageWidth, decimal pageHeight, decimal margin)
        {
            Rect(sb, 0, pageHeight - 52m, pageWidth, 52m, "#0B1F3A");
            Rect(sb, 0, pageHeight - 52m, 6m, 52m, "#185FA5");
            Text(sb, "REPORTE DE DEUDA ACTUAL", margin, pageHeight - 32m, 15, "#FFFFFF", true);
            TextRight(sb, $"Emitido: {DateTime.Now:dd/MM/yyyy HH:mm}", pageWidth - margin, pageHeight - 31m, 8, "#D8E6F7", false);
            DrawSectionTitle(sb, margin, 526m, "Detalle continuacion");
        }

        private static void DrawSummaryCards(StringBuilder sb, ReporteDeudaActualResponseDto data, decimal margin, decimal y)
        {
            var cardWidth = 183m;
            var gap = 12m;
            DrawMetricCard(sb, margin, y, cardWidth, "Clientes", data.Totales.TotalClientes.ToString(CultureInfo.InvariantCulture), "#E8F1FF", "#185FA5");
            DrawMetricCard(sb, margin + cardWidth + gap, y, cardWidth, "Prestamos", data.Totales.TotalPrestamos.ToString(CultureInfo.InvariantCulture), "#EEFDF6", "#0F6E56");
            DrawMetricCard(sb, margin + ((cardWidth + gap) * 2m), y, cardWidth, "Saldo actual", Money(data.Totales.TotalSaldo), "#F4F0FF", "#6D28D9");
            DrawMetricCard(sb, margin + ((cardWidth + gap) * 3m), y, cardWidth, "Total vencido", Money(data.Totales.TotalVencido), "#FEF2F2", "#DC2626");
        }

        private static void DrawMetricCard(StringBuilder sb, decimal x, decimal y, decimal width, string label, string value, string fill, string accent)
        {
            Rect(sb, x, y, width, 58m, "#FFFFFF", "#E5E7EB");
            Rect(sb, x, y, 4m, 58m, accent);
            Rect(sb, x + 13m, y + 14m, 30m, 30m, fill);
            Text(sb, label, x + 54m, y + 36m, 8, "#6B7280", true);
            Text(sb, value, x + 54m, y + 17m, 16, "#0F1F33", true);
        }

        private static void DrawSectionTitle(StringBuilder sb, decimal x, decimal y, string title)
        {
            Rect(sb, x, y - 2m, 4m, 18m, "#185FA5");
            Text(sb, title, x + 10m, y + 3m, 11, "#0F1F33", true);
        }

        private static void DrawTableHeader(StringBuilder sb, decimal x, decimal y)
        {
            Rect(sb, x, y, 778m, 24m, "#EEF3F9", "#DBE3EF");
            Text(sb, "CLIENTE", x + 10m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "PREST.", x + 366m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "CUOTAS", x + 442m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "VENC.", x + 508m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "SALDO", x + 614m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "VENCIDO", x + 720m, y + 8m, 8, "#4B5A6E", true);
            TextRight(sb, "ATRASO", x + 768m, y + 8m, 8, "#4B5A6E", true);
        }

        private static void DrawTableRow(StringBuilder sb, ReporteDeudaActualClienteDto item, decimal x, decimal y, bool alt)
        {
            Rect(sb, x, y, 778m, 24m, alt ? "#F8FBFF" : "#FFFFFF", "#EDF0F5");
            Text(sb, Cortar(item.Cliente, 38), x + 10m, y + 8m, 8.5m, "#1F2937", true);
            Text(sb, Cortar(item.Documento.Trim(), 16), x + 10m, y + 18m, 6.8m, "#6B7280", false);
            TextRight(sb, item.CantPrestamos.ToString(CultureInfo.InvariantCulture), x + 366m, y + 8m, 8, "#374151", false);
            TextRight(sb, item.CuotasPendientes.ToString(CultureInfo.InvariantCulture), x + 442m, y + 8m, 8, "#374151", false);
            TextRight(sb, item.CuotasVencidas.ToString(CultureInfo.InvariantCulture), x + 508m, y + 8m, 8, item.CuotasVencidas > 0 ? "#DC2626" : "#374151", true);
            TextRight(sb, Money(item.TotalSaldo), x + 614m, y + 8m, 8, "#0F1F33", true);
            TextRight(sb, Money(item.TotalVencido), x + 720m, y + 8m, 8, item.TotalVencido > 0 ? "#DC2626" : "#374151", true);
            TextRight(sb, $"{item.DiasAtraso} d", x + 768m, y + 8m, 8, item.DiasAtraso > 0 ? "#92400E" : "#374151", true);
        }

        private static void DrawTableTotal(StringBuilder sb, ReporteDeudaActualResponseDto data, decimal x, decimal y)
        {
            Rect(sb, x, y, 778m, 27m, "#F3F4F6", "#DBE3EF");
            Text(sb, "TOTAL", x + 10m, y + 10m, 9, "#0F1F33", true);
            TextRight(sb, data.Totales.TotalPrestamos.ToString(CultureInfo.InvariantCulture), x + 366m, y + 10m, 9, "#0F1F33", true);
            TextRight(sb, data.Totales.TotalCuotasPendientes.ToString(CultureInfo.InvariantCulture), x + 442m, y + 10m, 9, "#0F1F33", true);
            TextRight(sb, data.Totales.TotalCuotasVencidas.ToString(CultureInfo.InvariantCulture), x + 508m, y + 10m, 9, "#DC2626", true);
            TextRight(sb, Money(data.Totales.TotalSaldo), x + 614m, y + 10m, 9, "#0F1F33", true);
            TextRight(sb, Money(data.Totales.TotalVencido), x + 720m, y + 10m, 9, "#DC2626", true);
        }

        private static void DrawPageBase(StringBuilder sb, decimal pageWidth, decimal pageHeight, decimal margin, int pageNumber)
        {
            Rect(sb, 0, 0, pageWidth, pageHeight, "#F4F6FB");
            Rect(sb, margin, 28m, pageWidth - (margin * 2m), pageHeight - 56m, "#FFFFFF", "#E5E7EB");
            Text(sb, "Sistema Gestion de Alquileres", margin + 10m, 16m, 7, "#9CA3AF", false);
            TextRight(sb, $"Pagina {pageNumber}", pageWidth - margin - 10m, 16m, 7, "#9CA3AF", false);
        }

        private static byte[] BuildPdfDocument(List<StringBuilder> pageContents, decimal pageWidth, decimal pageHeight)
        {
            var objectsById = new SortedDictionary<int, string>();
            var pageObjectIds = new List<int>();
            var fontRegularId = 3 + (pageContents.Count * 2);
            var fontBoldId = fontRegularId + 1;
            var nextObjectId = 3;

            objectsById[1] = "1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n";

            foreach (var content in pageContents)
            {
                var pageId = nextObjectId++;
                var contentId = nextObjectId++;
                pageObjectIds.Add(pageId);

                var stream = content.ToString();
                var streamLength = Encoding.ASCII.GetByteCount(stream);

                objectsById[pageId] = $"{pageId} 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 {PdfNum(pageWidth)} {PdfNum(pageHeight)}] /Resources << /Font << /F1 {fontRegularId} 0 R /F2 {fontBoldId} 0 R >> >> /Contents {contentId} 0 R >> endobj\n";
                objectsById[contentId] = $"{contentId} 0 obj << /Length {streamLength} >> stream\n{stream}endstream endobj\n";
            }

            var kids = string.Join(" ", pageObjectIds.Select(id => $"{id} 0 R"));
            objectsById[2] = $"2 0 obj << /Type /Pages /Kids [{kids}] /Count {pageContents.Count} >> endobj\n";
            objectsById[fontRegularId] = $"{fontRegularId} 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n";
            objectsById[fontBoldId] = $"{fontBoldId} 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >> endobj\n";

            var output = new StringBuilder();
            var offsets = new Dictionary<int, int>();
            output.Append("%PDF-1.4\n");

            foreach (var obj in objectsById)
            {
                offsets[obj.Key] = Encoding.ASCII.GetByteCount(output.ToString());
                output.Append(obj.Value);
            }

            var xrefOffset = Encoding.ASCII.GetByteCount(output.ToString());
            var maxObjectId = objectsById.Keys.Max();
            output.AppendLine("xref");
            output.AppendLine($"0 {maxObjectId + 1}");
            output.AppendLine("0000000000 65535 f ");

            for (var i = 1; i <= maxObjectId; i++)
                output.AppendLine(offsets.ContainsKey(i) ? $"{offsets[i]:0000000000} 00000 n " : "0000000000 65535 f ");

            output.AppendLine("trailer");
            output.AppendLine($"<< /Size {maxObjectId + 1} /Root 1 0 R >>");
            output.AppendLine("startxref");
            output.AppendLine(xrefOffset.ToString(CultureInfo.InvariantCulture));
            output.AppendLine("%%EOF");

            return Encoding.ASCII.GetBytes(output.ToString());
        }

        private static void Rect(StringBuilder sb, decimal x, decimal y, decimal width, decimal height, string fill, string? stroke = null)
        {
            var (fr, fg, fb) = Hex(fill);
            sb.AppendLine("q");
            sb.AppendLine($"{PdfNum(fr)} {PdfNum(fg)} {PdfNum(fb)} rg");
            if (!string.IsNullOrWhiteSpace(stroke))
            {
                var (sr, sg, sbc) = Hex(stroke);
                sb.AppendLine($"{PdfNum(sr)} {PdfNum(sg)} {PdfNum(sbc)} RG");
                sb.AppendLine($"{PdfNum(x)} {PdfNum(y)} {PdfNum(width)} {PdfNum(height)} re B");
            }
            else
            {
                sb.AppendLine($"{PdfNum(x)} {PdfNum(y)} {PdfNum(width)} {PdfNum(height)} re f");
            }
            sb.AppendLine("Q");
        }

        private static void Text(StringBuilder sb, string text, decimal x, decimal y, decimal size, string color, bool bold)
        {
            var (r, g, b) = Hex(color);
            sb.AppendLine("BT");
            sb.AppendLine($"{PdfNum(r)} {PdfNum(g)} {PdfNum(b)} rg");
            sb.AppendLine($"/{(bold ? "F2" : "F1")} {PdfNum(size)} Tf");
            sb.AppendLine($"{PdfNum(x)} {PdfNum(y)} Td");
            sb.AppendLine($"({PdfEscape(text)}) Tj");
            sb.AppendLine("ET");
        }

        private static void TextRight(StringBuilder sb, string text, decimal rightX, decimal y, decimal size, string color, bool bold)
        {
            Text(sb, text, rightX - PdfTextWidth(text, size, bold), y, size, color, bold);
        }

        private static decimal PdfTextWidth(string text, decimal size, bool bold)
        {
            var factor = bold ? 0.56m : 0.52m;
            return RemoveDiacritics(text ?? string.Empty).Length * size * factor;
        }

        private static (decimal R, decimal G, decimal B) Hex(string hex)
        {
            hex = hex.TrimStart('#');
            var r = int.Parse(hex.Substring(0, 2), NumberStyles.HexNumber) / 255m;
            var g = int.Parse(hex.Substring(2, 2), NumberStyles.HexNumber) / 255m;
            var b = int.Parse(hex.Substring(4, 2), NumberStyles.HexNumber) / 255m;
            return (r, g, b);
        }

        private static string PdfNum(decimal value)
        {
            return value.ToString("0.###", CultureInfo.InvariantCulture);
        }

        private static string Cortar(string value, int max)
        {
            if (string.IsNullOrWhiteSpace(value)) return string.Empty;
            return value.Length <= max ? value : value.Substring(0, max - 3) + "...";
        }

        private static string Money(decimal value)
        {
            return $"S/.{value.ToString("#,##0.00", CultureInfo.GetCultureInfo("en-US"))}";
        }

        private static string PdfEscape(string value)
        {
            var normalized = RemoveDiacritics(value ?? string.Empty);
            return normalized.Replace("\\", "\\\\").Replace("(", "\\(").Replace(")", "\\)");
        }

        private static string RemoveDiacritics(string text)
        {
            var normalized = text.Normalize(NormalizationForm.FormD);
            var builder = new StringBuilder();

            foreach (var ch in normalized)
            {
                var category = CharUnicodeInfo.GetUnicodeCategory(ch);
                if (category != UnicodeCategory.NonSpacingMark && ch <= 127)
                    builder.Append(ch);
            }

            return builder.ToString().Normalize(NormalizationForm.FormC);
        }
    }
}
