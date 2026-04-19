(function () {
    let dtCtacteGeneral = null;
    let dtCtacteDetalle = null;
    let dtCtacteCuotas = null;

    function money(v) {
        const n = parseFloat(v || 0);
        return "S/ " + n.toFixed(2);
    }

    function fecha(v) {
        if (!v) return "";
        const d = new Date(v);
        if (isNaN(d)) return v;
        const dia = String(d.getDate()).padStart(2, "0");
        const mes = String(d.getMonth() + 1).padStart(2, "0");
        const anio = d.getFullYear();
        return `${dia}/${mes}/${anio}`;
    }

    function limpiarDetalleCliente() {
        $("#Cc_Cod_TipAnex").val("");
        $("#Cc_Cod_Anxo").val("");

        $("#ccCantPrestamos").text("0");
        $("#ccTotalCapital").text("S/ 0.00");
        $("#ccTotalProgramado").text("S/ 0.00");
        $("#ccTotalSaldo").text("S/ 0.00");

        if (dtCtacteDetalle) dtCtacteDetalle.clear().draw();
        if (dtCtacteCuotas) dtCtacteCuotas.clear().draw();
    }

    function initDataTables() {
        dtCtacteGeneral = $("#tblCtacteGeneral").DataTable({
            paging: true,
            searching: true,
            ordering: true,
            pageLength: 10,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "cliente" },
                { data: "cantPrestamos", className: "text-center" },
                { data: "totalCapital", render: money, className: "text-end" },
                { data: "totalProgramado", render: money, className: "text-end" },
                { data: "totalPagado", render: money, className: "text-end" },
                { data: "totalSaldo", render: money, className: "text-end" },
                {
                    data: null,
                    orderable: false,
                    searchable: false,
                    className: "text-center",
                    render: function (data, type, row) {
                        return `
                            <button type="button"
                                    class="btn btn-sm btn-outline-primary js-ver-ctacte-cliente"
                                    data-codtipanex="${row.cod_TipAnex || row.Cod_TipAnex || ''}"
                                    data-codanxo="${row.cod_Anxo || row.Cod_Anxo || ''}"
                                    data-cliente="${row.cliente || row.Cliente || ''}">
                                Ver detalle
                            </button>`;
                    }
                }
            ]
        });

        dtCtacteDetalle = $("#tblCtacteDetalle").DataTable({
            paging: true,
            searching: false,
            ordering: true,
            pageLength: 10,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "id_Prestamo" },
                { data: "fecha", render: fecha },
                { data: "capital", render: money, className: "text-end" },
                { data: "nro_Cuotas", className: "text-center" },
                { data: "porcInteresMensualTexto" },
                { data: "totalProgramado", render: money, className: "text-end" },
                { data: "totalPagado", render: money, className: "text-end" },
                { data: "saldoPendiente", render: money, className: "text-end" },
                { data: "cuotasVencidas", className: "text-center" },
                { data: "diasAtraso", className: "text-center" },
                {
                    data: null,
                    render: function (data, type, row) {
                        return row.conceptoMostrar || row.ConceptoMostrar || row.nombreConcepto || row.NombreConcepto || row.cod_Concepto || row.Cod_Concepto || "";
                    }
                },
                {
                    data: null,
                    orderable: false,
                    searchable: false,
                    className: "text-center",
                    render: function (data, type, row) {
                        return `
                            <button type="button"
                                    class="btn btn-sm btn-outline-secondary js-ver-cuotas-ctacte"
                                    data-idprestamo="${row.id_Prestamo || row.Id_Prestamo || ''}">
                                Ver cuotas
                            </button>`;
                    }
                }
            ]
        });

        dtCtacteCuotas = $("#tblCtacteCuotas").DataTable({
            paging: true,
            searching: false,
            ordering: true,
            pageLength: 10,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "id_Prestamo" },
                { data: "numCuota", className: "text-center" },
                { data: "fec_Venc", render: fecha },
                { data: "importeBase", render: money, className: "text-end" },
                { data: "importeInteres", render: money, className: "text-end" },
                { data: "impCuota", render: money, className: "text-end" },
                { data: "impPagado", render: money, className: "text-end" },
                { data: "saldoCuota", render: money, className: "text-end" },
                { data: "estadoCuota" },
                { data: "diasAtraso", className: "text-center" }
            ]
        });
    }

    function cargarCtacteClientesResumenGeneral() {
        return WebApp.UI.withSpinner(() => $.getJSON("/Prestamo/ObtenerCtacteClientesResumenGeneral"), "Cargando resumen general...")
            .done(function (r) {
                if (!(r.success || r.Success)) {
                    dtCtacteGeneral.clear().draw();
                    $("#cgTotalClientes").text("0");
                    $("#cgTotalPrestamos").text("0");
                    $("#cgTotalCapital").text("S/ 0.00");
                    $("#cgTotalProgramado").text("S/ 0.00");
                    $("#cgTotalPagado").text("S/ 0.00");
                    $("#cgTotalSaldo").text("S/ 0.00");
                    WebApp.Forms.showToast(false, r.message || r.Mensaje || "No se pudo cargar el resumen general.");
                    return;
                }

                const d = r.data || r.Data || {};
                const rows = d.detalle || d.Detalle || [];
                const tot = d.totales || d.Totales || {};

                dtCtacteGeneral.clear().rows.add(rows).draw();

                $("#cgTotalClientes").text(tot.totalClientes || tot.TotalClientes || 0);
                $("#cgTotalPrestamos").text(tot.totalPrestamos || tot.TotalPrestamos || 0);
                $("#cgTotalCapital").text(money(tot.totalCapital || tot.TotalCapital || 0));
                $("#cgTotalProgramado").text(money(tot.totalProgramado || tot.TotalProgramado || 0));
                $("#cgTotalPagado").text(money(tot.totalPagado || tot.TotalPagado || 0));
                $("#cgTotalSaldo").text(money(tot.totalSaldo || tot.TotalSaldo || 0));
            })
            .fail(function () {
                dtCtacteGeneral.clear().draw();
                WebApp.Forms.showToast(false, "Error al cargar el resumen general.");
            });
    }

    function cargarCtacteClienteResumen(codTipAnex, codAnxo) {
        return $.getJSON("/Prestamo/ObtenerCtacteClienteResumen", { codTipAnex, codAnxo })
            .done(function (r) {
                if (!(r.success || r.Success)) {
                    $("#ccCantPrestamos").text("0");
                    $("#ccTotalCapital").text("S/ 0.00");
                    $("#ccTotalProgramado").text("S/ 0.00");
                    $("#ccTotalSaldo").text("S/ 0.00");
                    return;
                }

                const d = r.data || r.Data || {};
                $("#ccCantPrestamos").text(d.cantPrestamos || d.CantPrestamos || 0);
                $("#ccTotalCapital").text(money(d.totalCapital || d.TotalCapital || 0));
                $("#ccTotalProgramado").text(money(d.totalProgramado || d.TotalProgramado || 0));
                $("#ccTotalSaldo").text(money(d.saldoPendiente || d.SaldoPendiente || 0));
            });
    }

    function cargarCtacteClienteDetalle(codTipAnex, codAnxo) {
        return $.getJSON("/Prestamo/ObtenerCtacteClienteDetalle", { codTipAnex, codAnxo })
            .done(function (r) {
                if (!(r.success || r.Success)) {
                    dtCtacteDetalle.clear().draw();
                    WebApp.Forms.showToast(false, r.message || r.Mensaje || "No se pudo cargar el detalle del cliente.");
                    return;
                }

                const rows = r.data || r.Data || [];
                dtCtacteDetalle.clear().rows.add(rows).draw();
            })
            .fail(function () {
                dtCtacteDetalle.clear().draw();
                WebApp.Forms.showToast(false, "Error al cargar detalle del cliente.");
            });
    }

    function cargarCtacteClienteCuotas(codTipAnex, codAnxo, idPrestamo) {
        return $.getJSON("/Prestamo/ObtenerCtacteClienteCuotas", { codTipAnex, codAnxo })
            .done(function (r) {
                if (!(r.success || r.Success)) {
                    dtCtacteCuotas.clear().draw();
                    WebApp.Forms.showToast(false, r.message || r.Mensaje || "No se pudo cargar cuotas.");
                    return;
                }

                const d = r.data || r.Data || {};
                let rows = d.detalle || d.Detalle || [];

                if (idPrestamo) {
                    rows = rows.filter(x => String(x.id_Prestamo || x.Id_Prestamo) === String(idPrestamo));
                }

                dtCtacteCuotas.clear().rows.add(rows).draw();
            })
            .fail(function () {
                dtCtacteCuotas.clear().draw();
                WebApp.Forms.showToast(false, "Error al cargar cuotas.");
            });
    }

    function cargarCuentaCorrienteCliente(codTipAnex, codAnxo) {
        $("#Cc_Cod_TipAnex").val(codTipAnex);
        $("#Cc_Cod_Anxo").val(codAnxo);

        return WebApp.UI.withSpinner(() =>
            $.when(
                cargarCtacteClienteResumen(codTipAnex, codAnxo),
                cargarCtacteClienteDetalle(codTipAnex, codAnxo),
                cargarCtacteClienteCuotas(codTipAnex, codAnxo, null)
            ),
            "Cargando cuenta corriente del cliente..."
        );
    }

    $("#btnRefrescarCtacteGeneral").on("click", function () {
        cargarCtacteClientesResumenGeneral();
    });

    $(document).on("click", ".js-ver-ctacte-cliente", function () {
        const codTipAnex = $(this).data("codtipanex");
        const codAnxo = $(this).data("codanxo");
        cargarCuentaCorrienteCliente(codTipAnex, codAnxo);
    });

    $(document).on("click", ".js-ver-cuotas-ctacte", function () {
        const idPrestamo = $(this).data("idprestamo");
        const codTipAnex = $("#Cc_Cod_TipAnex").val();
        const codAnxo = $("#Cc_Cod_Anxo").val();

        if (!codTipAnex || !codAnxo) {
            WebApp.Forms.showToast(false, "Primero selecciona un cliente.");
            return;
        }

        cargarCtacteClienteCuotas(codTipAnex, codAnxo, idPrestamo)
            .done(function () {

                // 🔹 mostrar label
                $("#lblPrestamoCuotasSeleccionado")
                    .text("Mostrando cuotas del préstamo #" + idPrestamo);

                // 🔹 scroll suave
                const $destino = $("#tblCtacteCuotas");
                if ($destino.length) {
                    $("html, body").animate({
                        scrollTop: $destino.offset().top - 120
                    }, 250);
                }
            });
    });

    $("#btnVerTodasCuotas").on("click", function () {
        const codTipAnex = $("#Cc_Cod_TipAnex").val();
        const codAnxo = $("#Cc_Cod_Anxo").val();

        if (!codTipAnex || !codAnxo) return;

        cargarCtacteClienteCuotas(codTipAnex, codAnxo, null)
            .done(function () {
                $("#lblPrestamoCuotasSeleccionado")
                    .text("Mostrando todas las cuotas del cliente");
            });
    });

    $(function () {
        initDataTables();
        limpiarDetalleCliente();
    });
})();