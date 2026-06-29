(function () {
    let dtPrestamos = null;
    let dtDetalle = null;
    let dtContinuaciones = null;
    let ultimaSimulacion = null;
    let continuacionesRegistradas = [];

    function unwrap(r) {
        return {
            ok: r && (r.success || r.Success),
            mensaje: (r && (r.mensaje || r.Mensaje || r.message || r.Message)) || "",
            data: (r && (r.data || r.Data)) || null,
            errors: (r && (r.errors || r.Errors)) || []
        };
    }

    function money(v) {
        const n = Number(v || 0);
        return "S/." + n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    function fecha(v) {
        if (!v) return "";
        const d = new Date(v);
        if (isNaN(d)) return v;
        return String(d.getDate()).padStart(2, "0") + "/" + String(d.getMonth() + 1).padStart(2, "0") + "/" + d.getFullYear();
    }

    function fechaInput(v) {
        if (!v) return "";
        const d = new Date(v);
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    }

    function frecuencia(v) { return v === "D" ? "Diaria" : v === "S" ? "Semanal" : "Mensual"; }
    function enEdicion() { return Number($("#IdContinuacion").val() || 0) > 0; }

    function token() {
        return $("#frmContinuacion input[name='__RequestVerificationToken']").val();
    }

    function limpiarSimulacion() {
        ultimaSimulacion = null;
        $("#pcFechaDesde").text("-");
        $("#pcFechaHasta").text("-");
        $("#pcNroCuotas").text("0");
        $("#pcInteresTotal").text(money(0));
        $("#pcCapitalBase").text(money(0));
        $("#pcMensaje").text("Simula para ver las cuotas de continuidad.");
        $("#btnAplicarContinuacion").prop("disabled", true);
        if (dtDetalle) dtDetalle.clear().draw();
    }

    function mostrarSeleccion($btn) {
        const id = $btn.data("id");
        const capital = $btn.data("capital");
        const fila = $btn.closest("tr");
        const cliente = fila.find("td").eq(1).text().trim() || "Cliente";

        $("#tblPrestamosContinuacion tbody tr").removeClass("pc-row-selected");
        fila.addClass("pc-row-selected");

        $("#pcSeleccionTitulo").text(`#${id} - ${cliente}`);
        $("#pcSeleccionMonto").text("Capital " + money(capital));
        $("#pcPrestamoSeleccionado").removeClass("d-none").addClass("pc-selected-box--active");

        const ultima = continuacionesRegistradas
            .filter(x => Number(x.idPrestamo) === Number(id) && x.estado === "A")
            .sort((a, b) => Number(b.idContinuacion) - Number(a.idContinuacion))[0];
        if (ultima) {
            $("#btnPdfUltimaContinuacion")
                .attr("href", `/Prestamo/ExportarContinuacionPdf?idContinuacion=${ultima.idContinuacion}`)
                .removeClass("d-none");
            $("#btnEditarUltimaContinuacion")
                .data("id", ultima.idContinuacion)
                .toggleClass("d-none", !ultima.puedeEditar);
        } else {
            $("#btnPdfUltimaContinuacion,#btnEditarUltimaContinuacion").addClass("d-none");
        }

        setTimeout(function () {
            $("#pcPrestamoSeleccionado").removeClass("pc-selected-box--active");
        }, 900);

        const $form = $("#frmContinuacion");
        if ($form.length) {
            $("html, body").animate({ scrollTop: Math.max(0, $form.offset().top - 88) }, 350, function () {
                $("#btnSimularContinuacion").trigger("focus");
            });
        }

        WebApp.Forms.showToast(true, ultima
            ? `Prestamo #${id} seleccionado. Ya tiene continuacion: puedes abrir su PDF o crear una nueva.`
            : `Prestamo #${id} seleccionado. Revisa la fecha y pulsa Simular.`);
    }

    function initTablas() {
        dtPrestamos = $("#tblPrestamosContinuacion").DataTable({
            paging: true,
            searching: true,
            ordering: true,
            pageLength: 10,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "id_Prestamo", className: "text-center" },
                { data: "cliente" },
                { data: "capital", render: money, className: "text-end" },
                { data: "nro_Cuotas", className: "text-center" },
                { data: "total_Programado", render: money, className: "text-end" },
                { data: "total_Pagado", render: money, className: "text-end" },
                { data: "saldo_Pendiente", render: money, className: "text-end fw-bold" },
                { data: "estado_Descripcion" },
                {
                    data: null,
                    orderable: false,
                    searchable: false,
                    className: "text-center",
                    render: function (data, type, row) {
                        return `<button type="button" class="pc-row-btn js-seleccionar-cont" data-id="${row.id_Prestamo}" data-capital="${row.capital}">Usar</button>`;
                    }
                }
            ]
        });

        dtDetalle = $("#tblContinuacionDetalle").DataTable({
            paging: true,
            searching: false,
            ordering: true,
            pageLength: 12,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "num_Secuencia", className: "text-center" },
                { data: "fecha_Desde", render: fecha },
                { data: "fecha_Hasta", render: fecha },
                { data: "fec_Venc", render: fecha },
                { data: "imp_Base", render: money, className: "text-end" },
                { data: "imp_Interes", render: money, className: "text-end fw-bold text-warning" },
                { data: "imp_Cuota", render: money, className: "text-end fw-bold" }
            ]
        });

        dtContinuaciones = $("#tblContinuaciones").DataTable({
            paging: true, searching: true, ordering: true, order: [[0, "desc"]], pageLength: 6, autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "idContinuacion", render: v => `<strong>#${v}</strong>` },
                { data: "idPrestamo", render: v => `#${v}` }, { data: "cliente" },
                { data: null, render: r => `${fecha(r.fechaDesde)} - ${fecha(r.fechaHasta)}` },
                { data: "frecuenciaPago", render: frecuencia }, { data: "capitalBase", render: money, className: "text-end" },
                { data: "importeInteresTotal", render: money, className: "text-end fw-bold text-warning" },
                { data: "nroCuotasGeneradas", className: "text-center" },
                { data: null, orderable: false, searchable: false, className: "text-center", render: function (_, __, r) {
                    const edit = r.puedeEditar
                        ? `<button type="button" class="pc-icon-btn edit js-editar-cont" data-id="${r.idContinuacion}" title="Editar continuacion"><i class="bi bi-pencil"></i></button>`
                        : `<button type="button" class="pc-icon-btn" disabled title="${r.motivoBloqueo || 'No editable'}"><i class="bi bi-lock"></i></button>`;
                    return `<div class="pc-action-group">${edit}<a class="pc-icon-btn pdf" href="/Prestamo/ExportarContinuacionPdf?idContinuacion=${r.idContinuacion}" target="_blank" title="Abrir PDF"><i class="bi bi-file-earmark-pdf"></i></a></div>${r.puedeEditar ? "" : `<div class="pc-lock">${r.motivoBloqueo || "Bloqueada"}</div>`}`;
                }}
            ]
        });
    }

    function cargarContinuaciones() {
        return $.getJSON("/Prestamo/ListarContinuaciones").done(function (r) {
            const u = unwrap(r); if (!u.ok) return WebApp.Forms.showToast(false, u.mensaje);
            continuacionesRegistradas = u.data || [];
            dtContinuaciones.clear().rows.add(continuacionesRegistradas).draw();
        }).fail(() => WebApp.Forms.showToast(false, "No se pudieron cargar las continuaciones registradas."));
    }

    function cargarPrestamos() {
        return WebApp.UI.withSpinner(() => $.getJSON("/Prestamo/Listar"), "Cargando prestamos...")
            .done(function (r) {
                const u = unwrap(r);
                if (!u.ok) {
                    dtPrestamos.clear().draw();
                    WebApp.Forms.showToast(false, u.mensaje || "No se pudieron cargar prestamos.");
                    return;
                }

                const rows = (u.data || []).filter(x => Number(x.saldo_Pendiente ?? x.Saldo_Pendiente ?? 0) > 0);
                dtPrestamos.clear().rows.add(rows).draw();
            })
            .fail(function () {
                dtPrestamos.clear().draw();
                WebApp.Forms.showToast(false, "Error al cargar prestamos.");
            });
    }

    function dataBase() {
        return {
            __RequestVerificationToken: token(),
            Id_Prestamo: $("#Id_Prestamo").val(),
            FechaHasta: $("#FechaHasta").val(),
            PorcInteresMensual: $("#PorcInteresMensual").val(),
            FrecuenciaPago: $("#FrecuenciaPago").val(),
            CapitalBase: $("#CapitalBase").val(),
            Observacion: $("#Observacion").val()
            ,IdContinuacion: $("#IdContinuacion").val()
        };
    }

    function simular() {
        WebApp.Forms.clearErrors($("#frmContinuacion"));
        $("#btnAplicarContinuacion").prop("disabled", true);

        return WebApp.UI.withSpinner(() => $.ajax({
            url: enEdicion() ? "/Prestamo/SimularEdicionContinuacion" : "/Prestamo/SimularContinuacion",
            type: "POST",
            data: dataBase()
        }), "Simulando continuidad...")
            .done(function (r) {
                const u = unwrap(r);
                if (!u.ok) {
                    limpiarSimulacion();
                    WebApp.Forms.mapErrors($("#frmContinuacion"), u.errors);
                    WebApp.Forms.showToast(false, u.mensaje || "No se pudo simular.");
                    return;
                }

                ultimaSimulacion = u.data || {};
                const resumen = ultimaSimulacion.resumen || ultimaSimulacion.Resumen || {};
                const detalle = ultimaSimulacion.detalle || ultimaSimulacion.Detalle || [];

                $("#pcFechaDesde").text(fecha(resumen.fechaDesde || resumen.FechaDesde));
                $("#pcFechaHasta").text(fecha(resumen.fechaHasta || resumen.FechaHasta));
                $("#pcNroCuotas").text(resumen.nroCuotas || resumen.NroCuotas || 0);
                $("#pcInteresTotal").text(money(resumen.interesTotal || resumen.InteresTotal || 0));
                $("#pcCapitalBase").text(money(resumen.capitalBase || resumen.CapitalBase || 0));
                $("#pcMensaje").text(resumen.mensaje || resumen.Mensaje || "Simulacion generada.");

                dtDetalle.clear().rows.add(detalle).draw();
                $("#btnAplicarContinuacion").prop("disabled", detalle.length === 0);
            })
            .fail(function () {
                limpiarSimulacion();
                WebApp.Forms.showToast(false, "Error al simular continuidad.");
            });
    }

    async function aplicar() {
        if (!ultimaSimulacion) {
            WebApp.Forms.showToast(false, "Primero simula la continuidad.");
            return;
        }

        const resumen = ultimaSimulacion.resumen || ultimaSimulacion.Resumen || {};
        const ok = await WebApp.UI.confirm({
            title: enEdicion() ? "Guardar correccion" : "Aplicar continuidad",
            message: `Se ${enEdicion() ? "reemplazaran" : "generaran"} ${resumen.nroCuotas || resumen.NroCuotas || 0} cuota(s) por ${money(resumen.interesTotal || resumen.InteresTotal || 0)} de interes. Esta operacion modifica el cronograma.`,
            okText: enEdicion() ? "Guardar cambios" : "Aplicar",
            cancelText: "Revisar"
        });

        if (!ok) return;

        return WebApp.UI.withSpinner(() => $.ajax({
            url: enEdicion() ? "/Prestamo/GuardarEdicionContinuacion" : "/Prestamo/AplicarContinuacion",
            type: "POST",
            data: dataBase()
        }), "Aplicando continuidad...")
            .done(function (r) {
                const u = unwrap(r);
                WebApp.Forms.showToast(u.ok, u.mensaje || (u.ok ? "Continuidad registrada." : "No se pudo registrar."));
                if (u.ok) {
                    cargarPrestamos();
                    cargarContinuaciones();
                    if (enEdicion()) salirEdicion(); else simular();
                }
            })
            .fail(function () {
                WebApp.Forms.showToast(false, "Error al aplicar continuidad.");
            });
    }

    $(document).on("click", ".js-seleccionar-cont", function () {
        const $btn = $(this);
        if (enEdicion()) salirEdicion();
        $("#Id_Prestamo").val($btn.data("id"));
        $("#CapitalBase").attr("placeholder", money($btn.data("capital")) + " actual");
        limpiarSimulacion();
        mostrarSeleccion($btn);
    });

    function editarContinuacion(id) {
        return WebApp.UI.withSpinner(() => $.getJSON("/Prestamo/ObtenerContinuacion", { idContinuacion: id }), "Cargando continuacion...")
            .done(function (r) {
                const u = unwrap(r); if (!u.ok) return WebApp.Forms.showToast(false, u.mensaje);
                const d = u.data;
                if (!d.puedeEditar) return WebApp.Forms.showToast(false, d.motivoBloqueo || "Esta continuacion no puede editarse.");
                $("#IdContinuacion").val(d.idContinuacion); $("#Id_Prestamo").val(d.idPrestamo).prop("readonly", true);
                $("#FechaHasta").val(fechaInput(d.fechaHasta)); $("#PorcInteresMensual").val(d.porcInteresMensual);
                $("#FrecuenciaPago").val(d.frecuenciaPago); $("#CapitalBase").val(d.capitalBase); $("#Observacion").val(d.observacion);
                $("#pcEdicionId").text("#" + d.idContinuacion); $("#pcModoEdicion").removeClass("d-none");
                $("#btnAplicarContinuacion span").text("Guardar"); limpiarSimulacion();
                $("html, body").animate({ scrollTop: $("#frmContinuacion").offset().top - 85 }, 350, () => $("#btnSimularContinuacion").trigger("focus"));
                WebApp.Forms.showToast(true, "Datos cargados. Ajusta, simula y guarda la correccion.");
            });
    }

    function salirEdicion() {
        $("#IdContinuacion").val(0); $("#Id_Prestamo").val("").prop("readonly", false); $("#PorcInteresMensual,#CapitalBase").val("");
        $("#FrecuenciaPago").val(""); $("#Observacion").val("CONTINUIDAD DE PRESTAMO VENCIDO");
        $("#pcModoEdicion,#pcPrestamoSeleccionado").addClass("d-none"); $("#btnAplicarContinuacion span").text("Aplicar"); limpiarSimulacion();
    }

    $(document).on("click", ".js-editar-cont", function () { editarContinuacion($(this).data("id")); });
    $("#btnEditarUltimaContinuacion").on("click", function () { editarContinuacion($(this).data("id")); });
    $("#btnCancelarEdicion,#btnNuevaContinuacion").on("click", salirEdicion);

    $("#btnCargarPrestamosContinuacion").on("click", cargarPrestamos);
    $("#btnSimularContinuacion").on("click", simular);
    $("#btnAplicarContinuacion").on("click", aplicar);
    $("#frmContinuacion input,#frmContinuacion select").on("change input", function () {
        $("#btnAplicarContinuacion").prop("disabled", true);
    });

    $(function () {
        initTablas();
        limpiarSimulacion();
        cargarPrestamos();
        cargarContinuaciones();
    });
})();
