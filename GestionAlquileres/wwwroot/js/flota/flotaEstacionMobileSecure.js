(function () {
    const page = $(".fm-page");
    const state = {
        contratos: [],
        contrato: null,
        operacion: null,
        contratoExpandido: false,
        pagos: [],
        combustibles: [],
        combustibleResumen: { totalGalones: 0, totalImporte: 0, totalCargas: 0 },
        pagoSeleccionadoId: 0,
        combustibleSeleccionadoId: 0,
        tab: String(page.data("tab-inicial") || "inicio"),
        contratoFijoId: Number(page.data("contrato-fijo") || 0),
        puedeCambiarContrato: String(page.data("puede-cambiar-contrato") || "1") === "1"
    };

    const maxBytes = 5 * 1024 * 1024;
    const extPermitidas = [".jpg", ".jpeg", ".png", ".webp", ".pdf"];
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

    function normalizeText(value) {
        return String(value || "").trim();
    }

    function parseObservacion(texto) {
        const raw = String(texto || "");
        const lines = raw.split(/\r?\n/);
        const inicio = lines.find(x => x.indexOf("Inicio:") === 0);
        const fin = lines.find(x => x.indexOf("Fin:") === 0);
        return {
            inicio: inicio ? inicio.replace("Inicio:", "").trim() : "",
            fin: fin ? fin.replace("Fin:", "").trim() : ""
        };
    }

    function composeObservacion() {
        const inicio = normalizeText($("#fmObservacionInicio").val());
        const fin = normalizeText($("#fmObservacionFin").val());
        const parts = [];
        if (inicio) parts.push(`Inicio: ${inicio}`);
        if (fin) parts.push(`Fin: ${fin}`);
        return parts.join("\n");
    }

    function currentDateTimeFor(fechaSelector) {
        const fecha = $(fechaSelector).val() || currentFecha();
        const now = new Date();
        return `${fecha}T${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}:${String(now.getSeconds()).padStart(2, "0")}`;
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

    function tab(tabId) {
        state.tab = tabId;
        $(".fm-tab").removeClass("active").filter(`[data-tab='${tabId}']`).addClass("active");
        $(".fm-panel").removeClass("active");
        const map = {
            inicio: "#fmPanelInicio",
            fin: "#fmPanelFin",
            combustible: "#fmPanelCombustible",
            pagos: "#fmPanelPagos",
            historial: "#fmPanelHistorial"
        };
        $(map[tabId] || "#fmPanelInicio").addClass("active");
    }

    function resetOperacionForm() {
        $("#fmKmInicial,#fmKmFinal,#fmObservacionInicio,#fmObservacionFin").val("");
        state.operacion = null;
        renderHistorial();
    }

    function resetCombustibleForm() {
        $("#fmCombustibleFecha").val(currentFecha());
        $("#fmCombustiblePago").val("C");
        $("#fmCombustibleGalones,#fmCombustibleImporte,#fmCombustibleObservacion,#fmReciboCombustibleObs").val("");
        $("#fmReciboCombustibleArchivo").val("");
    }

    function renderContratos() {
        const select = $("#fmContrato").empty().append('<option value="">Selecciona contrato...</option>');
        state.contratos.forEach(x => {
            select.append($("<option>").val(val(x, "idContrato", "IdContrato")).text(`${val(x, "numero", "Numero")} · ${val(x, "placa", "Placa")} · ${val(x, "chofer", "Chofer")}`));
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
        $("#fmContratoCompacto").text(`Placa ${val(state.contrato, "placa", "Placa") || "-"} | Contrato ${val(state.contrato, "numero", "Numero") || "-"}`);
        $("#fmModalidad").text(`Modalidad: ${val(state.contrato, "modalidad", "Modalidad") || "-"}`);
        $("#fmPeriodicidad").text(`Periodicidad: ${val(state.contrato, "periodicidad", "Periodicidad") || "-"}`);
        $("#fmContratoDetalle").toggle(!!state.contratoExpandido);
        $("#fmToggleContratoResumen").text(state.contratoExpandido ? "Ocultar" : "Ver datos");
    }

    function renderOperacion() {
        const op = state.operacion;
        if (!op) {
            resetOperacionForm();
            return;
        }
        const fecha = String(val(op, "fecha", "Fecha") || "").slice(0, 10);
        const observaciones = parseObservacion(val(op, "observacion", "Observacion"));
        const kmInicial = val(op, "kmInicial", "KmInicial");
        const kmFinal = val(op, "kmFinal", "KmFinal");
        const finPendiente = !val(op, "fechaHoraFin", "FechaHoraFin");
        $("#fmFechaOperacion").val(fecha);
        $("#fmFechaFin").val(fecha);
        $("#fmCombustibleFecha").val(fecha);
        $("#fmKmInicial").val(kmInicial ?? "");
        $("#fmKmFinal").val(finPendiente ? "" : (kmFinal ?? ""));
        $("#fmObservacionInicio").val(observaciones.inicio);
        $("#fmObservacionFin").val(observaciones.fin);
        renderHistorial();
    }

    function renderCombustibleResumen() {
        const resumen = state.combustibleResumen || {};
        $("#fmCombustibleTotalGalones").text(Number(val(resumen, "totalGalones", "TotalGalones") || 0).toFixed(3));
        $("#fmCombustibleTotalImporte").text(money(val(resumen, "totalImporte", "TotalImporte")));
        $("#fmCombustibleTotalCargas").text(val(resumen, "totalCargas", "TotalCargas") || 0);
    }

    function adjuntosLinks(adjuntos) {
        if (!adjuntos || !adjuntos.length) return '<div class="fm-inline-message">Sin adjuntos activos.</div>';
        return adjuntos.map(x => `<a href="${val(x, "rutaArchivo", "RutaArchivo")}" target="_blank" rel="noopener">${val(x, "nombreOriginal", "NombreOriginal") || "Adjunto"}</a>`).join("<br>");
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
            const id = val(x, "idCombustibleOperacion", "IdCombustibleOperacion");
            list.append(`
                <div class="fm-card-item">
                    <strong>${Number(val(x, "galones", "Galones") || 0).toFixed(3)} gal · ${money(val(x, "importe", "Importe"))}</strong>
                    <small>${String(val(x, "fecha", "Fecha") || "").slice(0, 10)} · ${val(x, "flgPagoCombustibleTexto", "FlgPagoCombustibleTexto") || "-"}</small>
                    <small>${val(x, "observacion", "Observacion") || "Sin observacion"}</small>
                    <div class="fm-card-actions">
                        <button type="button" class="fm-btn fm-btn-soft js-comb-select" data-id="${id}">Usar recibo</button>
                    </div>
                </div>`);
            select.append($("<option>").val(id).text(`${String(val(x, "fecha", "Fecha") || "").slice(0, 10)} · ${Number(val(x, "galones", "Galones") || 0).toFixed(3)} gal · ${money(val(x, "importe", "Importe"))}`));
            historial.push(`<div class="fm-card-item"><strong>${Number(val(x, "galones", "Galones") || 0).toFixed(3)} gal · ${money(val(x, "importe", "Importe"))}</strong><small>${val(x, "flgPagoCombustibleTexto", "FlgPagoCombustibleTexto") || "-"}</small>${adjuntosLinks(val(x, "adjuntos", "Adjuntos"))}</div>`);
        });
        if (state.combustibleSeleccionadoId) {
            select.val(String(state.combustibleSeleccionadoId));
        }
        $("#fmSubirReciboCombustible").prop("disabled", !state.combustibleSeleccionadoId);
        $("#fmAdjuntosCombustible").html(historial.join("") || '<div class="fm-empty">Todavia no hay recibos GLP por carga.</div>');
        renderCombustibleResumen();
        renderHistorial();
    }

    function renderAdjuntosOperacion(adjuntos) {
        const box = $("#fmAdjuntosOperacion").empty();
        if (!adjuntos || !adjuntos.length) {
            box.html('<div class="fm-empty">No hay adjuntos activos del registro del dia.</div>');
            return;
        }
        adjuntos.forEach(x => box.append(`<div class="fm-card-item"><strong>${val(x, "nombreOriginal", "NombreOriginal") || "Adjunto"}</strong><small>${val(x, "observacion", "Observacion") || "Sin observacion"}</small><a href="${val(x, "rutaArchivo", "RutaArchivo")}" target="_blank" rel="noopener">Ver adjunto</a></div>`));
    }

    function renderAdjuntosPago(adjuntos) {
        const box = $("#fmAdjuntosPago").empty();
        if (!adjuntos || !adjuntos.length) {
            box.html('<div class="fm-empty">No hay vouchers activos para el pago seleccionado.</div>');
            return;
        }
        adjuntos.forEach(x => box.append(`<div class="fm-card-item"><strong>${val(x, "nombreOriginal", "NombreOriginal") || "Voucher"}</strong><small>${val(x, "observacion", "Observacion") || "Sin observacion"}</small><a href="${val(x, "rutaArchivo", "RutaArchivo")}" target="_blank" rel="noopener">Ver adjunto</a></div>`));
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
            const id = val(x, "idPagoContrato", "IdPagoContrato");
            const validado = (val(x, "flgValidado", "FlgValidado") || "N") === "S";
            box.append(`
                <div class="fm-card-item">
                    <strong>${money(val(x, "importe", "Importe"))}</strong>
                    <small>${val(x, "contratoNumero", "ContratoNumero") || ""} · ${val(x, "placa", "Placa") || ""}</small>
                    <small>${val(x, "chofer", "Chofer") || ""}</small>
                    <small>${String(val(x, "fechaPago", "FechaPago") || "").slice(0, 10)} · ${val(x, "formaPagoTexto", "FormaPagoTexto") || val(x, "formaPago", "FormaPago") || "-"}</small>
                    <small>Disponible: ${money(val(x, "importeDisponible", "ImporteDisponible"))}</small>
                    <span class="fm-state ${validado ? "fm-state-ok" : "fm-state-warn"}">${validado ? "Validado" : "Pendiente"}</span>
                    <small>Pago declarado, aun no aplicado a recibo</small>
                </div>`);
            select.append($("<option>").val(id).text(`${String(val(x, "fechaPago", "FechaPago") || "").slice(0, 10)} · ${money(val(x, "importe", "Importe"))} · ${val(x, "formaPagoTexto", "FormaPagoTexto") || val(x, "formaPago", "FormaPago")}`));
        });
        if (state.pagoSeleccionadoId) {
            select.val(String(state.pagoSeleccionadoId));
        }
        $("#fmSubirVoucher").prop("disabled", !state.pagoSeleccionadoId);
        renderHistorial();
    }

    function renderHistorial() {
        const box = $("#fmHistorialResumen").empty();
        if (!state.operacion) {
            box.html('<div class="fm-empty">Todavia no hay un resumen operativo guardado para esta fecha.</div>');
            return;
        }
        const kmInicial = val(state.operacion, "kmInicial", "KmInicial");
        const kmFinal = val(state.operacion, "kmFinal", "KmFinal");
        const fechaHoraInicio = val(state.operacion, "fechaHoraInicio", "FechaHoraInicio");
        const fechaHoraFin = val(state.operacion, "fechaHoraFin", "FechaHoraFin");
        const finPendiente = !fechaHoraFin;
        const recorrido = Number(val(state.operacion, "kmRecorrido", "KmRecorrido") || 0);
        box.append(`
            <div class="fm-card-item">
                <strong>Fecha ${String(val(state.operacion, "fecha", "Fecha") || "").slice(0, 10)}</strong>
                <small>Inicio real: ${fechaHoraInicio ? String(fechaHoraInicio).replace("T", " ").substring(0, 16) : "-"}</small>
                <small>Fin real: ${fechaHoraFin ? String(fechaHoraFin).replace("T", " ").substring(0, 16) : "-"}</small>
                <small>Km inicial: ${kmInicial ?? "-"}</small>
                <small>Km final: ${finPendiente ? "-" : (kmFinal ?? "-")}</small>
                <small>Km recorrido: ${finPendiente ? "-" : recorrido.toFixed(2)}</small>
                <small>Observacion: ${val(state.operacion, "observacion", "Observacion") || "Sin observacion"}</small>
            </div>`);
        if (state.combustibles.length) {
            box.append(`<div class="fm-card-item"><strong>Combustible del dia</strong><small>${state.combustibles.length} cargas registradas</small><small>Total: ${$("#fmCombustibleTotalGalones").text()} gal · ${$("#fmCombustibleTotalImporte").text()}</small></div>`);
        }
        if (state.pagos.length) {
            box.append(`<div class="fm-card-item"><strong>Pagos declarados</strong><small>${state.pagos.length} pagos en este contrato</small><small>El pago declarado no descuenta recibos todavia.</small></div>`);
        }
    }

    function llenarFormasPago(items) {
        const select = $("#fmFormaPago").empty().append('<option value="">Selecciona...</option>');
        (items || []).forEach(x => {
            select.append($("<option>").val(val(x, "idFormaPago", "IdFormaPago")).text(val(x, "tipo", "Tipo") || val(x, "descripcion", "Descripcion") || val(x, "abrev", "Abrev")));
        });
    }

    function getSelectedContrato() {
        const id = Number($("#fmContrato").val() || 0);
        return state.contratos.find(x => Number(val(x, "idContrato", "IdContrato")) === id) || null;
    }

    function validarArchivo(file) {
        if (!file) return "Selecciona un archivo.";
        const ext = "." + file.name.split(".").pop().toLowerCase();
        if (!extPermitidas.includes(ext)) return "Archivo invalido. Usa JPG, PNG, WEBP o PDF.";
        if (file.size > maxBytes) return "Archivo invalido. Maximo 5 MB.";
        return "";
    }

    function loadContratos() {
        return getJson("/Flota/EstacionMobileContratos").done(r => {
            if (!r.success) return notify(false, r.message);
            state.contratos = val(r, "data")?.contratos || [];
            renderContratos();
            if (state.contratoFijoId > 0) {
                state.contrato = state.contratos.find(x => Number(val(x, "idContrato", "IdContrato")) === state.contratoFijoId) || null;
                $("#fmRegistrarPago").prop("disabled", !state.contrato);
                return reloadCurrentContext();
            }
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudieron cargar los contratos activos.")));
    }

    function loadPagos() {
        if (!state.contrato) {
            state.pagos = [];
            renderPagos();
            return $.Deferred().resolve().promise();
        }
        return getJson("/Flota/PagosContratoPorContrato", { idContrato: currentContratoId() }).done(r => {
            if (!r.success) return notify(false, r.message);
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
        return getJson("/Flota/CombustiblesPorFecha", { idContrato: currentContratoId(), fecha: $("#fmCombustibleFecha").val() || currentFecha() }).done(r => {
            if (!r.success) return notify(false, r.message);
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

    function loadOperacion() {
        if (!state.contrato) {
            state.operacion = null;
            renderContratoCard();
            renderOperacion();
            llenarFormasPago([]);
            return $.Deferred().resolve().promise();
        }
        return getJson("/Flota/OperacionMobileDetalle", {
            idContrato: currentContratoId(),
            fecha: currentFecha()
        }).done(r => {
            if (!r.success) return notify(false, r.message);
            const data = val(r, "data") || {};
            state.contrato = val(data, "contrato") || state.contrato;
            state.operacion = val(data, "operacion") || null;
            renderContratoCard();
            renderOperacion();
            llenarFormasPago(val(data, "formasPago") || []);
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo cargar la operacion del dia.")));
    }

    function reloadCurrentContext() {
        $("#fmFechaFin").val(currentFecha());
        $("#fmCombustibleFecha").val(currentFecha());
        return $.when(loadOperacion(), loadPagos(), loadCombustibles()).then(() => $.when(loadAdjuntosOperacion(), loadAdjuntosPago()));
    }

    function buildOperacionPayload(mode) {
        const kmInicialActual = $("#fmKmInicial").val() ? Number($("#fmKmInicial").val()) : null;
        const kmFinalActual = $("#fmKmFinal").val() ? Number($("#fmKmFinal").val()) : null;
        const kmInicialBase = kmInicialActual ?? val(state.operacion, "kmInicial", "KmInicial") ?? null;
        return {
            idContrato: currentContratoId(),
            fecha: currentFecha(),
            modoRegistro: mode === "inicio" ? "I" : "F",
            flgTrabajo: "S",
            codMotivo: "TRA",
            flgCobrable: "S",
            kmInicial: kmInicialBase,
            kmFinal: mode === "inicio" ? null : kmFinalActual,
            galonesCargados: 0,
            importeCombustible: 0,
            flgPagoCombustible: null,
            fechaHoraInicio: mode === "inicio" ? currentDateTimeFor("#fmFechaOperacion") : null,
            fechaHoraFin: mode === "fin" ? currentDateTimeFor("#fmFechaFin") : null,
            observacion: composeObservacion()
        };
    }

    function guardarInicio() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");
        if (!$("#fmKmInicial").val()) return notify(false, "Ingresa el km inicial.");
        const payload = buildOperacionPayload("inicio");
        const actualiza = !!val(state.operacion, "kmInicial", "KmInicial");
        $("#fmGuardarInicio").prop("disabled", true);
        postJson("/Flota/GuardarInicioOperacionMobile", payload).done(r => {
            notify(r.success, r.success ? (actualiza ? "Dato actualizado. Administracion podra revisar el registro." : "Inicio registrado. Administracion podra revisar el estado final del dia.") : r.message);
            if (r.success) reloadCurrentContext();
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo guardar el inicio."))).always(() => $("#fmGuardarInicio").prop("disabled", false));
    }

    function guardarFin() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");
        const kmInicial = Number($("#fmKmInicial").val() || val(state.operacion, "kmInicial", "KmInicial") || 0);
        if (!kmInicial) return notify(false, "Primero registra el km inicial.");
        if (!$("#fmKmFinal").val()) return notify(false, "Ingresa el km final.");
        const kmFinal = Number($("#fmKmFinal").val() || 0);
        if (kmFinal < kmInicial) return notify(false, "El km final debe ser mayor o igual que el km inicial.");
        const payload = buildOperacionPayload("fin");
        const actualiza = !!val(state.operacion, "fechaHoraFin", "FechaHoraFin");
        $("#fmGuardarFin").prop("disabled", true);
        postJson("/Flota/GuardarFinOperacionMobile", payload).done(r => {
            notify(r.success, r.success ? (actualiza ? "Dato actualizado. Administracion podra revisar el registro." : "Fin registrado. Administracion podra revisar el estado final del dia.") : r.message);
            if (r.success) reloadCurrentContext();
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo guardar el fin."))).always(() => $("#fmGuardarFin").prop("disabled", false));
    }

    function registrarCombustible() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");
        const payload = {
            idContrato: currentContratoId(),
            idChofer: val(state.contrato, "idChofer", "IdChofer"),
            idVehiculo: val(state.contrato, "idVehiculo", "IdVehiculo"),
            idOperacionDia: currentOperacionId() || null,
            fecha: $("#fmCombustibleFecha").val() || currentFecha(),
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
                resetCombustibleForm();
                $("#fmCombustibleFormCard").hide();
                loadCombustibles();
            }
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo registrar la carga de combustible."))).always(() => $("#fmRegistrarCombustible").prop("disabled", false));
    }

    function registrarPago() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");
        const payload = {
            idContrato: currentContratoId(),
            idChofer: val(state.contrato, "idChofer", "IdChofer"),
            idVehiculo: val(state.contrato, "idVehiculo", "IdVehiculo"),
            idOperacionDia: currentOperacionId() || null,
            fechaPago: $("#fmFechaPago").val(),
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
                loadPagos().then(loadAdjuntosPago);
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

    $("#fmContrato").on("change", function () {
        state.contrato = getSelectedContrato();
        state.pagoSeleccionadoId = 0;
        state.combustibleSeleccionadoId = 0;
        $("#fmRegistrarPago").prop("disabled", !state.contrato);
        reloadCurrentContext();
    });

    $("#fmFechaOperacion").on("change", function () {
        $("#fmFechaFin").val($(this).val());
        $("#fmCombustibleFecha").val($(this).val());
        reloadCurrentContext();
    });
    $("#fmFechaFin").on("change", function () {
        $("#fmFechaOperacion").val($(this).val());
        $("#fmCombustibleFecha").val($(this).val());
        reloadCurrentContext();
    });
    $("#fmCombustibleFecha").on("change", loadCombustibles);
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
        if ($("#fmCombustibleFormCard").is(":visible")) {
            resetCombustibleForm();
        }
    });
    $("#fmToggleContratoResumen").on("click", function () {
        state.contratoExpandido = !state.contratoExpandido;
        renderContratoCard();
    });
    $("#fmGuardarInicio").on("click", guardarInicio);
    $("#fmGuardarFin").on("click", guardarFin);
    $("#fmRegistrarCombustible").on("click", registrarCombustible);
    $("#fmRegistrarPago").on("click", registrarPago);
    $("#fmSubirReciboCombustible").on("click", subirAdjuntoCombustible);
    $("#fmSubirVoucher").on("click", subirAdjuntoPago);
    $("#fmLogout").on("click", logout);

    $(function () {
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
        });
    });
})();
