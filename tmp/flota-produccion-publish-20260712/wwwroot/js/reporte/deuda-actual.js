(function () {
    let dtDeuda = null;
    let chartDeuda = null;
    let ultimaConsulta = {};

    function money(v) {
        const n = parseFloat(v || 0);
        return "S/." + n.toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    function buildQuery() {
        const filtro = {
            fechaDesde: $("#FechaDesde").val() || "",
            fechaHasta: $("#FechaHasta").val() || "",
            cliente: $("#Cliente").val() || "",
            estado: $("#Estado").val() || ""
        };

        ultimaConsulta = filtro;
        return $.param(filtro);
    }

    function initTable() {
        if (dtDeuda) return dtDeuda;

        const $tabla = $("#tblDeudaActual");
        if (!$tabla.length || !$.fn.DataTable) return null;

        dtDeuda = $("#tblDeudaActual").DataTable({
            paging: true,
            searching: true,
            ordering: true,
            pageLength: 10,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "cliente" },
                { data: "documento" },
                { data: "cantPrestamos", className: "text-center" },
                { data: "cuotasPendientes", className: "text-center" },
                { data: "cuotasVencidas", className: "text-center" },
                { data: "totalSaldo", render: money, className: "text-end fw-semibold" },
                { data: "totalVencido", render: money, className: "text-end text-danger fw-semibold" },
                {
                    data: "diasAtraso",
                    className: "text-center",
                    render: function (value) {
                        return (parseInt(value || 0) || 0) + " dias";
                    }
                }
            ]
        });

        return dtDeuda;
    }

    function tablaDeuda() {
        return dtDeuda || initTable();
    }

    function renderChart(rows) {
        const top = rows.slice(0, 8);
        const labels = top.map(x => x.cliente || "");
        const values = top.map(x => parseFloat(x.totalSaldo || 0));

        if (chartDeuda) {
            chartDeuda.destroy();
        }

        const ctx = document.getElementById("chartDeudaCliente");
        chartDeuda = new Chart(ctx, {
            type: "bar",
            data: {
                labels: labels,
                datasets: [{
                    label: "Saldo",
                    data: values,
                    backgroundColor: "#0b5cad",
                    borderColor: "#084a8c",
                    borderWidth: 1,
                    borderRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: function (ctx) {
                                return money(ctx.raw);
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        ticks: {
                            maxRotation: 35,
                            minRotation: 0
                        }
                    },
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: function (value) {
                                return money(value);
                            }
                        }
                    }
                }
            }
        });
    }

    function pintarTotales(tot) {
        $("#lblClientes").text(tot.totalClientes || 0);
        $("#lblPrestamos").text(tot.totalPrestamos || 0);
        $("#lblVencido").text(money(tot.totalVencido || 0));
        $("#lblSaldo").text(money(tot.totalSaldo || 0));
    }

    function cargarReporte() {
        const query = buildQuery();

        return WebApp.UI.withSpinner(() => $.getJSON("/Reporte/ObtenerDeudaActual?" + query), "Cargando deuda actual...")
            .done(function (r) {
                if (!(r.success || r.Success)) {
                    WebApp.Forms.showToast(false, r.message || r.Mensaje || "No se pudo cargar el reporte.");
                    const tabla = tablaDeuda();
                    if (tabla) tabla.clear().draw();
                    pintarTotales({});
                    renderChart([]);
                    return;
                }

                const data = r.data || r.Data || {};
                const rows = data.detalle || data.Detalle || [];
                const tot = data.totales || data.Totales || {};

                const tabla = tablaDeuda();
                if (tabla) tabla.clear().rows.add(rows).draw();
                pintarTotales(tot);
                renderChart(rows);
            })
            .fail(function () {
                const tabla = tablaDeuda();
                if (tabla) tabla.clear().draw();
                pintarTotales({});
                renderChart([]);
                WebApp.Forms.showToast(false, "Error al cargar deuda actual.");
            });
    }

    function exportar(url) {
        const query = $.param(ultimaConsulta || {});
        window.location.href = url + (query ? "?" + query : "");
    }

    $("#btnGenerarReporte").on("click", cargarReporte);
    $("#btnExportExcel").on("click", function () {
        buildQuery();
        exportar("/Reporte/ExportarDeudaActualExcel");
    });
    $("#btnExportPdf").on("click", function () {
        buildQuery();
        exportar("/Reporte/ExportarDeudaActualPdf");
    });

    $(function () {
        initTable();
        cargarReporte();
    });
})();
