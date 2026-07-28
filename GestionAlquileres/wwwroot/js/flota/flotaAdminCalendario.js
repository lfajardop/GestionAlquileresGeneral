(function () {
    let contratos = [];
    let calendario = null;
    let recibos = [];
    let seleccion = new Set();
    let catalogos = { motivosDia: [], motivos: [] };
    let detalleActual = null;
    let diaActual = null;

    const money = v => "S/." + Number(v || 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    const date = v => v ? new Date(String(v).substring(0, 10) + "T12:00:00").toLocaleDateString("es-PE") : "-";
    const dateTimeLocal = v => v ? String(v).replace("T", " ").substring(0, 16) : "-";
    const dateTimeInput = v => v ? String(v).substring(0, 16) : "";
    const timeShort = v => v ? String(v).substring(11, 16) : "";
    const token = () => $("#faToken input[name='__RequestVerificationToken']").val();
    const notify = (ok, msg) => Swal.fire({ icon: ok ? "success" : "error", title: ok ? "Listo" : "No se pudo completar", text: msg, confirmButtonColor: ok ? "#087253" : "#b42318" });
    const jsonPost = (url, data) => $.ajax({ url: url, type: "POST", contentType: "application/json", data: JSON.stringify(data), headers: { RequestVerificationToken: token() } });
    const postAdmin = (url, payload) => $.ajax({ url: url, type: "POST", contentType: "application/json", data: JSON.stringify(payload), headers: { RequestVerificationToken: token() } });
    const selectedContract = () => contratos.find(x => x.idContrato === Number($("#faContrato").val()));
    const successMessages = [
        "Recibo anulado correctamente.",
        "Dia retirado del recibo correctamente.",
        "Pago editado correctamente.",
        "Pago anulado correctamente.",
        "Validacion de pago actualizada correctamente.",
        "Operacion del dia corregida correctamente."
    ];

    function isSuccessResponse(r) {
        return !!r && r.success === true && successMessages.includes(r.message);
    }

    function closeModal(id) {
        $(id).removeClass("open").attr("aria-hidden", "true");
    }

    function openModal(id) {
        $(id).addClass("open").attr("aria-hidden", "false");
    }

    function motivosActivos() {
        const rows = catalogos.motivosDia?.length ? catalogos.motivosDia : (catalogos.motivos || []);
        return rows.filter(x => {
            const activo = x.flgActivo || x.Flg_Activo || "S";
            return String(activo).toUpperCase() === "S";
        });
    }

    function setMotivoOptions(select, current) {
        const $select = $(select).empty();
        const motivos = motivosActivos();
        $select.append($("<option>").val("").text("Selecciona motivo..."));
        if (!motivos.length) {
            if (current) {
                $select.append($("<option>").val(current).text(current));
            }
            $select.val(current || "");
            return;
        }

        motivos.forEach(x => {
            const value = x.codigo || x.codMotivo || x.id || "";
            const text = x.nombre || x.descripcion || x.texto || value;
            $select.append($("<option>").val(value).text(text));
        });

        if (current) {
            $select.val(current);
            if ($select.val() !== current) {
                $select.append($("<option>").val(current).text(current));
                $select.val(current);
            }
        }
    }

    function loadContracts() {
        return $.getJSON("/Flota/ContratosAdmin").done(r => {
            if (!r.success) {
                notify(false, r.message);
                return;
            }

            contratos = r.data || [];
            const s = $("#faContrato").empty().append('<option value="">Selecciona contrato...</option>');
            contratos.forEach(x => s.append($("<option>").val(x.idContrato).text(x.numero + " · " + x.placa + " · " + x.chofer)));
        });
    }

    function loadCatalogs() {
        return $.getJSON("/Flota/Catalogos").done(r => {
            if (r.success) {
                catalogos = r.data || catalogos;
                setMotivoOptions("#faCorrectDayCode", "");
            }
        });
    }

    function monthParts() {
        const p = $("#faMes").val().split("-");
        return { anio: Number(p[0]), mes: Number(p[1]) };
    }

    function isMobileIntervalDay(day) {
        return !!day &&
            day.trabajo === "S" &&
            day.codMotivo === "TRA" &&
            day.cobrable === "S" &&
            day.tieneRecibo !== "S" &&
            Number(day.importe || 0) === 0 &&
            day.origen === "O";
    }

    function buildDayMeta(day) {
        if (!day) {
            return { badges: [], lines: [] };
        }

        if (day.tieneRecibo === "S") {
            return { badges: [{ text: "Recibo", className: "receipt" }], lines: [] };
        }

        if (isMobileIntervalDay(day)) {
            const lines = [];
            const horaInicio = timeShort(day.fechaHoraInicio);
            const horaFin = timeShort(day.fechaHoraFin);

            if (horaInicio && horaFin) {
                lines.push(horaInicio + " - " + horaFin);
            }

            if (day.kmInicial != null && day.kmFinal != null) {
                const kmInicial = Number(day.kmInicial);
                const kmFinal = Number(day.kmFinal);
                const recorrido = day.km != null ? Number(day.km) : (kmFinal - kmInicial);
                lines.push("Km: " + kmInicial.toLocaleString("en-US") + " \u2192 " + kmFinal.toLocaleString("en-US"));
                lines.push(Number(recorrido).toLocaleString("en-US") + " km");
            } else if (day.kmInicial != null) {
                lines.push("Km inicio: " + Number(day.kmInicial).toLocaleString("en-US"));
            }

            const tarifa = Number($("#faTarifa").val() || 0);
            if (tarifa > 0) {
                lines.push(money(tarifa) + " estimado");
            }

            return {
                badges: [
                    { text: "Mobile", className: "mobile" },
                    { text: "Pendiente recibo", className: "pending" }
                ],
                lines: lines
            };
        }

        if (day.origen === "M") {
            return { badges: [{ text: "Manual", className: "manual" }], lines: [] };
        }

        return { badges: [], lines: [] };
    }

    function loadAll() {
        const id = Number($("#faContrato").val());
        if (!id) {
            return notify(false, "Selecciona un contrato.");
        }

        const p = monthParts();
        return WebApp.UI.withSpinner(() => $.when(
            $.getJSON("/Flota/ObtenerCalendario", { idContrato: id, anio: p.anio, mes: p.mes }),
            $.getJSON("/Flota/ListarRecibos", { idContrato: id, anio: p.anio, mes: p.mes })
        ), "Cargando calendario...").done((a, b) => {
            const rc = a[0];
            const rr = b[0];
            if (!rc.success) {
                notify(false, rc.message);
                return;
            }

            calendario = rc.data;
            recibos = rr.data || [];
            seleccion.clear();
            detalleActual = null;
            diaActual = null;
            render();
            $("#faWorkspace").removeClass("d-none");
        });
    }

    function reloadCurrentContext() {
        const idRecibo = detalleActual?.cabecera?.idReciboAlquiler || 0;
        return loadAll().then(() => {
            if (idRecibo > 0) {
                return reloadReceiptDetail(idRecibo);
            }
        });
    }

    function reloadReceiptDetail(idRecibo) {
        return $.getJSON("/Flota/ObtenerRecibo", { id: idRecibo }).done(r => {
            if (!r.success) {
                notify(false, r.message);
                return;
            }

            detalleActual = r.data;
            renderReceiptDetail(detalleActual);
        });
    }

    function render() {
        const c = selectedContract();
        const info = calendario.contrato || {};
        $("#faChofer").text(info.chofer || c.chofer);
        $("#faVehiculo").text((info.placa || c.placa) + " · " + c.modalidad);
        $("#faTarifa").val(info.tarifaDia || c.tarifaDia);

        const activos = recibos.filter(x => x.estadoCodigo !== "X");
        $("#faTotalRecibos").text(money(activos.reduce((a, x) => a + x.importeTotal, 0)));
        $("#faPagado").text(money(activos.reduce((a, x) => a + x.importePagado, 0)));
        $("#faSaldo").text(money(activos.reduce((a, x) => a + x.saldo, 0)));

        renderCalendar();
        renderReceipts();
        renderSelection();
        fillMethods();
        renderDayDetail(null);
    }

    function renderCalendar() {
        const p = monthParts();
        const first = new Date(p.anio, p.mes - 1, 1);
        const days = new Date(p.anio, p.mes, 0).getDate();
        const offset = (first.getDay() + 6) % 7;
        const map = new Map((calendario.dias || []).map(x => [String(x.fecha).substring(0, 10), x]));
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        $("#faTituloMes").text(first.toLocaleDateString("es-PE", { month: "long", year: "numeric" }));

        const box = $("#faCalendar").empty();
        for (let i = 0; i < offset; i++) {
            box.append('<span class="fa-day empty"></span>');
        }

        for (let n = 1; n <= days; n++) {
            const d = new Date(p.anio, p.mes - 1, n);
            const key = p.anio + "-" + String(p.mes).padStart(2, "0") + "-" + String(n).padStart(2, "0");
            const x = map.get(key);
            const locked = x?.tieneRecibo === "S" || d > today;
            const status = x ? (x.cobrable === "S" ? x.motivo : "No cobrable") : "Sin registro";
            const meta = buildDayMeta(x);
            const classes = ["fa-day"];
            if (locked) classes.push("locked");
            if (x?.tieneRecibo === "S") classes.push("has-receipt");
            if ((meta.badges || []).some(b => b.className === "mobile")) classes.push("has-mobile");
            if (seleccion.has(key)) classes.push("selected");
            if (diaActual?.fecha === key) classes.push("active");

            const html = '<button type="button" class="' + classes.join(" ") + '" data-date="' + key + '" data-locked="' + (locked ? '1' : '0') + '">' +
                '<span class="num">' + n + '</span>' +
                '<span class="tag-stack">' + (meta.badges || []).map(b => '<span class="tag tag-' + b.className + '">' + b.text + '</span>').join("") + '</span>' +
                '<span class="status">' + status + '</span>' +
                '<span class="amount">' + (x && Number(x.importe || 0) > 0 ? money(x.importe) : '') + '</span>' +
                (meta.lines || []).map(line => '<span class="meta-line">' + line + '</span>').join("") +
                '</button>';
            box.append(html);
        }
    }

    function renderReceipts() {
        const body = $("#faTabla tbody").empty();
        if (!recibos.length) {
            body.append('<tr><td colspan="9" class="text-center text-muted py-4">No hay recibos en este mes.</td></tr>');
            return;
        }

        recibos.forEach(x => {
            let actions = '<button class="fa-detail" data-id="' + x.idReciboAlquiler + '" title="Ver detalle"><i class="bi bi-eye"></i></button>';
            if (x.saldo > 0 && x.estadoCodigo !== "X") {
                actions += '<button class="fa-pay" data-id="' + x.idReciboAlquiler + '" title="Registrar pago"><i class="bi bi-cash-coin"></i></button>';
            }
            if (x.estadoCodigo !== "X") {
                actions += '<button class="fa-receipt-actions" data-id="' + x.idReciboAlquiler + '" title="Acciones"><i class="bi bi-three-dots-vertical"></i></button>';
            }

            body.append('<tr>' +
                '<td><strong>' + x.numero + '</strong></td>' +
                '<td>' + date(x.fechaInicio) + ' - ' + date(x.fechaFin) + '</td>' +
                '<td>' + x.cantidadDias + '</td>' +
                '<td class="text-end">' + money(x.importeTotal) + '</td>' +
                '<td class="text-end text-success">' + money(x.importePagado) + '</td>' +
                '<td class="text-end fw-bold">' + money(x.saldo) + '</td>' +
                '<td><span class="fa-badge ' + x.estadoCodigo + '">' + x.estado + '</span></td>' +
                '<td>' + (x.origen === "M" ? "Manual" : "Operativo") + '</td>' +
                '<td><div class="fa-row-actions">' + actions + '</div></td>' +
                '</tr>');
        });
    }

    function renderSelection() {
        const a = [...seleccion].sort();
        $("#faCount").text(a.length);
        $("#faRange").text(a.length ? date(a[0]) + (a.length > 1 ? " al " + date(a[a.length - 1]) : "") : "Ningun dia seleccionado");
    }

    function fillMethods() {
        const methods = calendario.mediosPago || [];
        const payMethod = $("#payMethod").empty().append('<option value="">Seleccione...</option>');
        const editMethod = $("#faEditPaymentMethod").empty().append('<option value="">Seleccione...</option>');
        methods.forEach(x => {
            const option = $("<option>").val(x.codigo).text(x.nombre);
            payMethod.append(option.clone());
            editMethod.append(option.clone());
        });
    }

    function renderDayDetail(day) {
        diaActual = day;
        const box = $("#faDayDetail");
        const button = $("#faOpenCorrectDay");

        if (!day) {
            box.html('<p class="text-muted mb-0">Selecciona un dia del calendario para ver su detalle.</p>');
            button.addClass("d-none");
            return;
        }

        const worked = day.trabajo === "S" || day.flgTrabajo === "S" ? "Si" : "No";
        const billable = day.cobrable === "S" || day.flgCobrable === "S" ? "Si" : "No";
        const receipt = day.tieneRecibo === "S" ? "Si" : "No";
        const motivoCodigo = day.codMotivo || "";
        const motivo = day.motivo || day.codMotivo || "-";
        const observacion = day.observacion || "Sin observacion.";

        box.html(
            '<div class="detail-grid">' +
            '<div><span>Fecha</span><strong>' + date(day.fecha) + '</strong></div>' +
            '<div><span>Trabajo</span><strong>' + worked + '</strong></div>' +
            '<div><span>Cobrable</span><strong>' + billable + '</strong></div>' +
            '<div><span>En recibo</span><strong>' + receipt + '</strong></div>' +
            '<div><span>Motivo</span><strong>' + motivo + (motivoCodigo && motivo !== motivoCodigo ? ' <small>(' + motivoCodigo + ')</small>' : '') + '</strong></div>' +
            '<div><span>Importe</span><strong>' + money(day.importe || 0) + '</strong></div>' +
            '<div><span>Km inicial</span><strong>' + (day.kmInicial ?? "-") + '</strong></div>' +
            '<div><span>Km final</span><strong>' + (day.kmFinal ?? "-") + '</strong></div>' +
            '<div><span>Inicio real</span><strong>' + dateTimeLocal(day.fechaHoraInicio) + '</strong></div>' +
            '<div><span>Fin real</span><strong>' + dateTimeLocal(day.fechaHoraFin) + '</strong></div>' +
            '</div>' +
            '<div class="mt-3"><span>Observacion</span><p class="mb-0">' + observacion + '</p></div>'
        );

        if (day.idOperacionDia > 0) {
            button.removeClass("d-none");
        } else {
            button.addClass("d-none");
        }
    }

    function renderReceiptDetail(d) {
        const c = d.cabecera;
        const dayRows = (d.dias || []).map(x => {
            const action = c.estadoCodigo !== "X"
                ? '<button class="btn btn-sm btn-outline-danger fa-remove-day" data-recibo="' + c.idReciboAlquiler + '" data-detalle="' + (x.idDetalle || 0) + '" data-fecha="' + String(x.fecha).substring(0, 10) + '">Quitar dia</button>'
                : '';
            return '<tr>' +
                '<td>' + date(x.fecha) + '</td>' +
                '<td>' + (x.origen === "M" ? "Manual" : "Operativo") + '</td>' +
                '<td>' + money(x.importe) + '</td>' +
                '<td class="text-end">' + action + '</td>' +
                '</tr>';
        }).join("");

        const payRows = (d.pagos || []).length
            ? d.pagos.map(x => {
                const actionButtons = x.flgEstado !== "X"
                    ? '<div class="fa-row-actions">' +
                        '<button class="btn btn-sm btn-outline-primary fa-edit-payment" data-id="' + x.idPago + '">Editar</button>' +
                        '<button class="btn btn-sm btn-outline-warning fa-validate-payment" data-id="' + x.idPago + '">Validar</button>' +
                        '<button class="btn btn-sm btn-outline-danger fa-cancel-payment" data-id="' + x.idPago + '">Anular</button>' +
                      '</div>'
                    : '<span class="text-muted">Anulado</span>';
                return '<tr>' +
                    '<td>' + date(x.fechaPago) + '</td>' +
                    '<td>' + x.medioPagoTexto + '</td>' +
                    '<td>' + money(x.importe) + '</td>' +
                    '<td>' + (x.validado === "S" ? "Si" : "No") + '</td>' +
                    '<td>' + actionButtons + '</td>' +
                    '</tr>';
            }).join("")
            : '<tr><td colspan="5">Sin pagos registrados.</td></tr>';

        const paymentSummary = c.estadoCodigo === "X"
            ? '<div class="fa-receipt-pay-banner is-blocked"><div><strong>Recibo anulado</strong><span>Recibo anulado: no se pueden registrar pagos.</span></div></div>'
            : c.saldo > 0
                ? '<div class="fa-receipt-pay-banner"><div><strong>Registrar pago al recibo</strong><span>Este pago se aplica directamente al recibo.</span></div><button type="button" id="faOpenPayReceipt" class="btn btn-sm btn-primary" data-id="' + c.idReciboAlquiler + '">Registrar pago al recibo</button></div>'
                : '<div class="fa-receipt-pay-banner is-muted"><div><strong>Recibo sin saldo pendiente</strong><span>Este recibo ya no requiere pagos adicionales.</span></div></div>';
        const receiptActions = c.estadoCodigo !== "X"
            ? '<button type="button" id="faOpenCancelReceipt" class="btn btn-outline-danger" data-id="' + c.idReciboAlquiler + '">Anular recibo</button>'
            : '<span class="text-muted">Recibo anulado</span>';

        $("#detailTitle").text(c.numero);
        $("#detailBody").html(
            '<div class="detail-grid">' +
            '<div><span>Contrato</span><strong>' + c.contrato + '</strong></div>' +
            '<div><span>Chofer</span><strong>' + c.chofer + '</strong></div>' +
            '<div><span>Total</span><strong>' + money(c.importeTotal) + '</strong></div>' +
            '<div><span>Saldo</span><strong>' + money(c.saldo) + '</strong></div>' +
            '</div>' +
            paymentSummary +
            '<div class="mt-3 mb-3">' + receiptActions + '</div>' +
            '<table class="detail-table"><thead><tr><th>Fecha</th><th>Origen</th><th>Importe</th><th class="text-end">Acciones</th></tr></thead><tbody>' + dayRows + '</tbody></table>' +
            '<table class="detail-table"><thead><tr><th>Pago</th><th>Medio</th><th>Importe</th><th>Validado</th><th>Acciones</th></tr></thead><tbody>' + payRows + '</tbody></table>'
        );
    }

    function selectedReceipt(id) {
        return recibos.find(x => x.idReciboAlquiler === Number(id));
    }

    function selectedPayment(idPago) {
        return (detalleActual?.pagos || []).find(x => x.idPago === Number(idPago));
    }

    function selectedDay(dateKey) {
        return (calendario?.dias || []).find(x => String(x.fecha).substring(0, 10) === dateKey) || null;
    }

    function submitCancelReceipt() {
        const payload = {
            idReciboAlquiler: Number($("#faCancelReceiptId").val()),
            motivo: $("#faCancelReceiptReason").val().trim()
        };

        return postAdmin("/Flota/AnularRecibo", payload)
            .done(r => {
                notify(r.success, r.message);
                if (isSuccessResponse(r)) {
                    closeModal("#faCancelReceiptModal");
                    reloadCurrentContext();
                }
            })
            .fail(x => notify(false, x.responseJSON?.message || "No se pudo anular el recibo."));
    }

    function submitRemoveReceiptDay() {
        const payload = {
            idReciboDetalle: Number($("#faRemoveDayOperacionId").val()),
            motivo: $("#faRemoveDayReason").val().trim()
        };

        return postAdmin("/Flota/QuitarDiaRecibo", payload)
            .done(r => {
                notify(r.success, r.message);
                if (isSuccessResponse(r)) {
                    closeModal("#faRemoveDayModal");
                    reloadCurrentContext();
                }
            })
            .fail(x => notify(false, x.responseJSON?.message || "No se pudo quitar el dia del recibo."));
    }

    function submitEditPayment() {
        const payload = {
            idPagoRecibo: Number($("#faEditPaymentId").val()),
            fechaPago: $("#faEditPaymentDate").val(),
            importe: Number($("#faEditPaymentAmount").val()),
            medioPago: $("#faEditPaymentMethod").val(),
            observacion: $("#faEditPaymentObservation").val(),
            fotoVoucher: $("#faEditPaymentVoucher").val(),
            motivo: $("#faEditPaymentReason").val().trim()
        };

        return postAdmin("/Flota/EditarPagoRecibo", payload)
            .done(r => {
                notify(r.success, r.message);
                if (isSuccessResponse(r)) {
                    closeModal("#faEditPaymentModal");
                    reloadCurrentContext();
                }
            })
            .fail(x => notify(false, x.responseJSON?.message || "No se pudo editar el pago."));
    }

    function submitCancelPayment() {
        const payload = {
            idPagoRecibo: Number($("#faCancelPaymentId").val()),
            motivo: $("#faCancelPaymentReason").val().trim()
        };

        return postAdmin("/Flota/AnularPagoRecibo", payload)
            .done(r => {
                notify(r.success, r.message);
                if (isSuccessResponse(r)) {
                    closeModal("#faCancelPaymentModal");
                    reloadCurrentContext();
                }
            })
            .fail(x => notify(false, x.responseJSON?.message || "No se pudo anular el pago."));
    }

    function submitValidatePayment() {
        const payload = {
            idPagoRecibo: Number($("#faValidatePaymentId").val()),
            flgValidado: $("#faValidatePaymentFlag").val(),
            motivo: $("#faValidatePaymentReason").val().trim()
        };

        return postAdmin("/Flota/ValidarPagoRecibo", payload)
            .done(r => {
                notify(r.success, r.message);
                if (isSuccessResponse(r)) {
                    closeModal("#faValidatePaymentModal");
                    reloadCurrentContext();
                }
            })
            .fail(x => notify(false, x.responseJSON?.message || "No se pudo actualizar la validacion del pago."));
    }

    function submitCorrectDay() {
        const payload = {
            idOperacionDia: Number($("#faCorrectDayId").val()),
            flgTrabajo: $("#faCorrectDayWorked").val(),
            codMotivo: ($("#faCorrectDayCode").val() || "").trim(),
            flgCobrable: $("#faCorrectDayBillable").val(),
            kmInicial: $("#faCorrectDayKmInicial").val() === "" ? null : Number($("#faCorrectDayKmInicial").val()),
            kmFinal: $("#faCorrectDayKmFinal").val() === "" ? null : Number($("#faCorrectDayKmFinal").val()),
            fechaHoraInicio: $("#faCorrectDayHoraInicio").val() || null,
            fechaHoraFin: $("#faCorrectDayHoraFin").val() || null,
            observacion: $("#faCorrectDayObservation").val(),
            motivo: $("#faCorrectDayReason").val().trim()
        };

        if (!payload.codMotivo) {
            notify(false, "Selecciona el motivo del dia.");
            return $.Deferred().reject().promise();
        }

        return postAdmin("/Flota/CorregirOperacionDia", payload)
            .done(r => {
                notify(r.success, r.message);
                if (isSuccessResponse(r)) {
                    closeModal("#faCorrectDayModal");
                    reloadCurrentContext();
                }
            })
            .fail(x => notify(false, x.responseJSON?.message || "No se pudo corregir la operacion del dia."));
    }

    $(document).on("click", ".fa-day", function () {
        const key = $(this).data("date");
        const locked = $(this).data("locked") === 1 || $(this).data("locked") === "1";
        const day = selectedDay(key);

        diaActual = day ? $.extend({}, day, { fecha: key }) : { fecha: key };
        renderDayDetail(diaActual);
        $(".fa-day").removeClass("active");
        $(this).addClass("active");

        if (!locked) {
            seleccion.has(key) ? seleccion.delete(key) : seleccion.add(key);
            $(this).toggleClass("selected");
            renderSelection();
        }
    });

    $(document).on("click", ".fa-pay", function () {
        const x = selectedReceipt($(this).data("id"));
        $("#payId").val(x.idReciboAlquiler);
        $("#payReceipt").text(x.numero);
        $("#payBalance").text(money(x.saldo));
        $("#payAmount").val(x.saldo).attr("max", x.saldo);
        openModal("#faPayModal");
    });

    $(document).on("click", "#faOpenPayReceipt", function () {
        const x = selectedReceipt($(this).data("id"));
        $("#payId").val(x.idReciboAlquiler);
        $("#payReceipt").text(x.numero);
        $("#payBalance").text(money(x.saldo));
        $("#payAmount").val(x.saldo).attr("max", x.saldo);
        openModal("#faPayModal");
    });

    $(document).on("click", ".fa-detail", function () {
        reloadReceiptDetail($(this).data("id")).done(() => openModal("#faDetailModal"));
    });

    $(document).on("click", ".fa-receipt-actions", function () {
        const x = selectedReceipt($(this).data("id"));
        Swal.fire({
            title: x.numero,
            text: "Selecciona la accion administrativa.",
            showDenyButton: true,
            showCancelButton: true,
            confirmButtonText: "Ver detalle",
            denyButtonText: "Anular recibo",
            cancelButtonText: "Cerrar"
        }).then(r => {
            if (r.isConfirmed) {
                reloadReceiptDetail(x.idReciboAlquiler).done(() => openModal("#faDetailModal"));
            }
            if (r.isDenied) {
                $("#faCancelReceiptId").val(x.idReciboAlquiler);
                $("#faCancelReceiptReason").val("");
                openModal("#faCancelReceiptModal");
            }
        });
    });

    $(document).on("click", "#faOpenCancelReceipt", function () {
        $("#faCancelReceiptId").val($(this).data("id"));
        $("#faCancelReceiptReason").val("");
        openModal("#faCancelReceiptModal");
    });

    $(document).on("click", ".fa-remove-day", function () {
        $("#faRemoveDayReceiptId").val($(this).data("recibo"));
        $("#faRemoveDayOperacionId").val($(this).data("detalle"));
        $("#faRemoveDayReason").val("");
        $("#faRemoveDayText").text("Se retirara del recibo el dia " + date($(this).data("fecha")) + ".");
        openModal("#faRemoveDayModal");
    });

    $(document).on("click", ".fa-edit-payment", function () {
        const x = selectedPayment($(this).data("id"));
        $("#faEditPaymentId").val(x.idPago);
        $("#faEditPaymentDate").val(String(x.fechaPago || "").substring(0, 16));
        $("#faEditPaymentAmount").val(x.importe);
        $("#faEditPaymentMethod").val(x.medioPago || "");
        $("#faEditPaymentObservation").val(x.observacion || "");
        $("#faEditPaymentVoucher").val(x.fotoVoucher || "");
        $("#faEditPaymentReason").val("");
        openModal("#faEditPaymentModal");
    });

    $(document).on("click", ".fa-cancel-payment", function () {
        const x = selectedPayment($(this).data("id"));
        $("#faCancelPaymentId").val(x.idPago);
        $("#faCancelPaymentReason").val("");
        $("#faCancelPaymentText").text("Se anulara el pago de " + money(x.importe) + " registrado el " + date(x.fechaPago) + ".");
        openModal("#faCancelPaymentModal");
    });

    $(document).on("click", ".fa-validate-payment", function () {
        const x = selectedPayment($(this).data("id"));
        $("#faValidatePaymentId").val(x.idPago);
        $("#faValidatePaymentFlag").val(x.validado === "S" ? "N" : "S");
        $("#faValidatePaymentReason").val("");
        openModal("#faValidatePaymentModal");
    });

    $("#faOpenCorrectDay").on("click", function () {
        if (!diaActual || !diaActual.idOperacionDia) {
            notify(false, "Selecciona un dia valido para corregir.");
            return;
        }

        $("#faCorrectDayId").val(diaActual.idOperacionDia);
        $("#faCorrectDayWorked").val(diaActual.flgTrabajo || diaActual.trabajo || "S");
        $("#faCorrectDayBillable").val(diaActual.flgCobrable || diaActual.cobrable || "S");
        $("#faCorrectDayKmInicial").val(diaActual.kmInicial ?? "");
        $("#faCorrectDayKmFinal").val(diaActual.kmFinal ?? "");
        $("#faCorrectDayHoraInicio").val(dateTimeInput(diaActual.fechaHoraInicio));
        $("#faCorrectDayHoraFin").val(dateTimeInput(diaActual.fechaHoraFin));
        $("#faCorrectDayObservation").val(diaActual.observacion || "");
        $("#faCorrectDayReason").val("");

        const currentMotivo = diaActual.codMotivo || diaActual.motivo || "";
        setMotivoOptions("#faCorrectDayCode", currentMotivo);

        openModal("#faCorrectDayModal");
    });

    $("#faLimpiar").on("click", () => {
        seleccion.clear();
        renderCalendar();
        renderSelection();
    });

    $("#faCargar").on("click", loadAll);
    $("#faContrato,#faMes").on("change", function () {
        if ($("#faContrato").val()) {
            loadAll();
        }
    });

    $("#faGenerar").on("click", function () {
        const a = [...seleccion].sort();
        if (!a.length) {
            return notify(false, "Selecciona los dias del periodo.");
        }

        jsonPost("/Flota/GenerarRecibo", {
            idContrato: Number($("#faContrato").val()),
            fechaInicio: a[0],
            fechaFin: a[a.length - 1],
            observacion: $("#faObs").val()
        }).done(r => {
            notify(r.success, r.message);
            if (r.success) {
                loadAll();
            }
        });
    });

    $("#faManual").on("click", function () {
        const a = [...seleccion].sort();
        if (!a.length) {
            return notify(false, "Selecciona uno o varios dias anteriores.");
        }

        Swal.fire({
            icon: "question",
            title: "Generar carga historica",
            text: "Se registraran " + a.length + " dia(s) sin exigir kilometraje.",
            showCancelButton: true,
            confirmButtonText: "Si, generar",
            cancelButtonText: "Cancelar",
            confirmButtonColor: "#6941c6"
        }).then(q => {
            if (!q.isConfirmed) {
                return;
            }

            jsonPost("/Flota/GenerarReciboManual", {
                idContrato: Number($("#faContrato").val()),
                fechas: a,
                tarifaDia: Number($("#faTarifa").val()),
                modoAgrupacion: $("#faAgrupar").val(),
                observacion: $("#faObs").val()
            }).done(r => {
                notify(r.success, r.message);
                if (r.success) {
                    loadAll();
                }
            });
        });
    });

    $(".fa-close").on("click", function () {
        closeModal("#" + $(this).closest(".fa-modal").attr("id"));
    });

    $(".fa-modal").on("click", function (e) {
        if (e.target === this) {
            closeModal("#" + $(this).attr("id"));
        }
    });

    $("#payForm").on("submit", function (e) {
        e.preventDefault();
        const data = new FormData(this);
        if (!data.has("Validado")) {
            data.append("Validado", "false");
        }

        $.ajax({
            url: "/Flota/RegistrarPago",
            type: "POST",
            data: data,
            processData: false,
            contentType: false,
            headers: { RequestVerificationToken: token() }
        }).done(r => {
            notify(r.success, r.message);
            if (r.success) {
                closeModal("#faPayModal");
                this.reset();
                loadAll();
            }
        }).fail(x => notify(false, x.responseJSON?.message || "No se pudo registrar el pago."));
    });

    $("#faCancelReceiptForm").on("submit", function (e) {
        e.preventDefault();
        submitCancelReceipt();
    });

    $("#faRemoveDayForm").on("submit", function (e) {
        e.preventDefault();
        submitRemoveReceiptDay();
    });

    $("#faEditPaymentForm").on("submit", function (e) {
        e.preventDefault();
        submitEditPayment();
    });

    $("#faCancelPaymentForm").on("submit", function (e) {
        e.preventDefault();
        submitCancelPayment();
    });

    $("#faValidatePaymentForm").on("submit", function (e) {
        e.preventDefault();
        submitValidatePayment();
    });

    $("#faCorrectDayForm").on("submit", function (e) {
        e.preventDefault();
        submitCorrectDay();
    });

    $(function () {
        $.when(loadContracts(), loadCatalogs());
    });
})();


