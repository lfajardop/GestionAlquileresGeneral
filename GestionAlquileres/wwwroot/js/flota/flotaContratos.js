(function(){
    let catalogos = {};
    let contratos = [];
    let contratoActual = null;

    const token = () => $("#flotaContratosToken input[name='__RequestVerificationToken']").val();
    const money = value => "S/." + Number(value || 0).toLocaleString("en-US",{ minimumFractionDigits: 2, maximumFractionDigits: 2 });
    const fmtDate = value => value ? new Date(value).toLocaleDateString("es-PE") : "-";
    const notify = (ok, msg) => window.Swal
        ? Swal.fire({ icon: ok ? "success" : "error", title: ok ? "Listo" : "Revisemos esto", text: msg, confirmButtonColor: ok ? "#185fa5" : "#c62828" })
        : WebApp.Forms.showToast(ok, msg);
    const postJson = (url, data) => $.ajax({
        url,
        type: "POST",
        contentType: "application/json",
        data: JSON.stringify(data),
        headers: { RequestVerificationToken: token() }
    });

    function fillSelect(selector, rows, valueField, textFn){
        const el = $(selector).empty().append('<option value="">Seleccione...</option>');
        rows.forEach(x => el.append($("<option>").val(x[valueField]).text(textFn(x))));
    }

    function estadoBadge(estado){
        return estado === "A"
            ? '<span class="fleet-pill fleet-pill--active">Activo</span>'
            : '<span class="fleet-pill fleet-pill--closed">Cerrado</span>';
    }

    function periodicidadTexto(cod){
        return { D: "Diaria", S: "Semanal", Q: "Quincenal", M: "Mensual" }[cod] || cod || "-";
    }

    function modalidadTexto(cod){
        const item = (catalogos.modalidades || []).find(x => (x.codigo || "").toUpperCase() === (cod || "").toUpperCase());
        return item?.nombre || cod || "-";
    }

    function renderKpi(){
        const activos = contratos.filter(x => x.estado === "A").length;
        const cerrados = contratos.filter(x => x.estado === "C").length;
        const saldo = contratos.reduce((sum, x) => sum + Number(x.saldo || 0), 0);
        $("#kpiContratosActivos").text(activos);
        $("#kpiContratosCerrados").text(cerrados);
        $("#kpiSaldoContratos").text(money(saldo));
    }

    function renderContratos(){
        const tbody = $("#contratosRows").empty();
        if(!contratos.length){
            tbody.append('<tr><td colspan="9" class="fleet-empty">No hay contratos registrados todavía.</td></tr>');
            renderKpi();
            return;
        }

        contratos.forEach(x => {
            const disabledClose = x.estado !== "A" ? "disabled" : "";
            tbody.append(`
                <tr data-id="${x.idContrato}">
                    <td>
                        <strong>${x.numero || "-"}</strong>
                        <div class="fleet-mini">${fmtDate(x.fechaInicio)} a ${fmtDate(x.fechaFin)}</div>
                    </td>
                    <td>${x.chofer || "-"}</td>
                    <td>${x.placa || "-"}</td>
                    <td>${modalidadTexto(x.modalidadCodigo)}</td>
                    <td>${periodicidadTexto(x.periodicidad)}</td>
                    <td>${money(x.tarifaDia)}</td>
                    <td>${estadoBadge(x.estado)}</td>
                    <td>${money(x.saldo)}</td>
                    <td>
                        <div class="d-flex flex-wrap gap-2">
                            <button type="button" class="fleet-btn fleet-btn-soft btn-sm js-ver-contrato" data-id="${x.idContrato}">
                                <i class="bi bi-eye"></i> Ver
                            </button>
                            <a class="fleet-btn fleet-btn-soft btn-sm" href="/Flota/AdminCalendario?idContrato=${x.idContrato}">
                                <i class="bi bi-calendar3"></i> Calendario
                            </a>
                            <button type="button" class="fleet-btn fleet-btn-danger btn-sm js-cerrar-contrato" data-id="${x.idContrato}" ${disabledClose}>
                                <i class="bi bi-lock"></i> Cerrar
                            </button>
                        </div>
                    </td>
                </tr>
            `);
        });

        renderKpi();
    }

    function clearDetalle(){
        contratoActual = null;
        $("#contratoDetalleVacio").removeClass("fleet-hidden");
        $("#contratoDetallePanel").addClass("fleet-hidden");
        $("#formFinalizarContrato")[0].reset();
    }

    function renderDetalle(data){
        contratoActual = data;
        $("#contratoDetalleVacio").addClass("fleet-hidden");
        $("#contratoDetallePanel").removeClass("fleet-hidden");
        $("#detalleNumero").text(data.numero || "-");
        $("#detalleEstado").html(estadoBadge(data.estado));
        $("#detalleChofer").text(data.chofer || "-");
        $("#detallePlaca").text(data.placa || "-");
        $("#detalleModalidad").text(modalidadTexto(data.modalidad));
        $("#detallePeriodicidad").text(periodicidadTexto(data.periodicidad));
        $("#detalleFechaInicio").text(fmtDate(data.fechaInicio));
        $("#detalleFechaFin").text(fmtDate(data.fechaFin));
        $("#detalleTarifa").text(money(data.tarifaDia));
        $("#detalleObservacion").text(data.observacion || "Sin observación.");
        $("#finalizarFechaFin").val((data.fechaFin || new Date().toISOString()).slice(0,10));
        $("#btnFinalizarContrato").prop("disabled", data.estado !== "A");
    }

    function loadCatalogos(){
        return $.getJSON("/Flota/Catalogos").done(r => {
            if(!r.success){
                notify(false, r.message || "No se pudieron cargar los catálogos.");
                return;
            }
            catalogos = r.data || {};
            fillSelect("#contratoVehiculo", catalogos.vehiculos || [], "idVehiculo", x => `${x.placa} · ${x.marca} ${x.modelo}`);
            fillSelect("#contratoChofer", catalogos.choferes || [], "idChofer", x => x.nombres);
            fillSelect("#contratoModalidad", catalogos.modalidades || [], "codigo", x => x.nombre);
        });
    }

    function loadContratos(){
        return $.getJSON("/Flota/ContratosListar").done(r => {
            if(!r.success){
                notify(false, r.message || "No se pudieron listar los contratos.");
                return;
            }
            contratos = r.data || [];
            renderContratos();
            if(contratoActual){
                const stillThere = contratos.find(x => x.idContrato === contratoActual.idContrato);
                if(stillThere){
                    loadDetalle(stillThere.idContrato);
                }else{
                    clearDetalle();
                }
            }
        });
    }

    function loadDetalle(idContrato){
        return $.getJSON("/Flota/ContratoDetalle", { idContrato }).done(r => {
            if(!r.success){
                notify(false, r.message || "No se pudo cargar el detalle del contrato.");
                return;
            }
            renderDetalle(r.data);
        });
    }

    function autoPeriodicidad(){
        const modalidad = ($("#contratoModalidad").val() || "").toUpperCase();
        if(modalidad === "D"){
            $("#contratoPeriodicidad").val("D");
        }
    }

    $(document).on("click", ".js-ver-contrato,.js-cerrar-contrato", function(){
        const idContrato = Number($(this).data("id"));
        if(idContrato > 0){
            loadDetalle(idContrato);
        }
    });

    $("#btnRecargarContratos").on("click", function(){
        loadCatalogos().then(loadContratos);
    });

    $("#contratoModalidad").on("change", autoPeriodicidad);

    $("#formCrearContrato").on("submit", function(ev){
        ev.preventDefault();
        autoPeriodicidad();
        postJson("/Flota/CrearContrato", {
            idVehiculo: Number($("#contratoVehiculo").val()),
            idChofer: Number($("#contratoChofer").val()),
            modalidad: $("#contratoModalidad").val(),
            periodicidad: $("#contratoPeriodicidad").val(),
            fechaInicio: $("#contratoFechaInicio").val(),
            fechaFin: $("#contratoFechaFin").val() || null,
            tarifaDia: Number($("#contratoTarifa").val() || 0),
            cobraDomingo: $("#contratoCobraDomingo").prop("checked"),
            controlKm: $("#contratoControlKm").prop("checked"),
            observacion: $("#contratoObservacion").val()
        }).done(r => {
            notify(r.success, r.message);
            if(r.success){
                $("#formCrearContrato")[0].reset();
                $("#contratoPeriodicidad").val("D");
                loadCatalogos().then(loadContratos);
            }
        }).fail(() => notify(false, "No se pudo crear el contrato."));
    });

    $("#formFinalizarContrato").on("submit", function(ev){
        ev.preventDefault();
        if(!contratoActual){
            notify(false, "Primero selecciona un contrato.");
            return;
        }
        postJson("/Flota/FinalizarContrato", {
            idContrato: contratoActual.idContrato,
            fechaFin: $("#finalizarFechaFin").val(),
            motivoCierre: $("#finalizarMotivo").val(),
            observacion: $("#finalizarObservacion").val()
        }).done(r => {
            notify(r.success, r.message);
            if(r.success){
                loadContratos().then(() => loadDetalle(contratoActual.idContrato));
            }
        }).fail(() => notify(false, "No se pudo cerrar el contrato."));
    });

    $("#formCrearVehiculoRapido").on("submit", function(ev){
        ev.preventDefault();
        postJson("/Flota/CrearVehiculo", {
            placa: $("#vehiculoPlacaRapido").val(),
            marca: $("#vehiculoMarcaRapido").val(),
            modelo: $("#vehiculoModeloRapido").val(),
            compartido: true
        }).done(r => {
            notify(r.success, r.message);
            if(r.success){
                this.reset();
                loadCatalogos();
            }
        }).fail(() => notify(false, "No se pudo crear el vehículo."));
    });

    $("#formCrearChoferRapido").on("submit", function(ev){
        ev.preventDefault();
        postJson("/Flota/CrearChofer", {
            nombres: $("#choferNombreRapido").val(),
            documento: $("#choferDocumentoRapido").val(),
            telefono: $("#choferTelefonoRapido").val()
        }).done(r => {
            notify(r.success, r.message);
            if(r.success){
                this.reset();
                loadCatalogos();
            }
        }).fail(() => notify(false, "No se pudo crear el chofer."));
    });

    $(function(){
        const today = new Date().toISOString().slice(0,10);
        $("#contratoFechaInicio,#finalizarFechaFin").val(today);
        $("#contratoPeriodicidad").val("D");
        loadCatalogos().then(loadContratos);
    });
})();
