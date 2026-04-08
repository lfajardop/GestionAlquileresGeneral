(function () {
    let dtPrestamos = null;
    let dtAlquileres = null;
    let dtRentas = null;

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
    function abrirModalPagos(nroCobranza, cliente, documento) {
        $("#txtPagoNroCobranza").text(nroCobranza || "");
        $("#txtPagoCliente").text(cliente || "");
        $("#txtPagoDocumento").text(documento || "");
        $("#mdlPagosPrestamo").modal("show");

        // luego aquí llamaremos al backend real
        // cargarResumenPago(nroCobranza);
        // cargarHistorialPagos(nroCobranza);
    }

    function badgeEstado(estado) {
        const e = String(estado || "").toUpperCase();
        if (e === "VENCIDO") return `<span class="badge text-bg-danger">Vencido</span>`;
        if (e === "POR VENCER") return `<span class="badge text-bg-warning">Por vencer</span>`;
        return `<span class="badge text-bg-primary">Pendiente</span>`;
    }

    function initTables() {
        dtPrestamos = $("#tblPrestamos").DataTable({
            paging: true,
            searching: true,
            ordering: true,
            pageLength: 10,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "nroCobranza" },
                { data: "cliente" },
                { data: "documento" },
                { data: "fechaVencimiento", render: fecha },
                { data: "importeCuota", render: money, className: "text-end" },
                { data: "importeCancelado", render: money, className: "text-end" },
                { data: "saldo", render: money, className: "text-end" },
                { data: "diasAtraso", className: "text-center" },
                { data: "estado", render: badgeEstado, className: "text-center" },
                {
                    data: null,
                    orderable: false,
                    searchable: false,
                    className: "text-center",
                    render: function (data, type, row) {
                        return `
                    <button type="button"
                            class="btn btn-sm btn-outline-primary js-ver-pagos"
                            data-nrocobranza="${row.nroCobranza || ''}"
                            data-cliente="${row.cliente || ''}"
                            data-documento="${row.documento || ''}">
                        Pagos
                    </button>`;
                    }
                }
            ]
        });

        dtAlquileres = $("#tblAlquileres").DataTable({
            paging: true,
            searching: true,
            ordering: true,
            pageLength: 10,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "nroCobranza" },
                { data: "tipoOrigen" },
                { data: "cliente" },
                { data: "documento" },
                { data: "fechaVencimiento", render: fecha },
                { data: "saldo", render: money, className: "text-end" },
                { data: "diasAtraso", className: "text-center" },
                { data: "estado", render: badgeEstado, className: "text-center" }
            ]
        });

        dtRentas = $("#tblRentas").DataTable({
            paging: true,
            searching: true,
            ordering: true,
            pageLength: 10,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "nroCobranza" },
                { data: "cliente" },
                { data: "documento" },
                { data: "fechaVencimiento", render: fecha },
                { data: "saldo", render: money, className: "text-end" },
                { data: "diasAtraso", className: "text-center" },
                { data: "estado", render: badgeEstado, className: "text-center" }
            ]
        });
    }

    function cargarResumen() {
        return WebApp.UI.withSpinner(() => $.getJSON("/Cobranza/ObtenerResumen"), "Cargando resumen...")
            .done(function (r) {
                if (!(r.success || r.Success)) {
                    WebApp.Forms.showToast(false, r.message || r.Mensaje || "No se pudo cargar el resumen.");
                    return;
                }

                const d = r.data || r.Data;
                if (!d) return;

                $("#lblTotalPorCobrar").text(money(d.totalPorCobrar ?? d.TotalPorCobrar));
                $("#lblTotalVencido").text(money(d.totalVencido ?? d.TotalVencido));
                $("#lblTotalPorVencer").text(money(d.totalPorVencer14Dias ?? d.TotalPorVencer14Dias));
            })
            .fail(function () {
                WebApp.Forms.showToast(false, "Error al cargar el resumen.");
            });
    }

    function cargarPrestamos() {
        return WebApp.UI.withSpinner(() => $.getJSON("/Cobranza/ListarPrestamosPendientes"), "Cargando préstamos...")
            .done(function (r) {
                if (!(r.success || r.Success)) {
                    WebApp.Forms.showToast(false, r.message || r.Mensaje || "No se pudo cargar préstamos.");
                    dtPrestamos.clear().draw();
                    return;
                }

                const rows = r.data || r.Data || [];
                dtPrestamos.clear().rows.add(rows).draw();
            })
            .fail(function () {
                dtPrestamos.clear().draw();
                WebApp.Forms.showToast(false, "Error al cargar préstamos pendientes.");
            });
    }

    function cargarAlquileres() {
        return WebApp.UI.withSpinner(() => $.getJSON("/Cobranza/ListarAlquileresPendientes"), "Cargando alquileres...")
            .done(function (r) {
                if (!(r.success || r.Success)) {
                    WebApp.Forms.showToast(false, r.message || r.Mensaje || "No se pudo cargar alquileres.");
                    dtAlquileres.clear().draw();
                    return;
                }

                const rows = r.data || r.Data || [];
                dtAlquileres.clear().rows.add(rows).draw();
            })
            .fail(function () {
                dtAlquileres.clear().draw();
                WebApp.Forms.showToast(false, "Error al cargar alquileres pendientes.");
            });
    }

    function cargarRentas() {
        return WebApp.UI.withSpinner(() => $.getJSON("/Cobranza/ListarRentasPorVencer"), "Cargando rentas...")
            .done(function (r) {
                if (!(r.success || r.Success)) {
                    WebApp.Forms.showToast(false, r.message || r.Mensaje || "No se pudo cargar rentas.");
                    dtRentas.clear().draw();
                    return;
                }

                const rows = r.data || r.Data || [];
                dtRentas.clear().rows.add(rows).draw();
            })
            .fail(function () {
                dtRentas.clear().draw();
                WebApp.Forms.showToast(false, "Error al cargar rentas por vencer.");
            });
    }

    $(document).on("click", ".js-ver-pagos", function () {
        const nroCobranza = $(this).data("nrocobranza");
        const cliente = $(this).data("cliente");
        const documento = $(this).data("documento");

        abrirModalPagos(nroCobranza, cliente, documento);
    });

    $(function () {
        initTables();
        cargarResumen();
        cargarPrestamos();
        cargarAlquileres();
        cargarRentas();
    });
})();