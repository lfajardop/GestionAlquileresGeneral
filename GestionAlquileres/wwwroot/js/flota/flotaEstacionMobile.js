(function () {
    const state = {
        contratos: [],
        contrato: null,
        operacion: null,
        pagos: [],
        pagoSeleccionadoId: 0,
        flgTrabajo: "S"
    };

    const maxBytes = 5 * 1024 * 1024;
    const extPermitidas = [".jpg", ".jpeg", ".png", ".webp", ".pdf"];
    const money = (v) => "S/." + Number(v || 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    const token = () => $("#flotaMobileToken input[name='__RequestVerificationToken']").val();
    const val = (o, ...keys) => keys.map(k => o?.[k]).find(v => v !== undefined && v !== null);
    const feedback = $("#fmFeedback");

    function notify(ok, msg) {
        feedback.removeClass("show ok error").addClass(ok ? "ok" : "error").addClass("show").text(msg || (ok ? "Operación completada." : "No se pudo completar la operación."));
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

    function resetOperacionForm() {
        $("#fmMotivo").val("TRA");
        $("#fmCobrable").val("S");
        $("#fmKmInicial,#fmKmFinal,#fmObservacionOperacion").val("");
        $("#fmGalones,#fmCostoGlp").val("0");
        $("#fmPagoCombustible").val("");
        state.operacion = null;
    }

    function renderContratos() {
        const select = $("#fmContrato").empty().append('<option value="">Selecciona contrato...</option>');
        state.contratos.forEach(x => {
            select.append($("<option>").val(val(x, "idContrato", "IdContrato")).text(`${val(x, "numero", "Numero")} · ${val(x, "placa", "Placa")} · ${val(x, "chofer", "Chofer")}`));
        });
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
        const tieneOperacion = !!val(op, "idOperacionDia", "IdOperacionDia");
        if (!op) {
            resetOperacionForm();
        } else {
            $("#fmFechaOperacion").val(String(val(op, "fecha", "Fecha") || "").slice(0, 10));
            state.flgTrabajo = val(op, "flgTrabajo", "FlgTrabajo") || "S";
            $(".js-flg-trabajo").removeClass("active").filter(`[data-value='${state.flgTrabajo}']`).addClass("active");
            $("#fmMotivo").val(val(op, "codMotivo", "CodMotivo") || "TRA");
            $("#fmCobrable").val(val(op, "flgCobrable", "FlgCobrable") || "S");
            $("#fmKmInicial").val(val(op, "kmInicial", "KmInicial") ?? "");
            $("#fmKmFinal").val(val(op, "kmFinal", "KmFinal") ?? "");
            $("#fmGalones").val(val(op, "galonesCargados", "GalonesCargados") ?? 0);
            $("#fmCostoGlp").val(val(op, "importeCombustible", "ImporteCombustible") ?? 0);
            $("#fmPagoCombustible").val(val(op, "flgPagoCombustible", "FlgPagoCombustible") || "");
            $("#fmObservacionOperacion").val(val(op, "observacion", "Observacion") || "");
        }
        $("#fmSubirReciboGlp").prop("disabled", !tieneOperacion);
    }

    function renderAdjuntosOperacion(adjuntos) {
        const box = $("#fmAdjuntosOperacion").empty();
        if (!adjuntos || !adjuntos.length) {
            box.html('<div class="fm-empty">No hay adjuntos activos del recibo GLP.</div>');
            return;
        }
        adjuntos.forEach(x => {
            box.append(`<div class="fm-item"><strong>${val(x, "nombreOriginal", "NombreOriginal") || "Adjunto"}</strong><small>${val(x, "observacion", "Observacion") || "Sin observación"}</small><a href="${val(x, "rutaArchivo", "RutaArchivo")}" target="_blank" rel="noopener">Ver adjunto</a></div>`);
        });
    }

    function renderAdjuntosPago(adjuntos) {
        const box = $("#fmAdjuntosPago").empty();
        if (!adjuntos || !adjuntos.length) {
            box.html('<div class="fm-empty">No hay vouchers activos para el pago seleccionado.</div>');
            return;
        }
        adjuntos.forEach(x => {
            box.append(`<div class="fm-item"><strong>${val(x, "nombreOriginal", "NombreOriginal") || "Voucher"}</strong><small>${val(x, "observacion", "Observacion") || "Sin observación"}</small><a href="${val(x, "rutaArchivo", "RutaArchivo")}" target="_blank" rel="noopener">Ver adjunto</a></div>`);
        });
    }

    function renderPagos() {
        const box = $("#fmPagosDeclarados").empty();
        const select = $("#fmPagoSeleccionado").empty().append('<option value="">Selecciona un pago...</option>');
        if (!state.pagos.length) {
            box.html('<div class="fm-empty">Todavía no hay pagos declarados para este contrato.</div>');
            $("#fmSubirVoucher").prop("disabled", true);
            return;
        }
        state.pagos.forEach(x => {
            const id = val(x, "idPagoContrato", "IdPagoContrato");
            const validado = (val(x, "flgValidado", "FlgValidado") || "N") === "S";
            box.append(`
                <button type="button" class="fm-payment-card js-pago-card ${state.pagoSeleccionadoId === id ? "active" : ""}" data-id="${id}">
                    <strong>${money(val(x, "importe", "Importe"))}</strong>
                    <small>${val(x, "contratoNumero", "ContratoNumero") || ""} · ${val(x, "placa", "Placa") || ""}</small>
                    <small>${val(x, "chofer", "Chofer") || ""}</small>
                    <small>${String(val(x, "fechaPago", "FechaPago") || "").slice(0, 10)} · ${val(x, "formaPagoTexto", "FormaPagoTexto") || val(x, "formaPago", "FormaPago") || "-"}</small>
                    <small>Disponible: ${money(val(x, "importeDisponible", "ImporteDisponible"))}</small>
                    <span class="fm-state ${validado ? "fm-state-ok" : "fm-state-warn"}">${validado ? "Validado" : "Pendiente"}</span>
                    <small>Pago declarado, aún no aplicado a recibo</small>
                </button>`);
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
            { codigo: "TRA", nombre: "Día trabajado" },
            { codigo: "DES", nombre: "Descanso acordado" },
            { codigo: "MAN", nombre: "Mantenimiento aprobado" },
            { codigo: "AVE", nombre: "Avería del vehículo" },
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
        if (!extPermitidas.includes(ext)) return "Archivo inválido. Usa JPG, PNG, WEBP o PDF.";
        if (file.size > maxBytes) return "Archivo inválido. Máximo 5 MB.";
        return "";
    }

    function loadContratos() {
        return getJson("/Flota/EstacionMobileContratos").done(r => {
            if (!r.success) return notify(false, r.message);
            state.contratos = val(r, "data")?.contratos || [];
            renderContratos();
        }).fail(() => notify(false, "No se pudieron cargar los contratos activos."));
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
        }).fail(() => notify(false, "No se pudieron cargar los pagos declarados."));
    }

    function loadAdjuntosOperacion() {
        const idOperacion = Number(val(state.operacion, "idOperacionDia", "IdOperacionDia") || 0);
        if (!idOperacion) {
            renderAdjuntosOperacion([]);
            return $.Deferred().resolve().promise();
        }
        return getJson("/Flota/AdjuntosFlota", { tipoEntidad: "OPERACION_DIA", idEntidad: idOperacion }).done(r => {
            renderAdjuntosOperacion(val(r, "data") || []);
        }).fail(() => notify(false, "No se pudieron cargar los adjuntos de operación."));
    }

    function loadAdjuntosPago() {
        if (!state.pagoSeleccionadoId) {
            renderAdjuntosPago([]);
            return $.Deferred().resolve().promise();
        }
        return getJson("/Flota/AdjuntosFlota", { tipoEntidad: "PAGO_CONTRATO", idEntidad: state.pagoSeleccionadoId }).done(r => {
            renderAdjuntosPago(val(r, "data") || []);
        }).fail(() => notify(false, "No se pudieron cargar los adjuntos del pago."));
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
            renderAdjuntosOperacion(val(data, "adjuntos") || []);
        }).fail(() => notify(false, "No se pudo cargar la operación del día."));
    }

    function reloadCurrentContext() {
        return $.when(loadOperacion(), loadPagos()).then(() => loadAdjuntosPago());
    }

    function registrarOperacion() {
        if (!state.contrato) return notify(false, "Selecciona un contrato.");
        const payload = {
            idContrato: val(state.contrato, "idContrato", "IdContrato"),
            fecha: $("#fmFechaOperacion").val(),
            flgTrabajo: state.flgTrabajo,
            codMotivo: $("#fmMotivo").val(),
            flgCobrable: $("#fmCobrable").val(),
            kmInicial: $("#fmKmInicial").val() ? Number($("#fmKmInicial").val()) : null,
            kmFinal: $("#fmKmFinal").val() ? Number($("#fmKmFinal").val()) : null,
            galonesCargados: Number($("#fmGalones").val() || 0),
            importeCombustible: Number($("#fmCostoGlp").val() || 0),
            flgPagoCombustible: $("#fmPagoCombustible").val() || null,
            observacion: $("#fmObservacionOperacion").val()
        };
        $("#fmGuardarOperacion").prop("disabled", true);
        postJson("/Flota/GuardarOperacionMobile", payload).done(r => {
            notify(r.success, r.message);
            if (r.success) reloadCurrentContext();
        }).fail(() => notify(false, "No se pudo guardar la operación.")).always(() => $("#fmGuardarOperacion").prop("disabled", false));
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
                reloadCurrentContext();
            }
        }).fail(() => notify(false, "No se pudo registrar el pago declarado.")).always(() => $("#fmRegistrarPago").prop("disabled", !state.contrato));
    }

    function subirAdjuntoOperacion() {
        const idOperacion = Number(val(state.operacion, "idOperacionDia", "IdOperacionDia") || 0);
        if (!idOperacion) return notify(false, "Primero guarda la operación del día.");
        const file = $("#fmReciboGlpArchivo")[0].files[0];
        const error = validarArchivo(file);
        if (error) return notify(false, error);
        const form = new FormData();
        form.append("TipoEntidad", "OPERACION_DIA");
        form.append("IdEntidad", idOperacion);
        form.append("TipoAdjunto", "RECIBO_GLP");
        form.append("Observacion", $("#fmReciboGlpObs").val() || "");
        form.append("archivo", file);
        $("#fmSubirReciboGlp").prop("disabled", true);
        postForm("/Flota/SubirAdjuntoFlota", form).done(r => {
            notify(r.success, r.message);
            if (r.success) {
                $("#fmReciboGlpArchivo").val("");
                $("#fmReciboGlpObs").val("");
                loadAdjuntosOperacion();
            }
        }).fail(() => notify(false, "No se pudo subir el recibo GLP.")).always(() => $("#fmSubirReciboGlp").prop("disabled", false));
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
        }).fail(() => notify(false, "No se pudo subir el voucher.")).always(() => $("#fmSubirVoucher").prop("disabled", !state.pagoSeleccionadoId));
    }

    $(document).on("click", ".js-flg-trabajo", function () {
        state.flgTrabajo = $(this).data("value");
        $(".js-flg-trabajo").removeClass("active");
        $(this).addClass("active");
    });

    $(document).on("click", ".js-pago-card", function () {
        state.pagoSeleccionadoId = Number($(this).data("id") || 0);
        renderPagos();
        loadAdjuntosPago();
    });

    $("#fmContrato").on("change", function () {
        state.contrato = getSelectedContrato();
        state.pagoSeleccionadoId = 0;
        $("#fmRegistrarPago").prop("disabled", !state.contrato);
        reloadCurrentContext();
    });

    $("#fmFechaOperacion").on("change", loadOperacion);
    $("#fmPagoSeleccionado").on("change", function () {
        state.pagoSeleccionadoId = Number($(this).val() || 0);
        renderPagos();
        loadAdjuntosPago();
    });
    $("#fmGuardarOperacion").on("click", registrarOperacion);
    $("#fmRegistrarPago").on("click", registrarPago);
    $("#fmSubirReciboGlp").on("click", subirAdjuntoOperacion);
    $("#fmSubirVoucher").on("click", subirAdjuntoPago);

    $(function () {
        cargarMotivos();
        loadContratos().then(() => {
            $("#fmRegistrarPago").prop("disabled", true);
            renderAdjuntosOperacion([]);
            renderAdjuntosPago([]);
            renderPagos();
        });
    });
})();
