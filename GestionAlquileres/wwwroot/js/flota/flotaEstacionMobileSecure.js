(function () {
    const page = $(".fm-page");
    if (!page.length) {
        return;
    }

    const state = {
        contratos: [],
        contrato: null,
        operacion: null,
        intervalos: [],
        resumenHoras: null,
        pagos: [],
        combustibles: [],
        combustibleResumen: { totalGalones: 0, totalImporte: 0, totalCargas: 0 },
        resumenGlobal: null,
        detalleGlobal: null,
        pagoSeleccionadoId: 0,
        combustibleSeleccionadoId: 0,
        contratoExpandido: false,
        detalleGlobalExpandido: false,
        tab: String(page.data("tab-inicial") || "intervalos"),
        contratoFijoId: Number(page.data("contrato-fijo") || 0),
        puedeCambiarContrato: String(page.data("puede-cambiar-contrato") || "1") === "1"
    };

    const maxBytes = 5 * 1024 * 1024;
    const extPermitidas = [".jpg", ".jpeg", ".png", ".webp", ".pdf"];
    const maxFechaOperacion = String(page.data("fecha-maxima") || "");
    const money = (v) => "S/." + Number(v || 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    const token = () => $("#flotaMobileToken input[name='__RequestVerificationToken']").val();
    const val = (o, ...keys) => keys.map(k => o?.[k]).find(v => v !== undefined && v !== null);
    const feedback = $("#fmFeedback");

    function messageFromXhr(xhr, fallback) {
        return xhr?.responseJSON?.message || fallback;
    }

    function notify(ok, msg) {
        const text = msg || (ok ? "Operacion completada." : "No se pudo completar la operacion.");
        feedback.removeClass("show ok error").addClass(ok ? "ok" : "error").addClass("show").text(text);
        if (window.Swal) {
            Swal.fire({
                icon: ok ? "success" : "error",
                title: ok ? "Listo" : "No se pudo completar",
                text,
                confirmButtonColor: ok ? "#1268d8" : "#b42318"
            });
        }
    }

    function getJson(url, data) {
        return $.ajax({ url, type: "GET", data: data || {} });
    }

    function postJson(url, data) {
        return $.ajax({
            url,
            type: "POST",
            contentType: "application/json",
            data: JSON.stringify(data),
            headers: { RequestVerificationToken: token() }
        });
    }

    function postForm(url, formData) {
        formData.append("__RequestVerificationToken", token());
        return $.ajax({
            url,
            type: "POST",
            data: formData,
            processData: false,
            contentType: false
        });
    }

    function openModal(selector) {
        $(selector).addClass("open").attr("aria-hidden", "false");
    }

    function closeModal(selector) {
        $(selector).removeClass("open").attr("aria-hidden", "true");
    }

    function currentFecha() {
        return $("#fmFechaOperacion").val();
    }

    function currentContratoId() {
        return Number(val(state.contrato, "idContrato", "IdContrato") || 0);
    }

    function currentOperacionId() {
        return Number(val(state.operacion, "idOperacionDia", "IdOperacionDia") || 0);
    }

    function normalizeText(value) {
        return String(value || "").trim();
    }

    function combineDateTime(fecha, hora) {
        if (!fecha || !hora) {
            return null;
        }
        return `${fecha}T${hora}:00`;
    }

    function toDateValue(value) {
        return String(value || "").slice(0, 10);
    }

    function toDateTimeLabel(value) {
        if (!value) {
            return "-";
        }
        return String(value).replace("T", " ").substring(0, 16);
    }

    function isFutureDate(fecha) {
        return !!fecha && !!maxFechaOperacion && fecha > maxFechaOperacion;
    }

    function validarFechaNoFutura(fecha, mensaje) {
        if (isFutureDate(fecha)) {
            notify(false, mensaje || "No puedes registrar una fecha posterior al dia actual en Peru.");
            return false;
        }
        return true;
    }

    function validarArchivo(file) {
        if (!file) {
            return "Selecciona un archivo.";
        }
        const ext = (file.name.match(/\.[^.]+$/)?.[0] || "").toLowerCase();
        if (!extPermitidas.includes(ext)) {
            return "Archivo invalido. Usa JPG, PNG, WEBP o PDF.";
        }
        if (file.size > maxBytes) {
            return "El archivo supera el maximo de 5 MB.";
        }
        return "";
    }

    function currentOpenInterval() {
        return state.intervalos.find(x => !val(x, "fechaHoraFin", "FechaHoraFin")) || null;
    }

    function initTooltips() {
        if (!window.bootstrap || !window.bootstrap.Tooltip) return;
        document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
            const current = window.bootstrap.Tooltip.getInstance(el);
            if (current) {
                current.dispose();
            }
            new window.bootstrap.Tooltip(el);
        });
    }

    function tab(tabId) {
        state.tab = tabId;
        $(".fm-tab").removeClass("active").filter(`[data-tab='${tabId}']`).addClass("active");
        $(".fm-panel").removeClass("active");
        const map = {
            intervalos: "#fmPanelIntervalos",
            combustible: "#fmPanelCombustible",
            pagos: "#fmPanelPagos",
            historial: "#fmPanelHistorial"
        };
        $(map[tabId] || "#fmPanelIntervalos").addClass("active");
    }

    function resetOperacionState() {
        state.operacion = null;
        state.intervalos = [];
        state.resumenHoras = null;
        $("#fmKmInicial,#fmKmFinal,#fmObservacionIntervaloInicio,#fmObservacionIntervaloFin").val("");
    }

    function getSelectedContrato() {
        const id = Number($("#fmContrato").val() || 0);
        return state.contratos.find(x => Number(val(x, "idContrato", "IdContrato")) === id) || null;
    }

    function renderContratos() {
        const select = $("#fmContrato").empty().append('<option value="">Selecciona contrato...</option>');
        state.contratos.forEach(x => {
            select.append(
                $("<option>")
                    .val(val(x, "idContrato", "IdContrato"))
                    .text(`${val(x, "numero", "Numero")} · ${val(x, "placa", "Placa")} · ${val(x, "chofer", "Chofer")}`)
            );
        });

        if (state.contratoFijoId > 0) {
            select.val(String(state.contratoFijoId)).prop("disabled", true);
        } else {
            select.prop("disabled", !state.puedeCambiarContrato);
        }
    }

    function renderContratoCard() {
        if (!state.contrato) {
            $("#fmContratoResumen").hide();
            return;
        }

        $("#fmContratoResumen").show();
        $("#fmContratoNumero").text(val(state.contrato, "numero", "Numero") || "-");
        $("#fmChofer").text(val(state.contrato, "chofer", "Chofer") || "-");
        $("#fmPlaca").text(val(state.contrato, "placa", "Placa") || "-");
        $("#fmPlacaChip").text(`Placa ${val(state.contrato, "placa", "Placa") || "-"}`);
        $("#fmContratoChip").text(`Contrato ${val(state.contrato, "numero", "Numero") || "-"}`);
        $("#fmContratoCompacto").text(`${val(state.contrato, "chofer", "Chofer") || "-"} · ${val(state.contrato, "modalidad", "Modalidad") || "-"}${val(state.contrato, "periodicidad", "Periodicidad") ? ` · ${val(state.contrato, "periodicidad", "Periodicidad")}` : ""}`);
        $("#fmModalidad").text(`Modalidad: ${val(state.contrato, "modalidad", "Modalidad") || "-"}`);
        $("#fmPeriodicidad").text(`Periodicidad: ${val(state.contrato, "periodicidad", "Periodicidad") || "-"}`);
        $("#fmContratoDetalle").toggle(!!state.contratoExpandido);
        $("#fmToggleContratoResumen").text(state.contratoExpandido ? "Ocultar" : "Ver datos");
        initTooltips();
    }

    function renderResumenGlobal() {
        const resumen = state.resumenGlobal || {};
        $("#fmResumenDeuda").text(money(val(resumen, "deudaGlobal", "DeudaGlobal")));
        $("#fmResumenPagado").text(money(val(resumen, "pagadoGlobal", "PagadoGlobal")));
        $("#fmResumenSaldo").text(money(val(resumen, "saldoGlobal", "SaldoGlobal")));
        $("#fmResumenPendiente").text(money(val(resumen, "pagoDeclaradoPendiente", "PagoDeclaradoPendiente")));
        $("#fmResumenValidado").text(money(val(resumen, "pagoDeclaradoValidadoNoAplicado", "PagoDeclaradoValidadoNoAplicado")));
    }

    function renderDetalleGlobal() {
        const recibosBox = $("#fmDetalleGlobalRecibos").empty();
        const pagosBox = $("#fmDetalleGlobalPagos").empty();
        const data = state.detalleGlobal || {};
        const recibos = val(data, "recibos", "Recibos") || [];
        const pagos = val(data, "pagosDeclarados", "PagosDeclarados") || [];

        if (!recibos.length) {
            recibosBox.html('<div class="fm-empty">No hay recibos reales para mostrar.</div>');
        } else {
            recibos.forEach(x => {
                recibosBox.append(`
                    <div class="fm-card-item">
                        <strong>${val(x, "contratoNumero", "ContratoNumero") || "-"} · ${val(x, "placa", "Placa") || "-"}</strong>
                        <small>Recibo ${val(x, "reciboNumero", "ReciboNumero") || "-"}</small>
                        <small>Periodo: ${toDateValue(val(x, "fechaInicio", "FechaInicio"))} al ${toDateValue(val(x, "fechaFin", "FechaFin"))}</small>
                        <small>Importe: ${money(val(x, "importeRecibo", "ImporteRecibo"))}</small>
                        <small>Pagado: ${money(val(x, "pagado", "Pagado"))}</small>
                        <small>Saldo: ${money(val(x, "saldo", "Saldo"))}</small>
                        <small>Estado: ${val(x, "estado", "Estado") || val(x, "estadoCodigo", "EstadoCodigo") || "-"}</small>
                    </div>`);
            });
        }

        if (!pagos.length) {
            pagosBox.html('<div class="fm-empty">No hay pagos declarados para mostrar.</div>');
        } else {
            pagos.forEach(x => {
                const anulado = (val(x, "flgEstado", "FlgEstado") || "A") === "X";
                const validado = (val(x, "flgValidado", "FlgValidado") || "N") === "S";
                const badge = anulado
                    ? '<span class="fm-state fm-state-error">Anulado</span>'
                    : validado
                        ? '<span class="fm-state fm-state-ok">Validado no aplicado</span>'
                        : '<span class="fm-state fm-state-warn">Pendiente</span>';

                pagosBox.append(`
                    <div class="fm-card-item">
                        <strong>${money(val(x, "importe", "Importe"))}</strong>
                        <small>${val(x, "contratoNumero", "ContratoNumero") || "-"} · ${val(x, "placa", "Placa") || "-"}</small>
                        <small>${toDateValue(val(x, "fechaPago", "FechaPago"))} · ${val(x, "formaPagoTexto", "FormaPagoTexto") || "-"}</small>
                        <small>Disponible: ${money(val(x, "importeDisponible", "ImporteDisponible"))}</small>
                        <small>Referencia: ${val(x, "operacionReferencia", "OperacionReferencia") || "-"}</small>
                        <small>${val(x, "observacion", "Observacion") || "Sin observacion"}</small>
                        ${badge}
                    </div>`);
            });
        }
    }

    function renderOperacion() {
        if (!state.operacion) {
            renderHistorial();
            return;
        }

        const fecha = toDateValue(val(state.operacion, "fecha", "Fecha"));
        $("#fmFechaOperacion").val(fecha);
        $("#fmFechaFinIntervalo").val(fecha);
        $("#fmCombustibleFecha").val(fecha);
        renderHistorial();
    }

    function renderResumenHoras() {
        const resumen = state.resumenHoras || {};
        const totalHoras = Number(val(resumen, "totalHorasDia", "TotalHorasDia") || 0);
        const abiertos = !!val(resumen, "tieneIntervaloAbierto", "TieneIntervaloAbierto");
        const alerta = String(val(resumen, "alertaExcesoHoras", "AlertaExcesoHoras") || "N").toUpperCase() === "S";
        const cantidad = Number(val(resumen, "cantidadIntervalos", "CantidadIntervalos") || state.intervalos.length || 0);

        $("#fmTotalHorasDia").text(`${totalHoras.toFixed(2)} h`);
        $("#fmCantidadIntervalos").text(cantidad);
        $("#fmBadgeIntervaloAbierto").toggle(abiertos);
        $("#fmAbrirIntervalo").prop("disabled", abiertos || !state.contrato);
        $("#fmCerrarIntervalo").prop("disabled", !abiertos || !state.contrato);

        if (alerta) {
            $("#fmAlertaHoras")
                .text(val(resumen, "mensaje", "Mensaje") || "Supera 12 horas acumuladas. Posible dia adicional cobrable.")
                .show();
        } else {
            $("#fmAlertaHoras").hide().text("");
        }
    }

    function renderIntervalos() {
        const box = $("#fmIntervalosLista").empty();
        if (!state.intervalos.length) {
            box.html('<div class="fm-empty">Todavia no hay intervalos registrados para esta fecha operativa.</div>');
            renderResumenHoras();
            renderHistorial();
            return;
        }

        state.intervalos.forEach(x => {
            const abierto = !val(x, "fechaHoraFin", "FechaHoraFin");
            const horas = Number(val(x, "horasCalculadas", "HorasCalculadas") || 0);
            const badge = abierto
                ? '<span class="fm-state fm-state-info">Abierto</span>'
                : `<span class="fm-state fm-state-ok">${horas.toFixed(2)} h</span>`;

            box.append(`
                <div class="fm-card-item">
                    <strong>${toDateTimeLabel(val(x, "fechaHoraInicio", "FechaHoraInicio"))} ${abierto ? "→ En curso" : `→ ${toDateTimeLabel(val(x, "fechaHoraFin", "FechaHoraFin"))}`}</strong>
                    <small>Km inicio: ${val(x, "kmInicio", "KmInicio") ?? "-"}</small>
                    <small>Km fin: ${val(x, "kmFin", "KmFin") ?? "-"}</small>
                    <small>${val(x, "observacion", "Observacion") || "Sin observacion"}</small>
                    ${badge}
                </div>`);
        });

        const abierto = currentOpenInterval();
        if (abierto) {
            $("#fmKmInicial").val(val(abierto, "kmInicio", "KmInicio") ?? "");
        }

        renderResumenHoras();
        renderHistorial();
    }

    function renderCombustibleResumen() {
        const resumen = state.combustibleResumen || {};
        $("#fmCombustibleTotalGalones").text(Number(val(resumen, "totalGalones", "TotalGalones") || 0).toFixed(3));
        $("#fmCombustibleTotalImporte").text(money(val(resumen, "totalImporte", "TotalImporte")));
        $("#fmCombustibleTotalCargas").text(val(resumen, "totalCargas", "TotalCargas") || 0);
    }

    function renderAdjuntosOperacion(adjuntos) {
        const box = $("#fmAdjuntosOperacion").empty();
        if (!adjuntos || !adjuntos.length) {
            box.html('<div class="fm-empty">No hay adjuntos activos del registro del dia.</div>');
            return;
        }

        adjuntos.forEach(x => {
            box.append(`
                <div class="fm-card-item">
                    <strong>${val(x, "nombreOriginal", "NombreOriginal") || "Adjunto"}</strong>
                    <small>${val(x, "observacion", "Observacion") || "Sin observacion"}</small>
                    <a href="${val(x, "rutaArchivo", "RutaArchivo")}" target="_blank" rel="noopener">Ver adjunto</a>
                </div>`);
        });
    }

    function renderAdjuntosPago(adjuntos) {
        const box = $("#fmAdjuntosPago").empty();
        if (!adjuntos || !adjuntos.length) {
            box.html('<div class="fm-empty">No hay vouchers activos para el pago seleccionado.</div>');
            return;
        }

        adjuntos.forEach(x => {
            box.append(`
                <div class="fm-card-item">
                    <strong>${val(x, "nombreOriginal", "NombreOriginal") || "Voucher"}</strong>
                    <small>${val(x, "observacion", "Observacion") || "Sin observacion"}</small>
                    <a href="${val(x, "rutaArchivo", "RutaArchivo")}" target="_blank" rel="noopener">Ver adjunto</a>
                </div>`);
        });
    }

    function renderCombustibles() {
        const list = $("#fmCombustiblesLista").empty();
        const select = $("#fmCombustibleSeleccionado").empty().append('<option value="">Selecciona una carga...</option>');

        if (!state.combustibles.length) {
            list.html('<div class="fm-empty">Todavia no hay cargas de combustible en esta fecha.</div>');
            $("#fmSubirReciboCombustible").prop("disabled", true);
            $("#fmAdjuntosCombustible").html('<div class="fm-empty">Todavia no hay recibos GLP por carga.</div>');
            renderCombustibleResumen();
            renderHistorial();
            return;
        }

        const historial = [];
        state.combustibles.forEach(x => {
            const id = Number(val(x, "idCombustibleOperacion", "IdCombustibleOperacion") || 0);
            list.append(`
                <div class="fm-card-item">
                    <strong>${Number(val(x, "galones", "Galones") || 0).toFixed(3)} gal · ${money(val(x, "importe", "Importe"))}</strong>
                    <small>${toDateValue(val(x, "fecha", "Fecha"))} · ${val(x, "flgPagoCombustibleTexto", "FlgPagoCombustibleTexto") || "-"}</small>
                    <small>${val(x, "observacion", "Observacion") || "Sin observacion"}</small>
                    <div class="fm-card-actions">
                        <button type="button" class="fm-btn fm-btn-soft js-comb-select" data-id="${id}">Usar recibo</button>
                    </div>
                </div>`);
            select.append($("<option>").val(id).text(`${toDateValue(val(x, "fecha", "Fecha"))} · ${Number(val(x, "galones", "Galones") || 0).toFixed(3)} gal · ${money(val(x, "importe", "Importe"))}`));
            historial.push(`<div class="fm-card-item"><strong>${Number(val(x, "galones", "Galones") || 0).toFixed(3)} gal · ${money(val(x, "importe", "Importe"))}</strong><small>${val(x, "flgPagoCombustibleTexto", "FlgPagoCombustibleTexto") || "-"}</small>${(val(x, "adjuntos", "Adjuntos") || []).map(a => `<a href="${val(a, "rutaArchivo", "RutaArchivo")}" target="_blank" rel="noopener">${val(a, "nombreOriginal", "NombreOriginal") || "Adjunto"}</a>`).join("<br>") || '<div class="fm-inline-message">Sin adjuntos activos.</div>'}</div>`);
        });

        if (state.combustibleSeleccionadoId) {
            select.val(String(state.combustibleSeleccionadoId));
        }

        $("#fmSubirReciboCombustible").prop("disabled", !state.combustibleSeleccionadoId);
        $("#fmAdjuntosCombustible").html(historial.join("") || '<div class="fm-empty">Todavia no hay recibos GLP por carga.</div>');
        renderCombustibleResumen();
        renderHistorial();
    }

    function renderPagos() {
        const box = $("#fmPagosDeclarados").empty();
        const select = $("#fmPagoSeleccionado").empty().append('<option value="">Selecciona un pago...</option>');

        if (!state.pagos.length) {
            box.html('<div class="fm-empty">Todavia no hay pagos declarados para este contrato.</div>');
            $("#fmSubirVoucher").prop("disabled", true);
            renderHistorial();
            return;
        }

        state.pagos.forEach(x => {
            const id = Number(val(x, "idPagoContrato", "IdPagoContrato") || 0);
            const validado = (val(x, "flgValidado", "FlgValidado") || "N") === "S";
            const anulado = (val(x, "flgEstado", "FlgEstado") || "A") === "X";
            const puedeEditar = !validado && !anulado && Number(val(x, "importeAplicado", "ImporteAplicado") || 0) <= 0;

            box.append(`
                <div class="fm-card-item">
                    <strong>${money(val(x, "importe", "Importe"))}</strong>
                    <small>${val(x, "contratoNumero", "ContratoNumero") || ""} · ${val(x, "placa", "Placa") || ""}</small>
                    <small>${val(x, "chofer", "Chofer") || ""}</small>
                    <small>${toDateValue(val(x, "fechaPago", "FechaPago"))} · ${val(x, "formaPagoTexto", "FormaPagoTexto") || val(x, "formaPago", "FormaPago") || "-"}</small>
                    <small>Disponible: ${money(val(x, "importeDisponible", "ImporteDisponible"))}</small>
                    <span class="fm-state ${anulado ? "fm-state-error" : validado ? "fm-state-ok" : "fm-state-warn"}">${anulado ? "Anulado" : validado ? "Validado" : "Pendiente"}</span>
                    <small>Pago declarado, aun no aplicado a recibo</small>
                    <div class="fm-card-actions">
                        ${puedeEditar ? `<button type="button" class="fm-btn fm-btn-soft js-pago-editar" data-id="${id}">Editar</button>` : ""}
                        <button type="button" class="fm-btn fm-btn-soft js-pago-voucher" data-id="${id}">Voucher</button>
                    </div>
                </div>`);

            select.append($("<option>").val(id).text(`${toDateValue(val(x, "fechaPago", "FechaPago"))} · ${money(val(x, "importe", "Importe"))} · ${val(x, "formaPagoTexto", "FormaPagoTexto") || val(x, "formaPago", "FormaPago")}`));
        });

        if (state.pagoSeleccionadoId) {
            select.val(String(state.pagoSeleccionadoId));
        }

        $("#fmSubirVoucher").prop("disabled", !state.pagoSeleccionadoId);
        renderHistorial();
    }

    function renderHistorial() {
        const box = $("#fmHistorialResumen").empty();
        if (!state.operacion && !state.intervalos.length) {
            box.html('<div class="fm-empty">Todavia no hay un resumen operativo guardado para esta fecha.</div>');
            return;
        }

        const kmInicial = val(state.operacion, "kmInicial", "KmInicial");
        const kmFinal = val(state.operacion, "kmFinal", "KmFinal");
        const fechaHoraInicio = val(state.operacion, "fechaHoraInicio", "FechaHoraInicio");
        const fechaHoraFin = val(state.operacion, "fechaHoraFin", "FechaHoraFin");
        const recorrido = Number(val(state.operacion, "kmRecorrido", "KmRecorrido") || 0);
        const totalHoras = Number(val(state.resumenHoras, "totalHorasDia", "TotalHorasDia") || 0);
        const abiertos = !!val(state.resumenHoras, "tieneIntervaloAbierto", "TieneIntervaloAbierto");

        box.append(`
            <div class="fm-card-item">
                <strong>Fecha ${toDateValue(val(state.operacion, "fecha", "Fecha") || currentFecha())}</strong>
                <small>Inicio cabecera: ${toDateTimeLabel(fechaHoraInicio)}</small>
                <small>Fin cabecera: ${toDateTimeLabel(fechaHoraFin)}</small>
                <small>Km inicial cabecera: ${kmInicial ?? "-"}</small>
                <small>Km final cabecera: ${kmFinal ?? "-"}</small>
                <small>Km recorrido cabecera: ${recorrido.toFixed(2)}</small>
                <small>Total horas acumuladas: ${totalHoras.toFixed(2)}</small>
                <small>Intervalo abierto: ${abiertos ? "Si" : "No"}</small>
            </div>`);
    }

    function llenarFormasPago(items) {
        const selects = [$("#fmFormaPago"), $("#fmEditFormaPago")];
        selects.forEach(select => {
            select.empty().append('<option value="">Selecciona...</option>');
            items.forEach(x => {
                select.append($("<option>").val(val(x, "idFormaPago", "IdFormaPago")).text(val(x, "tipo", "Tipo") || val(x, "descripcion", "Descripcion") || "-"));
            });
        });
    }

    function abrirEditarPago(idPagoContrato) {
        if (!idPagoContrato) {
            return notify(false, "Selecciona un pago declarado valido.");
        }

        getJson("/Flota/PagoContratoDetalle", { idPagoContrato }).done(r => {
            if (!r.success) {
                return notify(false, r.message || "No se pudo cargar el pago declarado.");
            }

            const pago = val(r, "data") || {};
            $("#fmEditPagoId").val(val(pago, "idPagoContrato", "IdPagoContrato") || 0);
            $("#fmEditFechaPago").val(toDateValue(val(pago, "fechaPago", "FechaPago")));
            $("#fmEditImportePago").val(val(pago, "importe", "Importe") || "");
            $("#fmEditFormaPago").val(String(val(pago, "idFormaPago", "IdFormaPago") || ""));
            $("#fmEditReferenciaPago").val(val(pago, "operacionReferencia", "OperacionReferencia") || "");
            $("#fmEditObservacionPago").val(val(pago, "observacion", "Observacion") || "");
            openModal("#fmEditPagoModal");
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo cargar el pago declarado.")));
    }

    function guardarEdicionPago() {
        const payload = {
            idPagoContrato: Number($("#fmEditPagoId").val() || 0),
            fechaPago: $("#fmEditFechaPago").val(),
            importe: Number($("#fmEditImportePago").val() || 0),
            idFormaPago: Number($("#fmEditFormaPago").val() || 0),
            operacionReferencia: normalizeText($("#fmEditReferenciaPago").val()) || null,
            observacion: normalizeText($("#fmEditObservacionPago").val()) || null
        };

        if (!payload.idPagoContrato) return notify(false, "Selecciona un pago declarado valido.");
        if (!validarFechaNoFutura(payload.fechaPago, "No puedes registrar un pago con una fecha posterior al dia actual en Peru.")) return;
        if (payload.importe <= 0) return notify(false, "Ingresa un importe valido.");
        if (!payload.idFormaPago) return notify(false, "Selecciona la forma de pago.");

        $("#fmGuardarEdicionPago").prop("disabled", true);
        postJson("/Flota/EditarPagoContratoMobile", payload).done(r => {
            notify(r.success, r.message);
            if (r.success) {
                closeModal("#fmEditPagoModal");
                loadPagos().then(loadAdjuntosPago);
                loadResumenGlobal();
                loadDetalleGlobal();
            }
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo editar el pago declarado."))).always(() => $("#fmGuardarEdicionPago").prop("disabled", false));
    }

    function loadResumenGlobal() {
        return getJson("/Flota/MobileResumenGlobal").done(r => {
            if (!r.success) {
                state.resumenGlobal = null;
                renderResumenGlobal();
                return notify(false, r.message || "No se pudo cargar el resumen global del chofer.");
            }
            state.resumenGlobal = val(r, "data") || null;
            renderResumenGlobal();
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo cargar el resumen global del chofer.")));
    }

    function loadDetalleGlobal() {
        return getJson("/Flota/MobileDetalleDeudaGlobal").done(r => {
            if (!r.success) {
                state.detalleGlobal = null;
                renderDetalleGlobal();
                return notify(false, r.message || "No se pudo cargar el detalle global del chofer.");
            }
            state.detalleGlobal = val(r, "data") || null;
            renderDetalleGlobal();
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo cargar el detalle global del chofer.")));
    }

    function loadContratos() {
        return getJson("/Flota/EstacionMobileContratos").done(r => {
            if (!r.success) {
                return notify(false, r.message || "No se pudieron cargar los contratos activos.");
            }

            state.contratos = val(r, "data")?.contratos || [];
            renderContratos();

            if (state.contratoFijoId > 0) {
                state.contrato = state.contratos.find(x => Number(val(x, "idContrato", "IdContrato")) === state.contratoFijoId) || null;
                $("#fmRegistrarPago").prop("disabled", !state.contrato);
                return reloadCurrentContext();
            }

            if (state.contratos.length === 1) {
                state.contrato = state.contratos[0];
                $("#fmContrato").val(String(val(state.contrato, "idContrato", "IdContrato")));
                $("#fmRegistrarPago").prop("disabled", false);
                return reloadCurrentContext();
            }

            state.contrato = null;
            $("#fmRegistrarPago").prop("disabled", true);
            renderContratoCard();
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudieron cargar los contratos activos.")));
    }

    function loadOperacion() {
        if (!state.contrato) {
            resetOperacionState();
            renderContratoCard();
            renderOperacion();
            renderResumenHoras();
            renderIntervalos();
            llenarFormasPago([]);
            return $.Deferred().resolve().promise();
        }

        return getJson("/Flota/OperacionMobileDetalle", {
            idContrato: currentContratoId(),
            fecha: isFutureDate(currentFecha()) ? maxFechaOperacion : currentFecha()
        }).done(r => {
            if (!r.success) {
                return notify(false, r.message || "No se pudo cargar la operacion del dia.");
            }

            const data = val(r, "data") || {};
            state.contrato = val(data, "contrato") || state.contrato;
            state.operacion = val(data, "operacion") || null;
            renderContratoCard();
            renderOperacion();
            llenarFormasPago(val(data, "formasPago") || []);
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo cargar la operacion del dia.")));
    }

    function loadIntervalos() {
        if (!state.contrato) {
            state.intervalos = [];
            renderIntervalos();
            return $.Deferred().resolve().promise();
        }

        return getJson("/Flota/MobileIntervalosDia", {
            idContrato: currentContratoId(),
            fecha: currentFecha()
        }).done(r => {
            if (!r.success) {
                return notify(false, r.message || "No se pudieron cargar los intervalos.");
            }
            state.intervalos = val(r, "data") || [];
            renderIntervalos();
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudieron cargar los intervalos del dia.")));
    }

    function loadResumenHoras() {
        if (!state.contrato) {
            state.resumenHoras = null;
            renderResumenHoras();
            return $.Deferred().resolve().promise();
        }

        return getJson("/Flota/MobileResumenHorasDia", {
            idContrato: currentContratoId(),
            fecha: currentFecha()
        }).done(r => {
            if (!r.success) {
                return notify(false, r.message || "No se pudo cargar el resumen de horas.");
            }
            state.resumenHoras = val(r, "data") || null;
            renderResumenHoras();
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo cargar el resumen de horas.")));
    }

    function loadPagos() {
        if (!state.contrato) {
            state.pagos = [];
            renderPagos();
            return $.Deferred().resolve().promise();
        }

        return getJson("/Flota/PagosContratoPorContrato", { idContrato: currentContratoId() }).done(r => {
            if (!r.success) {
                return notify(false, r.message || "No se pudieron cargar los pagos declarados.");
            }
            state.pagos = val(r, "data") || [];
            if (state.pagoSeleccionadoId && !state.pagos.some(x => Number(val(x, "idPagoContrato", "IdPagoContrato")) === state.pagoSeleccionadoId)) {
                state.pagoSeleccionadoId = 0;
            }
            renderPagos();
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudieron cargar los pagos declarados.")));
    }

    function loadCombustibles() {
        if (!state.contrato) {
            state.combustibles = [];
            state.combustibleResumen = { totalGalones: 0, totalImporte: 0, totalCargas: 0 };
            renderCombustibles();
            return $.Deferred().resolve().promise();
        }

        return getJson("/Flota/CombustiblesPorFecha", {
            idContrato: currentContratoId(),
            fecha: $("#fmCombustibleFecha").val() || currentFecha()
        }).done(r => {
            if (!r.success) {
                return notify(false, r.message || "No se pudieron cargar las cargas de combustible.");
            }
            state.combustibles = val(r, "data")?.cargas || [];
            state.combustibleResumen = val(r, "data")?.resumen || { totalGalones: 0, totalImporte: 0, totalCargas: 0 };
            if (state.combustibleSeleccionadoId && !state.combustibles.some(x => Number(val(x, "idCombustibleOperacion", "IdCombustibleOperacion")) === state.combustibleSeleccionadoId)) {
                state.combustibleSeleccionadoId = 0;
            }
            renderCombustibles();
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudieron cargar las cargas de combustible.")));
    }

    function loadAdjuntosOperacion() {
        if (!currentOperacionId()) {
            renderAdjuntosOperacion([]);
            return $.Deferred().resolve().promise();
        }

        return getJson("/Flota/AdjuntosFlota", { tipoEntidad: "OPERACION_DIA", idEntidad: currentOperacionId() }).done(r => {
            renderAdjuntosOperacion(val(r, "data") || []);
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudieron cargar los adjuntos de operacion.")));
    }

    function loadAdjuntosPago() {
        if (!state.pagoSeleccionadoId) {
            renderAdjuntosPago([]);
            return $.Deferred().resolve().promise();
        }

        return getJson("/Flota/AdjuntosFlota", { tipoEntidad: "PAGO_CONTRATO", idEntidad: state.pagoSeleccionadoId }).done(r => {
            renderAdjuntosPago(val(r, "data") || []);
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudieron cargar los adjuntos del pago.")));
    }

    function reloadCurrentContext() {
        if (isFutureDate(currentFecha())) {
            $("#fmFechaOperacion,#fmFechaFinIntervalo,#fmCombustibleFecha").val(maxFechaOperacion);
        }

        $("#fmFechaFinIntervalo").val(currentFecha());
        $("#fmCombustibleFecha").val(currentFecha());

        return $.when(loadOperacion(), loadIntervalos(), loadResumenHoras(), loadPagos(), loadCombustibles()).then(() =>
            $.when(loadAdjuntosOperacion(), loadAdjuntosPago())
        );
    }

    function abrirIntervalo() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");

        const fecha = $("#fmFechaOperacion").val();
        const hora = $("#fmHoraInicioIntervalo").val();
        if (!validarFechaNoFutura(fecha)) return;
        if (!hora) return notify(false, "Selecciona la hora de inicio.");
        if (!$("#fmKmInicial").val()) return notify(false, "Ingresa el km inicial.");

        const payload = {
            idContrato: currentContratoId(),
            idChofer: val(state.contrato, "idChofer", "IdChofer"),
            idVehiculo: val(state.contrato, "idVehiculo", "IdVehiculo"),
            fechaHoraInicio: combineDateTime(fecha, hora),
            kmInicio: Number($("#fmKmInicial").val() || 0),
            observacion: normalizeText($("#fmObservacionIntervaloInicio").val()) || null
        };

        $("#fmAbrirIntervalo").prop("disabled", true);
        postJson("/Flota/MobileIntervaloAbrir", payload).done(r => {
            notify(r.success, r.message);
            if (r.success) {
                $("#fmObservacionIntervaloInicio").val("");
                reloadCurrentContext();
            }
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo abrir el intervalo."))).always(() => renderResumenHoras());
    }

    function cerrarIntervalo() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");

        const fecha = $("#fmFechaFinIntervalo").val();
        const hora = $("#fmHoraFinIntervalo").val();
        if (!validarFechaNoFutura(fecha)) return;
        if (!hora) return notify(false, "Selecciona la hora de cierre.");
        if (!$("#fmKmFinal").val()) return notify(false, "Ingresa el km final.");

        const abierto = currentOpenInterval();
        if (!abierto) return notify(false, "No hay un intervalo abierto para cerrar.");

        const kmInicio = Number(val(abierto, "kmInicio", "KmInicio") || 0);
        const kmFinal = Number($("#fmKmFinal").val() || 0);
        if (kmInicio && kmFinal < kmInicio) {
            return notify(false, "El km final debe ser mayor o igual que el km inicial del intervalo abierto.");
        }

        const payload = {
            idContrato: currentContratoId(),
            idChofer: val(state.contrato, "idChofer", "IdChofer"),
            idVehiculo: val(state.contrato, "idVehiculo", "IdVehiculo"),
            fechaHoraFin: combineDateTime(fecha, hora),
            kmFin: kmFinal,
            observacion: normalizeText($("#fmObservacionIntervaloFin").val()) || null
        };

        $("#fmCerrarIntervalo").prop("disabled", true);
        postJson("/Flota/MobileIntervaloCerrar", payload).done(r => {
            notify(r.success, r.message);
            if (r.success) {
                $("#fmObservacionIntervaloFin").val("");
                reloadCurrentContext();
            }
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo cerrar el intervalo."))).always(() => renderResumenHoras());
    }

    function registrarCombustible() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");
        const fecha = $("#fmCombustibleFecha").val() || currentFecha();
        if (!validarFechaNoFutura(fecha, "No puedes registrar combustible con una fecha posterior al dia actual en Peru.")) return;

        const payload = {
            idContrato: currentContratoId(),
            idChofer: val(state.contrato, "idChofer", "IdChofer"),
            idVehiculo: val(state.contrato, "idVehiculo", "IdVehiculo"),
            idOperacionDia: currentOperacionId() || null,
            fecha,
            galones: Number($("#fmCombustibleGalones").val() || 0),
            importe: Number($("#fmCombustibleImporte").val() || 0),
            flgPagoCombustible: $("#fmCombustiblePago").val() || null,
            observacion: $("#fmCombustibleObservacion").val()
        };

        $("#fmRegistrarCombustible").prop("disabled", true);
        postJson("/Flota/RegistrarCombustible", payload).done(r => {
            notify(r.success, r.message);
            if (r.success) {
                state.combustibleSeleccionadoId = Number(val(r, "data")?.id || val(r, "data")?.Id || 0);
                $("#fmCombustibleGalones,#fmCombustibleImporte,#fmCombustibleObservacion,#fmReciboCombustibleObs").val("");
                $("#fmReciboCombustibleArchivo").val("");
                $("#fmCombustibleFormCard").hide();
                loadCombustibles();
            }
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo registrar la carga de combustible."))).always(() => $("#fmRegistrarCombustible").prop("disabled", false));
    }

    function registrarPago() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");

        const fechaPago = $("#fmFechaPago").val();
        if (!validarFechaNoFutura(fechaPago, "No puedes registrar un pago con una fecha posterior al dia actual en Peru.")) return;

        const payload = {
            idContrato: currentContratoId(),
            idChofer: val(state.contrato, "idChofer", "IdChofer"),
            idVehiculo: val(state.contrato, "idVehiculo", "IdVehiculo"),
            idOperacionDia: currentOperacionId() || null,
            fechaPago,
            importe: Number($("#fmImportePago").val() || 0),
            idFormaPago: Number($("#fmFormaPago").val() || 0),
            operacionReferencia: $("#fmReferenciaPago").val(),
            observacion: $("#fmObservacionPago").val()
        };

        $("#fmRegistrarPago").prop("disabled", true);
        postJson("/Flota/RegistrarPagoContrato", payload).done(r => {
            notify(r.success, r.message);
            if (r.success) {
                state.pagoSeleccionadoId = Number(val(r, "data")?.id || val(r, "data")?.Id || 0);
                $("#fmImportePago,#fmReferenciaPago,#fmObservacionPago").val("");
                loadPagos().then(loadAdjuntosPago);
                loadResumenGlobal();
                loadDetalleGlobal();
            }
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo registrar el pago declarado."))).always(() => $("#fmRegistrarPago").prop("disabled", !state.contrato));
    }

    function subirAdjuntoCombustible() {
        if (!state.combustibleSeleccionadoId) return notify(false, "Selecciona una carga de combustible.");
        const file = $("#fmReciboCombustibleArchivo")[0].files[0];
        const error = validarArchivo(file);
        if (error) return notify(false, error);

        const form = new FormData();
        form.append("TipoEntidad", "COMBUSTIBLE");
        form.append("IdEntidad", state.combustibleSeleccionadoId);
        form.append("TipoAdjunto", "RECIBO_GLP");
        form.append("Observacion", $("#fmReciboCombustibleObs").val() || "");
        form.append("archivo", file);

        $("#fmSubirReciboCombustible").prop("disabled", true);
        postForm("/Flota/SubirAdjuntoFlota", form).done(r => {
            notify(r.success, r.message);
            if (r.success) {
                $("#fmReciboCombustibleArchivo,#fmReciboCombustibleObs").val("");
                loadCombustibles();
            }
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo subir el recibo GLP."))).always(() => $("#fmSubirReciboCombustible").prop("disabled", !state.combustibleSeleccionadoId));
    }

    function subirAdjuntoPago() {
        if (!state.pagoSeleccionadoId) return notify(false, "Selecciona un pago declarado.");
        const file = $("#fmVoucherArchivo")[0].files[0];
        const error = validarArchivo(file);
        if (error) return notify(false, error);

        const form = new FormData();
        form.append("TipoEntidad", "PAGO_CONTRATO");
        form.append("IdEntidad", state.pagoSeleccionadoId);
        form.append("TipoAdjunto", "VOUCHER_PAGO");
        form.append("Observacion", "Voucher de pago declarado");
        form.append("archivo", file);

        $("#fmSubirVoucher").prop("disabled", true);
        postForm("/Flota/SubirAdjuntoFlota", form).done(r => {
            notify(r.success, r.message);
            if (r.success) {
                $("#fmVoucherArchivo").val("");
                loadAdjuntosPago();
                loadPagos();
            }
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo subir el voucher."))).always(() => $("#fmSubirVoucher").prop("disabled", !state.pagoSeleccionadoId));
    }

    function logout() {
        $("#fmLogout").prop("disabled", true);
        $.ajax({
            url: "/Flota/MobileLogout",
            type: "POST",
            headers: { RequestVerificationToken: token() }
        }).done(r => {
            window.location.href = r?.data?.redirectUrl || "/Flota/MobileLogin";
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo cerrar la sesion."))).always(() => $("#fmLogout").prop("disabled", false));
    }

    $(document).on("click", ".fm-tab", function () {
        tab($(this).data("tab"));
    });

    $(document).on("click", ".js-comb-select", function () {
        state.combustibleSeleccionadoId = Number($(this).data("id") || 0);
        renderCombustibles();
    });

    $(document).on("click", ".js-pago-editar", function () {
        abrirEditarPago(Number($(this).data("id") || 0));
    });

    $(document).on("click", ".js-pago-voucher", function () {
        state.pagoSeleccionadoId = Number($(this).data("id") || 0);
        $("#fmPagoSeleccionado").val(String(state.pagoSeleccionadoId));
        renderPagos();
        loadAdjuntosPago();
        tab("pagos");
        const voucher = document.getElementById("fmVoucherArchivo");
        if (voucher) {
            voucher.scrollIntoView({ behavior: "smooth", block: "center" });
        }
    });

    $("#fmContrato").on("change", function () {
        state.contrato = getSelectedContrato();
        state.pagoSeleccionadoId = 0;
        state.combustibleSeleccionadoId = 0;
        $("#fmRegistrarPago").prop("disabled", !state.contrato);
        reloadCurrentContext();
    });

    $("#fmFechaOperacion").on("change", function () {
        if (isFutureDate($(this).val())) {
            $(this).val(maxFechaOperacion);
            notify(false, "No puedes seleccionar una fecha posterior al dia actual en Peru.");
        }
        $("#fmFechaFinIntervalo").val($(this).val());
        $("#fmCombustibleFecha").val($(this).val());
        reloadCurrentContext();
    });

    $("#fmFechaFinIntervalo").on("change", function () {
        if (isFutureDate($(this).val())) {
            $(this).val(maxFechaOperacion);
            notify(false, "No puedes seleccionar una fecha posterior al dia actual en Peru.");
        }
    });

    $("#fmCombustibleFecha").on("change", function () {
        if (isFutureDate($(this).val())) {
            $(this).val(maxFechaOperacion);
            notify(false, "No puedes seleccionar una fecha posterior al dia actual en Peru.");
        }
        loadCombustibles();
    });

    $("#fmPagoSeleccionado").on("change", function () {
        state.pagoSeleccionadoId = Number($(this).val() || 0);
        renderPagos();
        loadAdjuntosPago();
    });

    $("#fmCombustibleSeleccionado").on("change", function () {
        state.combustibleSeleccionadoId = Number($(this).val() || 0);
        renderCombustibles();
    });

    $("#fmToggleCombustibleForm").on("click", function () {
        $("#fmCombustibleFormCard").toggle();
    });

    $("#fmToggleContratoResumen").on("click", function () {
        state.contratoExpandido = !state.contratoExpandido;
        renderContratoCard();
    });

    $("#fmToggleDetalleGlobal").on("click", function () {
        state.detalleGlobalExpandido = !state.detalleGlobalExpandido;
        $("#fmDetalleGlobalBody").toggle(state.detalleGlobalExpandido);
        $(this).text(state.detalleGlobalExpandido ? "Ocultar detalle" : "Ver detalle");
    });

    $("#fmRefrescarResumenGlobal").on("click", function () {
        loadResumenGlobal();
        loadDetalleGlobal();
    });

    $("#fmAbrirIntervalo").on("click", abrirIntervalo);
    $("#fmCerrarIntervalo").on("click", cerrarIntervalo);
    $("#fmRegistrarCombustible").on("click", registrarCombustible);
    $("#fmRegistrarPago").on("click", registrarPago);
    $("#fmSubirReciboCombustible").on("click", subirAdjuntoCombustible);
    $("#fmSubirVoucher").on("click", subirAdjuntoPago);
    $("#fmLogout").on("click", logout);

    $("#fmCloseEditPago").on("click", function () {
        closeModal("#fmEditPagoModal");
    });

    $("#fmEditPagoModal").on("click", function (e) {
        if (e.target === this) {
            closeModal("#fmEditPagoModal");
        }
    });

    $("#fmEditPagoForm").on("submit", function (e) {
        e.preventDefault();
        guardarEdicionPago();
    });

    $(function () {
        $("#fmFechaOperacion,#fmFechaFinIntervalo,#fmCombustibleFecha,#fmFechaPago,#fmEditFechaPago").attr("max", maxFechaOperacion);
        const now = new Date();
        const hora = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
        $("#fmHoraInicioIntervalo,#fmHoraFinIntervalo").val(hora);
        initTooltips();
        tab(state.tab);
        loadContratos().then(() => {
            if (state.contratoFijoId <= 0) {
                $("#fmRegistrarPago").prop("disabled", true);
            }
            renderAdjuntosOperacion([]);
            renderAdjuntosPago([]);
            renderCombustibles();
            renderPagos();
            renderHistorial();
            renderResumenGlobal();
            renderDetalleGlobal();
            loadResumenGlobal();
            loadDetalleGlobal();
        });
    });
})();
