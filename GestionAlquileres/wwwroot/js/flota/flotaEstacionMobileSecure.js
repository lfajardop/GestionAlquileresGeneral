(function () {
    const page = $(".fm-page");
    const state = {
        contratos: [],
        contrato: null,
        operacion: null,
        pagos: [],
        combustibles: [],
        combustibleResumen: { totalGalones: 0, totalImporte: 0, totalCargas: 0 },
        pagoSeleccionadoId: 0,
        combustibleSeleccionadoId: 0,
        flgTrabajo: "S",
        tab: String(page.data("tab-inicial") || "dia"),
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
        feedback.removeClass("show ok error").addClass(ok ? "ok" : "error").addClass("show").text(msg || (ok ? "Operacion completada." : "No se pudo completar la operacion."));
        if (window.Swal) {
            Swal.fire({
                icon: ok ? "success" : "error",
                title: ok ? "Listo" : "No se pudo completar",
                text: msg || "",
                confirmButtonColor: ok ? "#0f766e" : "#b42318"
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

    function tab(tabId) {
        state.tab = tabId;
        $(".fm-tab").removeClass("active").filter(`[data-tab='${tabId}']`).addClass("active");
        $(".fm-panel").removeClass("active");
        ({
            dia: "#fmPanelDia",
            combustible: "#fmPanelCombustible",
            pagos: "#fmPanelPagos",
            historial: "#fmPanelHistorial"
        }[tabId] || "#fmPanelDia");
        $(({
            dia: "#fmPanelDia",
            combustible: "#fmPanelCombustible",
            pagos: "#fmPanelPagos",
            historial: "#fmPanelHistorial"
        })[tabId] || "#fmPanelDia").addClass("active");
    }

    function resetOperacionForm() {
        $("#fmMotivo").val("TRA");
        $("#fmKmInicial,#fmKmFinal,#fmObservacionOperacion").val("");
        state.operacion = null;
    }

    function resetCombustibleForm() {
        $("#fmCombustibleFecha").val($("#fmFechaOperacion").val());
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
        $("#fmModalidad").text(`Modalidad: ${val(state.contrato, "modalidad", "Modalidad") || "-"}`);
        $("#fmPeriodicidad").text(`Periodicidad: ${val(state.contrato, "periodicidad", "Periodicidad") || "-"}`);
    }

    function renderOperacion() {
        const op = state.operacion;
        if (!op) {
            resetOperacionForm();
            return;
        }
        $("#fmFechaOperacion").val(String(val(op, "fecha", "Fecha") || "").slice(0, 10));
        $("#fmCombustibleFecha").val(String(val(op, "fecha", "Fecha") || "").slice(0, 10));
        state.flgTrabajo = val(op, "flgTrabajo", "FlgTrabajo") || "S";
        $(".js-flg-trabajo").removeClass("active").filter(`[data-value='${state.flgTrabajo}']`).addClass("active");
        $("#fmMotivo").val(val(op, "codMotivo", "CodMotivo") || "TRA");
        $("#fmKmInicial").val(val(op, "kmInicial", "KmInicial") ?? "");
        $("#fmKmFinal").val(val(op, "kmFinal", "KmFinal") ?? "");
        $("#fmObservacionOperacion").val(val(op, "observacion", "Observacion") || "");
    }

    function renderCombustibleResumen() {
        const resumen = state.combustibleResumen || {};
        $("#fmResumenGalones,#fmCombustibleTotalGalones").text(Number(val(resumen, "totalGalones", "TotalGalones") || 0).toFixed(3));
        $("#fmResumenImporte,#fmCombustibleTotalImporte").text(money(val(resumen, "totalImporte", "TotalImporte")));
        $("#fmResumenCargas,#fmCombustibleTotalCargas").text(val(resumen, "totalCargas", "TotalCargas") || 0);
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
            return;
        }
        const historial = [];
        state.combustibles.forEach(x => {
            const id = val(x, "idCombustibleOperacion", "IdCombustibleOperacion");
            const selected = state.combustibleSeleccionadoId === id;
            list.append(`
                <div class="fm-card-item ${selected ? "active" : ""}">
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
    }

    function llenarFormasPago(items) {
        const select = $("#fmFormaPago").empty().append('<option value="">Selecciona...</option>');
        (items || []).forEach(x => {
            select.append($("<option>").val(val(x, "idFormaPago", "IdFormaPago")).text(val(x, "tipo", "Tipo") || val(x, "descripcion", "Descripcion") || val(x, "abrev", "Abrev")));
        });
    }

    function cargarMotivos() {
        const opciones = [
            { codigo: "TRA", nombre: "Dia trabajado" },
            { codigo: "DES", nombre: "Descanso acordado" },
            { codigo: "MAN", nombre: "Mantenimiento aprobado" },
            { codigo: "AVE", nombre: "Averia del vehiculo" },
            { codigo: "FAL", nombre: "Falta del conductor" },
            { codigo: "OTR", nombre: "Otro motivo autorizado" }
        ];
        const select = $("#fmMotivo").empty();
        opciones.forEach(x => select.append($("<option>").val(x.codigo).text(x.nombre)));
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
        return getJson("/Flota/PagosContratoPorContrato", { idContrato: val(state.contrato, "idContrato", "IdContrato") }).done(r => {
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
        return getJson("/Flota/CombustiblesPorFecha", { idContrato: val(state.contrato, "idContrato", "IdContrato"), fecha: $("#fmCombustibleFecha").val() || $("#fmFechaOperacion").val() }).done(r => {
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
        const idOperacion = Number(val(state.operacion, "idOperacionDia", "IdOperacionDia") || 0);
        if (!idOperacion) {
            renderAdjuntosOperacion([]);
            return $.Deferred().resolve().promise();
        }
        return getJson("/Flota/AdjuntosFlota", { tipoEntidad: "OPERACION_DIA", idEntidad: idOperacion }).done(r => {
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
            idContrato: val(state.contrato, "idContrato", "IdContrato"),
            fecha: $("#fmFechaOperacion").val()
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
        $("#fmCombustibleFecha").val($("#fmFechaOperacion").val());
        return $.when(loadOperacion(), loadPagos(), loadCombustibles()).then(() => $.when(loadAdjuntosOperacion(), loadAdjuntosPago()));
    }

    function registrarOperacion() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");
        const payload = {
            idContrato: val(state.contrato, "idContrato", "IdContrato"),
            fecha: $("#fmFechaOperacion").val(),
            flgTrabajo: state.flgTrabajo,
            codMotivo: $("#fmMotivo").val(),
            kmInicial: $("#fmKmInicial").val() ? Number($("#fmKmInicial").val()) : null,
            kmFinal: $("#fmKmFinal").val() ? Number($("#fmKmFinal").val()) : null,
            galonesCargados: 0,
            importeCombustible: 0,
            flgPagoCombustible: null,
            observacion: $("#fmObservacionOperacion").val()
        };
        $("#fmGuardarOperacion").prop("disabled", true);
        postJson("/Flota/GuardarOperacionMobile", payload).done(r => {
            notify(r.success, r.message);
            if (r.success) reloadCurrentContext();
        }).fail(xhr => notify(false, messageFromXhr(xhr, "No se pudo guardar el dia."))).always(() => $("#fmGuardarOperacion").prop("disabled", false));
    }

    function registrarCombustible() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");
        const payload = {
            idContrato: val(state.contrato, "idContrato", "IdContrato"),
            idChofer: val(state.contrato, "idChofer", "IdChofer"),
            idVehiculo: val(state.contrato, "idVehiculo", "IdVehiculo"),
            idOperacionDia: val(state.operacion, "idOperacionDia", "IdOperacionDia") || null,
            fecha: $("#fmCombustibleFecha").val() || $("#fmFechaOperacion").val(),
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
            idContrato: val(state.contrato, "idContrato", "IdContrato"),
            idChofer: val(state.contrato, "idChofer", "IdChofer"),
            idVehiculo: val(state.contrato, "idVehiculo", "IdVehiculo"),
            idOperacionDia: val(state.operacion, "idOperacionDia", "IdOperacionDia") || null,
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

    $(document).on("click", ".js-flg-trabajo", function () {
        state.flgTrabajo = $(this).data("value");
        $(".js-flg-trabajo").removeClass("active");
        $(this).addClass("active");
    });

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
    $("#fmGuardarOperacion").on("click", registrarOperacion);
    $("#fmRegistrarCombustible").on("click", registrarCombustible);
    $("#fmRegistrarPago").on("click", registrarPago);
    $("#fmSubirReciboCombustible").on("click", subirAdjuntoCombustible);
    $("#fmSubirVoucher").on("click", subirAdjuntoPago);
    $("#fmLogout").on("click", logout);

    $(function () {
        cargarMotivos();
        tab(state.tab);
        loadContratos().then(() => {
            if (state.contratoFijoId <= 0) {
                $("#fmRegistrarPago").prop("disabled", true);
            }
            renderAdjuntosOperacion([]);
            renderAdjuntosPago([]);
            renderCombustibles();
            renderPagos();
        });
    });
})();
