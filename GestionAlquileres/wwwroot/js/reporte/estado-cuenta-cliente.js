(function () {
    let dtClientes, dtPrestamos, dtCuotas, dtPagos, dtCompensaciones;
    let seleccionado = null;
    const get = (o, a, b) => o?.[a] ?? o?.[b];
    const dataOf = r => get(r, "data", "Data") || null;
    const okOf = r => !!get(r, "success", "Success");
    const messageOf = r => get(r, "message", "Mensaje") || "No se pudo completar la operacion.";
    const money = value => "S/." + Number(value || 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    const date = value => value ? new Date(value).toLocaleDateString("es-PE", { day: "2-digit", month: "2-digit", year: "numeric" }) : "-";
    const esc = value => $("<div>").text(value || "").html();

    function badge(text, danger) {
        const css = danger ? "danger" : String(text || "").toUpperCase().includes("PAG") ? "ok" : "warn";
        return `<span class="ec-badge ${css}">${esc(text || "Pendiente")}</span>`;
    }

    function initTables() {
        const language = { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" };
        dtClientes = $("#tblEcClientes").DataTable({ paging: true, searching: true, ordering: true, pageLength: 6, autoWidth: false, language,
            columns: [
                { data: "cliente", render: (v, t, r) => `<strong>${esc(v)}</strong><small class="d-block text-muted">${esc(get(r, "cod_Anxo", "Cod_Anxo"))}</small>` },
                { data: "cantPrestamos", className: "text-center" },
                { data: "totalCapital", render: money, className: "text-end fw-semibold" },
                { data: "totalPagado", render: money, className: "text-end text-success fw-semibold" },
                { data: "totalSaldo", render: money, className: "text-end text-danger fw-bold" },
                { data: null, orderable: false, searchable: false, className: "text-end", render: () => '<button class="ec-use" title="Preparar estado de cuenta"><i class="bi bi-arrow-down-circle"></i> Usar</button>' }
            ]
        });
        dtPrestamos = $("#tblEcPrestamos").DataTable({ paging: true, searching: false, ordering: true, pageLength: 8, autoWidth: false, language,
            columns: [
                { data: "idPrestamo", render: v => `<strong>#${v}</strong>` }, { data: "fecha", render: date }, { data: "concepto" },
                { data: "capital", render: money, className: "text-end" }, { data: "interes", render: money, className: "text-end text-warning-emphasis" },
                { data: "totalPagado", render: money, className: "text-end text-success" }, { data: "saldoPendiente", render: money, className: "text-end fw-bold" },
                { data: null, render: r => badge(r.cuotasVencidas > 0 ? `${r.cuotasVencidas} vencida(s) · ${r.diasAtraso} d` : r.estado, r.cuotasVencidas > 0) }
            ]
        });
        dtCuotas = $("#tblEcCuotas").DataTable({ paging: true, searching: true, ordering: true, pageLength: 10, autoWidth: false, language,
            columns: [
                { data: "idPrestamo", render: v => `#${v}` }, { data: "numCuota", className: "text-center" }, { data: "fechaVencimiento", render: date },
                { data: "capital", render: money, className: "text-end" }, { data: "interes", render: money, className: "text-end" },
                { data: "pagado", render: money, className: "text-end text-success" }, { data: "saldo", render: money, className: "text-end fw-bold" },
                { data: null, render: r => badge(r.estado, r.diasAtraso > 0 && r.saldo > 0) }
            ]
        });
        dtPagos = $("#tblEcPagos").DataTable({ paging: true, searching: true, ordering: true, order: [[0, "desc"]], pageLength: 10, autoWidth: false, language,
            columns: [
                { data: "fechaPago", render: date }, { data: "idPrestamo", render: v => `#${v}` }, { data: "numCuota", className: "text-center" },
                { data: "formaPago" }, { data: "cajaBanco" }, { data: "importe", render: money, className: "text-end text-success fw-bold" }, { data: "glosa" }
            ]
        });
        dtCompensaciones = $("#tblEcCompensaciones").DataTable({ paging: true, searching: true, ordering: true, order: [[1, "desc"]], pageLength: 10, autoWidth: false, language,
            columns: [
                { data: "numero", render: v => `<strong>${esc(v)}</strong>` }, { data: "fecha", render: date }, { data: "concepto" },
                { data: "prestamos" }, { data: "cuotasAfectadas", className: "text-center" },
                { data: "importe", render: money, className: "text-end fw-bold" },
                { data: null, render: r => badge(r.estado, String(r.estadoCodigo).toUpperCase() !== "A") }, { data: "observacion" }
            ]
        });
    }

    function loadClients() {
        return WebApp.UI.withSpinner(() => $.getJSON("/Prestamo/ObtenerCtacteClientesResumenGeneral"), "Buscando clientes con prestamos...")
            .done(r => {
                if (!okOf(r)) return WebApp.Forms.showToast(false, messageOf(r));
                const data = dataOf(r) || {};
                dtClientes.clear().rows.add(get(data, "detalle", "Detalle") || []).draw();
            }).fail(() => WebApp.Forms.showToast(false, "No se pudo cargar la lista de clientes."));
    }

    function render(data) {
        const summary = get(data, "resumen", "Resumen") || {};
        $("#ecCliente").text(get(data, "cliente", "Cliente") || "Cliente");
        $("#ecDocumento").text(`Documento: ${get(data, "documento", "Documento") || "Sin documento"}`);
        $("#ecCapital").text(money(get(summary, "totalCapital", "TotalCapital")));
        $("#ecInteres").text(money(get(summary, "totalInteres", "TotalInteres")));
        $("#ecPagosRecibidos").text(money(get(summary, "totalPagosRecibidos", "TotalPagosRecibidos")));
        $("#ecCompensado").text(money(get(summary, "totalCompensado", "TotalCompensado")));
        $("#ecPagado").text(money(get(summary, "totalPagado", "TotalPagado")));
        $("#ecSaldo").text(money(get(summary, "saldoPendiente", "SaldoPendiente")));
        $("#ecVencido").text(money(get(summary, "saldoVencido", "SaldoVencido")));
        $("#ecCuotasVencidas").text(get(summary, "cuotasVencidas", "CuotasVencidas") || 0);
        $("#ecAtraso").text(`${get(summary, "diasAtraso", "DiasAtraso") || 0} dias`);
        $("#ecProximo").text(date(get(summary, "proximoVencimiento", "ProximoVencimiento")));
        dtPrestamos.clear().rows.add(get(data, "prestamos", "Prestamos") || []).draw();
        dtCuotas.clear().rows.add(get(data, "cuotas", "Cuotas") || []).draw();
        const pagos = (get(data, "pagos", "Pagos") || []).filter(x => String(get(x, "formaPago", "FormaPago") || "").toUpperCase() !== "COMPENSACION");
        dtPagos.clear().rows.add(pagos).draw();
        dtCompensaciones.clear().rows.add(get(data, "compensaciones", "Compensaciones") || []).draw();
        $("#ecWorkspace").removeClass("d-none");
        $("#btnEcExcel,#btnEcPdf").prop("disabled", false);
        const query = `codTipAnex=${encodeURIComponent(seleccionado.codTipAnex)}&codAnxo=${encodeURIComponent(seleccionado.codAnxo)}`;
        $("#ecPagoGlobal").attr("href", `/Prestamo/PagoGlobal?${query}`);
        $("#ecContinuacion").attr("href", `/Prestamo/Continuacion?${query}`);
        window.setTimeout(() => window.scrollTo({ top: $("#ecSelected").offset().top - 90, behavior: "smooth" }), 120);
    }

    function loadStatement(row, $button) {
        seleccionado = {
            codTipAnex: get(row, "cod_TipAnex", "Cod_TipAnex"),
            codAnxo: get(row, "cod_Anxo", "Cod_Anxo")
        };
        $("#tblEcClientes tbody tr").removeClass("ec-row-selected");
        $button.closest("tr").addClass("ec-row-selected");
        return WebApp.UI.withSpinner(() => $.getJSON("/Reporte/ObtenerEstadoCuentaCliente", seleccionado), "Preparando el estado de cuenta...")
            .done(r => { if (!okOf(r)) return WebApp.Forms.showToast(false, messageOf(r)); render(dataOf(r)); WebApp.Forms.showToast(true, "Estado de cuenta listo para revisar o compartir."); })
            .fail(() => WebApp.Forms.showToast(false, "No se pudo preparar el estado de cuenta."));
    }

    $(document).on("click", ".ec-use", function () { loadStatement(dtClientes.row($(this).closest("tr")).data(), $(this)); });
    $("#txtEcBuscar").on("input", function () { dtClientes.search(this.value).draw(); });
    $(".ec-tabs button").on("click", function () { $(".ec-tabs button").removeClass("active"); $(this).addClass("active"); $(".ec-panel").removeClass("active"); $("#" + $(this).data("target")).addClass("active"); });
    $("#ecFiltroCuota").on("change", function () { dtCuotas.column(7).search(this.value).draw(); });
    $("#btnEcExcel").on("click", () => exportFile("Excel"));
    $("#btnEcPdf").on("click", () => exportFile("Pdf"));
    function exportFile(type) {
        if (!seleccionado) return WebApp.Forms.showToast(false, "Primero elige un cliente.");
        const query = $.param(seleccionado);
        window.open(`/Reporte/ExportarEstadoCuentaCliente${type}?${query}`, "_blank");
        WebApp.Forms.showToast(true, `${type} generado con el estado de cuenta actual.`);
    }
    $(function () { initTables(); loadClients(); });
})();
