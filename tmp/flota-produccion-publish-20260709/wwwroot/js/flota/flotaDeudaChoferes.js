(function(){
    let rows = [];

    const money = value => "S/." + Number(value || 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    const fmtDate = value => value ? new Date(value).toLocaleDateString("es-PE") : "-";
    const notify = (ok, msg) => window.Swal
        ? Swal.fire({ icon: ok ? "success" : "error", title: ok ? "Listo" : "Revisemos esto", text: msg, confirmButtonColor: ok ? "#185fa5" : "#c62828" })
        : WebApp.Forms.showToast(ok, msg);

    function renderKpi(){
        $("#kpiChoferes").text(rows.length);
        $("#kpiSaldoReal").text(money(rows.reduce((sum, item) => sum + Number(item.saldoRecibos || 0), 0)));
        $("#kpiPagoPendiente").text(money(rows.reduce((sum, item) => sum + Number(item.pagoDeclaradoPendiente || 0), 0)));
        $("#kpiPagoValidado").text(money(rows.reduce((sum, item) => sum + Number(item.pagoDeclaradoValidadoNoAplicado || 0), 0)));
    }

    function renderRows(){
        const tbody = $("#deudaChoferesRows").empty();
        if(!rows.length){
            tbody.append('<tr><td colspan="10" class="fleet-empty">No hay deuda consolidada para mostrar.</td></tr>');
            renderKpi();
            return;
        }

        rows.forEach(item => {
            tbody.append(`
                <tr>
                    <td>
                        <strong>${item.chofer || "-"}</strong>
                        <div class="fleet-mini">Id ${item.idChofer || 0}</div>
                    </td>
                    <td>${item.documento || "-"}</td>
                    <td>${item.telefono || "-"}</td>
                    <td>
                        <strong>${item.totalContratos || 0}</strong>
                        <div class="fleet-mini">Activos ${item.contratosActivos || 0} · Cerrados ${item.contratosCerrados || 0}</div>
                    </td>
                    <td>${money(item.totalGeneradoRecibos)}</td>
                    <td>${money(item.totalPagadoRecibos)}</td>
                    <td><strong>${money(item.saldoRecibos)}</strong></td>
                    <td>${money(item.pagoDeclaradoPendiente)}</td>
                    <td>${money(item.pagoDeclaradoValidadoNoAplicado)}</td>
                    <td>${fmtDate(item.ultimaFechaDeuda)}</td>
                </tr>
            `);
        });

        renderKpi();
    }

    function loadRows(){
        return $.getJSON("/Flota/DeudaChoferesListar").done(r => {
            if(!r.success){
                notify(false, r.message || "No se pudo consultar la deuda global por chofer.");
                return;
            }
            rows = r.data || [];
            renderRows();
        }).fail(() => notify(false, "No se pudo consultar la deuda global por chofer."));
    }

    $("#btnRecargarDeudaChoferes").on("click", loadRows);

    $(function(){
        loadRows();
    });
})();
