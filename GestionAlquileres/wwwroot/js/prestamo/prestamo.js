(function () {
    const $mdlPrestamo = $("#mdlPrestamo");
    const $frmPrestamo = $("#frmPrestamo");
    const $btnGuardarPrestamo = $("#btnGuardarPrestamo");
    const $btnSimularPrestamo = $("#btnSimularPrestamo");
    const $msg = $("#frmPrestamoMsg");
    const $cliente = $("#Cod_Anxo");

    const $mdlPagosPrestamo = $("#mdlPagosPrestamo");
    const $mdlGenerarPago = $("#mdlGenerarPago");
    const $frmGenerarPago = $("#frmGenerarPago");
    const $msgPago = $("#frmGenerarPagoMsg");
    const $btnGuardarPagoPrestamo = $("#btnGuardarPagoPrestamo");

    const $mdlDesembolsoPrestamo = $("#mdlDesembolsoPrestamo");
    const $mdlRegistrarDesembolso = $("#mdlRegistrarDesembolso");
    const $frmRegistrarDesembolso = $("#frmRegistrarDesembolso");
    const $msgDesembolso = $("#frmRegistrarDesembolsoMsg");
    const $btnGuardarDesembolso = $("#btnGuardarDesembolso");



    let dtPrestamos = null;
    let dtPagosPrestamo = null;
    let dtDesembolsosPrestamo = null;
    let simulacionOk = false;

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

    function limpiarSimulacion() {
        simulacionOk = false;
        $("#simNroCuotas").text("0");
        $("#simInteresMensual").text("S/ 0.00");
        $("#simInteresDiario").text("S/ 0.00");
        $("#simInteresTotal").text("S/ 0.00");
        $("#simTotalCobrar").text("S/ 0.00");
        $("#simImporteCuota").text("S/ 0.00");
        $("#simTeaReferencial").text("0.0000 %");
        $("#simCuotaInteres").text("S/ 0.00");
        $("#simUltimaCuota").text("S/ 0.00");
        $("#numCuotasComp").text("0");
    }

    function pintarSimulacion(d) {
        simulacionOk = !!d;
        $("#simNroCuotas").text(d?.nroCuotas ?? d?.NroCuotas ?? 0);
        $("#simInteresMensual").text(money(d?.interesMensual ?? d?.InteresMensual));
        $("#simInteresDiario").text(money(d?.interesDiario ?? d?.InteresDiario));
        $("#simInteresTotal").text(money(d?.interesTotal ?? d?.InteresTotal));
        $("#simTotalCobrar").text(money(d?.totalCobrar ?? d?.TotalCobrar));
        $("#simImporteCuota").text(money(d?.importeCuota ?? d?.ImporteCuota));
        $("#simCuotaInteres").text(money(d?.importeCuotaInteres ?? d?.ImporteCuotaInteres));
        $("#simUltimaCuota").text(money(d?.importeUltimaCuota ?? d?.ImporteUltimaCuota));
        $("#numCuotasComp").text(d?.nroCuotasCompletas ?? d?.NroCuotasCompletas ?? 0);
        

        const tea = parseFloat(d?.teaReferencial ?? d?.TeaReferencial ?? 0);
        $("#simTeaReferencial").text(tea.toFixed(4) + " %");
    }

    function limpiarFormulario() {
        if ($frmPrestamo.length > 0) $frmPrestamo[0].reset();

        $("#Cod_TipAnex").val("C");
        $("#Fecha").val(new Date().toISOString().substring(0, 10));
        $("#FechaInicioCobro").val(new Date().toISOString().substring(0, 10));
        $("#FechaFinCobro").val(new Date().toISOString().substring(0, 10));
        $("#Cod_Almacen").val("1");
        $("#TipoInteres").val("M");
        $("#FrecuenciaPago").val("M");
        $("#PorcInteresMensual").val("0");

        if ($cliente.hasClass("select2-hidden-accessible")) {
            $cliente.val(null).trigger("change");
        }
        /*Nuevos Campos */
        $("#TipoModalidad").val("C");
        $("#TieneGarantia").prop("checked", false);
        $("#panelGarantia").addClass("d-none");

        $("#TipoGarantia").val("");
        $("#MarcaGarantia").val("");
        $("#ModeloGarantia").val("");
        $("#SerieGarantia").val("");
        $("#EstadoGarantia").val("");
        $("#ValorGarantia").val("");
        $("#DescripcionGarantia").val("");

        WebApp.Forms.hideMsg($msg);
        WebApp.Forms.clearErrors($frmPrestamo);
        limpiarSimulacion();
    }

    function initClienteSelect() {
        if (!$.fn || typeof $.fn.select2 !== "function") {
            console.error("Select2 no está cargado.");
            WebApp.Forms.showToast(false, "No se pudo cargar el buscador de clientes. Recarga la página.");
            return;
        }

        if ($cliente.hasClass("select2-hidden-accessible")) {
            $cliente.select2("destroy");
        }

        $cliente.select2({
            width: "100%",
            dropdownParent: $mdlPrestamo,
            placeholder: "Buscar cliente por nombre o documento...",
            allowClear: true,
            minimumInputLength: 2,
            ajax: {
                url: "/Prestamo/BuscarClientes",
                dataType: "json",
                delay: 250,
                data: function (params) {
                    return { texto: params.term || "" };
                },
                processResults: function (response) {
                    const rows = response.data || response.Data || [];

                    return {
                        results: rows.map(x => ({
                            id: x.cod_Anxo ?? x.Cod_Anxo,
                            text: x.textoMostrar ?? x.TextoMostrar,
                            codTipAnex: x.cod_TipAnex ?? x.Cod_TipAnex,
                            codAnxo: x.cod_Anxo ?? x.Cod_Anxo
                        }))
                    };
                }
            }
        });

        $cliente.off("select2:select").on("select2:select", function (e) {
            const item = e.params.data;
            $("#Cod_TipAnex").val(item.codTipAnex || "C");
        });

        $cliente.off("select2:clear").on("select2:clear", function () {
            $("#Cod_TipAnex").val("C");
        });
    }

        
    function initDataTable() {
        dtPrestamos = $("#tblPrestamos").DataTable({
            paging: true,
            searching: true,
            ordering: true,
            pageLength: 10,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "id_Prestamo" },
                { data: "cliente" },
                { data: "documento" },
                { data: "fecha", render: fecha },
                { data: "capital", render: money, className: "text-end" },
                { data: "nro_Cuotas", className: "text-center" },
                { data: "total_Programado", render: money, className: "text-end" },
                { data: "total_Pagado", render: money, className: "text-end" },
                { data: "saldo_Pendiente", render: money, className: "text-end" },
                { data: "estado", className: "text-center" },
                {
                    data: null,
                    orderable: false,
                    searchable: false,
                    className: "text-center",
                    render: function (data, type, row) {
                        const flgDes = (row.flg_Desembolsado || row.Flg_Desembolsado || "N");
                        const totalDes = parseFloat(row.imp_Desembolsado || row.Imp_Desembolsado || 0);

                        let btnDesembolsar = "";
                        if (flgDes === "N" || flgDes === "P") {
                            btnDesembolsar = `
                            <button type="button"
                                    class="btn btn-sm btn-outline-success js-ver-desembolso"
                                    data-idprestamo="${row.id_Prestamo || ''}"
                                    data-nrocobranza="${row.nroCobranza || row.NroCobranza || ''}"
                                    data-cliente="${row.cliente || ''}"
                                    data-documento="${row.documento || ''}"
                                    data-capital="${row.capital || 0}"
                                    data-desembolsado="${totalDes}">
                                Desembolsar
                            </button>`;
                        }

                        return `
                        <div class="d-flex gap-1 justify-content-center">
                            <button type="button"
                                    class="btn btn-sm btn-outline-primary js-ver-pagos"
                                    data-idprestamo="${row.id_Prestamo || ''}"
                                    data-nrocobranza="${row.nroCobranza || row.NroCobranza || ''}"
                                    data-cliente="${row.cliente || ''}"
                                    data-documento="${row.documento || ''}"
                                    data-deudatotal="${row.total_Programado || 0}"
                                    data-pagadototal="${row.total_Pagado || 0}"
                                    data-saldopendiente="${row.saldo_Pendiente || 0}">
                                Pagos
                            </button>
                            ${btnDesembolsar}
                        </div>`;
                    }
                }
            ]
        });

        dtPagosPrestamo = $("#tblPagosPrestamo").DataTable({
            paging: true,
            searching: false,
            ordering: true,
            pageLength: 5,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "numCuota", className: "text-center" },
                { data: "fecPago", render: fecha },
                { data: "formaPago" },
                { data: "cajaBanco" },
                { data: "importe", render: money, className: "text-end" },
                { data: "deuda", render: money, className: "text-end" },
                { data: "saldo", render: money, className: "text-end" },
                { data: "glosa" }
            ]
        });

        dtDesembolsosPrestamo = $("#tblDesembolsosPrestamo").DataTable({
            paging: true,
            searching: false,
            ordering: true,
            pageLength: 5,
            autoWidth: false,
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "secuencia", className: "text-center" },
                { data: "fecDesembolso", render: fecha },
                { data: "desCajaChica" },
                { data: "importe", render: money, className: "text-end" },
                { data: "documento" },
                { data: "glosa" },
                { data: "secMovimiento", className: "text-center" }
            ]
        });
    }


    function actualizarResumen(rows) {
        const totalPrestamos = rows.length;
        const capitalAcumulado = rows.reduce((a, b) => a + parseFloat(b.capital || b.Capital || 0), 0);
        const cuotasAcumuladas = rows.reduce((a, b) => a + parseInt(b.nro_Cuotas || b.Nro_Cuotas || 0), 0);

        $("#lblTotalPrestamos").text(totalPrestamos);
        $("#lblCapitalAcumulado").text(money(capitalAcumulado));
        $("#lblCuotasAcumuladas").text(cuotasAcumuladas);
    }

    function listarPrestamos() {
        return WebApp.UI.withSpinner(() => $.getJSON("/Prestamo/Listar"), "Cargando préstamos...")
            .done(function (r) {
                const rows = (r.data || r.Data) || [];
                dtPrestamos.clear().rows.add(rows).draw();
                actualizarResumen(rows);
            })
            .fail(function () {
                dtPrestamos.clear().draw();
                actualizarResumen([]);
                WebApp.Forms.showToast(false, "Error al listar préstamos.");
            });
    }

    function cargarCajasPorFormaPago(formaPago) {
        let esBanco = formaPago === "BANCARIO" ? "S" : "N";

        $.getJSON("/Caja/ListarPorTipo", { esBanco })
            .done(function (r) {
                let html = "";
                (r.data || []).forEach(x => {
                    html += `<option value="${x.cod_CajaChica}">${x.des_CajaChica}</option>`;
                });
                $("#CodCajaChica").html(html);
            });
    }

    function cargarFormaPago() {
        $.getJSON("/FormaPago/Listar")
            .done(function (r) {
                let html = "";
                (r.data || []).forEach(x => {
                    html += `<option value="${x.idFormaPago}">${x.descripcion}</option>`;
                });
                $("#FormaPago").html(html);
            });
    }



    //function abrirModalGenerarPago() {
    //    WebApp.Forms.hideMsg($msgPago);
    //    WebApp.Forms.clearErrors($frmGenerarPago);

    //    $("#FecPago").val(new Date().toISOString().substring(0, 10));
    //    $("#FormaPago").val("EFECTIVO");
    //    $("#CodCajaChica").html("");
    //    $("#ImportePago").val($("#lblPagoSaldoPendiente").text().replace("S/", "").trim());
    //    $("#GlosaPago").val("");
    //    $("#PermitirExcedente").prop("checked", false);

    //    $mdlGenerarPago.modal("show");
    //    cargarCajasPorFormaPago("EFECTIVO");
    //}





    function abrirModalPagos(data) {
        $("#hidPagoIdPrestamo").val(data.idPrestamo || "");
        $("#hidPagoNroCobranza").val(data.nroCobranza || "");
        $("#txtPagoIdPrestamo").text(data.idPrestamo || "");
        $("#txtPagoNroCobranza").text(data.nroCobranza || "");
        $("#txtPagoCliente").text(data.cliente || "");
        $("#txtPagoDocumento").text(data.documento || "");
        $("#lblPagoDeudaTotal").text(money(data.deudaTotal || 0));
        $("#lblPagoPagadoTotal").text(money(data.pagadoTotal || 0));
        $("#lblPagoSaldoPendiente").text(money(data.saldoPendiente || 0));

        dtPagosPrestamo.clear().draw();
        $mdlPagosPrestamo.modal("show");

        // luego conectaremos backend real
        // cargarHistorialPagos(data.nroCobranza);
        // cargarResumenPagos(data.nroCobranza);
    }

    function abrirModalDesembolso(data) {
    $("#hidDesIdPrestamo").val(data.idPrestamo || "");
    $("#hidDesNroCobranza").val(data.nroCobranza || "");
    $("#txtDesIdPrestamo").text(data.idPrestamo || "");
    $("#txtDesNroCobranza").text(data.nroCobranza || "");
    $("#txtDesCliente").text(data.cliente || "");
    $("#txtDesDocumento").text(data.documento || "");
    $("#lblDesCapital").text(money(data.capital || 0));
    $("#lblDesTotalDesembolsado").text(money(data.desembolsado || 0));
    $("#lblDesSaldoPendiente").text(money((parseFloat(data.capital || 0) - parseFloat(data.desembolsado || 0)) || 0));

    dtDesembolsosPrestamo.clear().draw();
    $mdlDesembolsoPrestamo.modal("show");

    // luego backend real
    // cargarHistorialDesembolsos(data.idPrestamo);
    // cargarResumenDesembolso(data.idPrestamo);
}
    /* Nuevos*/
    function abrirModalDesembolso(data) {
        $("#hidDesIdPrestamo").val(data.idPrestamo || "");
        $("#hidDesNroCobranza").val(data.nroCobranza || "");
        $("#txtDesIdPrestamo").text(data.idPrestamo || "");
        $("#txtDesNroCobranza").text(data.nroCobranza || "");
        $("#txtDesCliente").text(data.cliente || "");
        $("#txtDesDocumento").text(data.documento || "");
        $("#lblDesCapital").text(money(data.capital || 0));
        $("#lblDesTotalDesembolsado").text(money(data.desembolsado || 0));
        $("#lblDesSaldoPendiente").text(money((parseFloat(data.capital || 0) - parseFloat(data.desembolsado || 0)) || 0));

        dtDesembolsosPrestamo.clear().draw();
        $mdlDesembolsoPrestamo.modal("show");

        // luego backend real
        // cargarHistorialDesembolsos(data.idPrestamo);
        // cargarResumenDesembolso(data.idPrestamo);
    }

    function abrirModalRegistrarDesembolso() {
        WebApp.Forms.hideMsg($msgDesembolso);
        WebApp.Forms.clearErrors($frmRegistrarDesembolso);

        $("#FecDesembolso").val(new Date().toISOString().substring(0, 10));
        $("#ImpDesembolso").val($("#lblDesSaldoPendiente").text().replace("S/", "").trim());
        $("#GlosaDesembolso").val("");
        $("#CodTipDocDesembolso").val("20");
        $("#SerDocDesembolso").val("");
        $("#NumDocDesembolso").val("");

        $("#CodCajaChicaDesembolso").html("");
        cargarCajasDesembolso();

        $mdlRegistrarDesembolso.modal("show");
    }

    function cargarCajasDesembolso() {
        $.getJSON("/Caja/ListarPorTipo", { esBanco: "" })
            .done(function (r) {
                let html = "";
                (r.data || r.Data || []).forEach(x => {
                    html += `<option value="${x.cod_CajaChica || x.Cod_CajaChica}">${x.des_CajaChica || x.Des_CajaChica}</option>`;
                });
                $("#CodCajaChicaDesembolso").html(html);
            })
            .fail(function () {
                WebApp.Forms.showToast(false, "No se pudo cargar las cajas de desembolso.");
            });
    }

    /* Fin Modal*/
function abrirModalRegistrarDesembolso() {
    WebApp.Forms.hideMsg($msgDesembolso);
    WebApp.Forms.clearErrors($frmRegistrarDesembolso);

    $("#FecDesembolso").val(new Date().toISOString().substring(0, 10));
    $("#ImpDesembolso").val($("#lblDesSaldoPendiente").text().replace("S/", "").trim());
    $("#GlosaDesembolso").val("");
    $("#CodTipDocDesembolso").val("20");
    $("#SerDocDesembolso").val("");
    $("#NumDocDesembolso").val("");

    $("#CodCajaChicaDesembolso").html("");
    cargarCajasDesembolso();

    $mdlRegistrarDesembolso.modal("show");
}

function cargarCajasDesembolso() {
    $.getJSON("/Caja/ListarPorTipo", { esBanco: "" })
        .done(function (r) {
            let html = "";
            (r.data || []).forEach(x => {
                html += `<option value="${x.cod_CajaChica}">${x.des_CajaChica}</option>`;
            });
            $("#CodCajaChicaDesembolso").html(html);
        })
        .fail(function () {
            WebApp.Forms.showToast(false, "No se pudo cargar cajas para desembolso.");
        });
    }

    /* Fin */

    function abrirModalGenerarPago() {
        WebApp.Forms.hideMsg($msgPago);
        WebApp.Forms.clearErrors($frmGenerarPago);

        $("#FecPago").val(new Date().toISOString().substring(0, 10));
        $("#FormaPago").val("EFECTIVO");
        $("#CodCajaChica").html("");
        $("#ImportePago").val($("#lblPagoSaldoPendiente").text().replace("S/", "").trim());
        $("#GlosaPago").val("");
        $("#PermitirExcedente").prop("checked", false);

        $mdlGenerarPago.modal("show");
        cargarCajasPorFormaPago("EFECTIVO");
    }




    function obtenerDataSimulacion() {
        return {
            Capital: $("#Capital").val(),
            TipoInteres: $("#TipoInteres").val(),
            PorcInteresMensual: $("#PorcInteresMensual").val(),
            FrecuenciaPago: $("#FrecuenciaPago").val(),
            FechaInicioCobro: $("#FechaInicioCobro").val(),
            FechaFinCobro: $("#FechaFinCobro").val(),
            TipoModalidad: $("#TipoModalidad").val()
        };
    }

    function simularPrestamo() {
        WebApp.Forms.hideMsg($msg);
        WebApp.Forms.clearErrors($frmPrestamo);
        limpiarSimulacion();

        return WebApp.UI.withSpinner(() => $.ajax({
            url: "/Prestamo/Simular",
            type: "POST",
            data: $.param(obtenerDataSimulacion()) + "&__RequestVerificationToken=" + $frmPrestamo.find("input[name='__RequestVerificationToken']").val()
        }), "Simulando préstamo...")
            .done(function (r) {
                if (r.success || r.Success) {
                    pintarSimulacion(r.data || r.Data);
                    return;
                }

                simulacionOk = false;
                const errores = r.errors || r.Errors || [];
                WebApp.Forms.mapErrors($frmPrestamo, errores);
                WebApp.Forms.showMsg($msg, false, r.message || r.Mensaje || "No se pudo simular.");
            })
            .fail(function () {
                simulacionOk = false;
                WebApp.Forms.showMsg($msg, false, "Error inesperado al simular el préstamo.");
            });
    }

    $("#btnNuevoPrestamo").on("click", function () {
        limpiarFormulario();
        $mdlPrestamo.modal("show");
    });

    $btnSimularPrestamo.on("click", function () {
        simularPrestamo();
    });

    function cargarAlmacenes() {
        return WebApp.UI.withSpinner(() => $.getJSON("/Prestamo/ListarAlmacenes"), "Cargando almacenes...")
            .done(function (r) {
                const rows = r.data || r.Data || [];
                let html = "";

                rows.forEach(x => {
                    const id = x.idAlmacen ?? x.IdAlmacen;
                    const nombre = x.nombreAlmacen ?? x.NombreAlmacen;
                    html += `<option value="${id}">${nombre}</option>`;
                });

                $("#Cod_Almacen").html(html);
            })
            .fail(function () {
                WebApp.Forms.showToast(false, "Error al cargar almacenes.");
            });
    }

    $btnGuardarPrestamo.on("click", function () {
        WebApp.Forms.hideMsg($msg);
        WebApp.Forms.clearErrors($frmPrestamo);

        if (!simulacionOk) {
            WebApp.Forms.showMsg($msg, false, "Primero debes simular el préstamo.");
            return;
        }

        $btnGuardarPrestamo.prop("disabled", true).text("Guardando...");

        WebApp.UI.withSpinner(() => $.ajax({
            url: "/Prestamo/Guardar",
            type: "POST",
            data: $frmPrestamo.serialize()
        }), "Guardando préstamo...")
            .done(function (r) {
                if (r.success || r.Success) {
                    WebApp.Forms.showToast(true, r.message || r.Mensaje || "Préstamo registrado correctamente.");
                    $mdlPrestamo.modal("hide");
                    listarPrestamos();
                    return;
                }

                const errores = r.errors || r.Errors || [];
                WebApp.Forms.mapErrors($frmPrestamo, errores);
                WebApp.Forms.showMsg($msg, false, r.message || r.Mensaje || "No se pudo guardar.");
            })
            .fail(function () {
                WebApp.Forms.showMsg($msg, false, "Error inesperado al guardar el préstamo.");
            })
            .always(function () {
                $btnGuardarPrestamo.prop("disabled", false).text("Guardar préstamo");
            });
    }); 

    $btnGuardarDesembolso.on("click", function () {
        WebApp.Forms.hideMsg($msgDesembolso);
        WebApp.Forms.clearErrors($frmRegistrarDesembolso);

        const idPrestamo = $("#hidDesIdPrestamo").val();

        const payload = {
            IdPrestamo: idPrestamo,
            CodCajaChicaDesembolso: $("#CodCajaChicaDesembolso").val(),
            FecDesembolso: $("#FecDesembolso").val(),
            ImpDesembolso: $("#ImpDesembolso").val(),
            CodTipDocDesembolso: $("#CodTipDocDesembolso").val(),
            SerDocDesembolso: $("#SerDocDesembolso").val(),
            NumDocDesembolso: $("#NumDocDesembolso").val(),
            GlosaDesembolso: $("#GlosaDesembolso").val(),
            __RequestVerificationToken: $frmRegistrarDesembolso.find("input[name='__RequestVerificationToken']").val()
        };

        $btnGuardarDesembolso.prop("disabled", true).text("Guardando...");

        WebApp.UI.withSpinner(() => $.ajax({
            url: "/Prestamo/RegistrarDesembolso",
            type: "POST",
            data: payload
        }), "Registrando desembolso...")
            .done(function (r) {
                if (r.success || r.Success || r.ok || r.Ok) {
                    WebApp.Forms.showToast(true, r.message || r.Mensaje || "Desembolso registrado correctamente.");
                    $mdlRegistrarDesembolso.modal("hide");
                    cargarHistorialDesembolsos(idPrestamo);
                    listarPrestamos();
                    return;
                }

                WebApp.Forms.showMsg($msgDesembolso, false, r.message || r.Mensaje || "No se pudo registrar el desembolso.");
            })
            .fail(function () {
                WebApp.Forms.showMsg($msgDesembolso, false, "Error inesperado al registrar desembolso.");
            })
            .always(function () {
                $btnGuardarDesembolso.prop("disabled", false).text("Guardar desembolso");
            });
    });
    function cargarHistorialDesembolsos(idPrestamo) {
        return WebApp.UI.withSpinner(() => $.getJSON("/Prestamo/ListarDesembolsos", { idPrestamo }), "Cargando desembolsos...")
            .done(function (r) {
                if (!(r.success || r.Success)) {
                    dtDesembolsosPrestamo.clear().draw();
                    WebApp.Forms.showToast(false, r.message || r.Mensaje || "No se pudo cargar desembolsos.");
                    return;
                }

                const rows = r.data || r.Data || [];
                dtDesembolsosPrestamo.clear().rows.add(rows).draw();
            })
            .fail(function () {
                dtDesembolsosPrestamo.clear().draw();
                WebApp.Forms.showToast(false, "Error al cargar desembolsos.");
            });
    }
    $(document).on("click", ".js-ver-pagos", function () {
        abrirModalPagos({
            idPrestamo: $(this).data("idprestamo"),
            nroCobranza: $(this).data("nrocobranza"),
            cliente: $(this).data("cliente"),
            documento: $(this).data("documento"),
            deudaTotal: $(this).data("deudatotal"),
            pagadoTotal: $(this).data("pagadototal"),
            saldoPendiente: $(this).data("saldopendiente")
        });
    });

    $(document).on("click", ".js-ver-desembolso", function () {
        abrirModalDesembolso({
            idPrestamo: $(this).data("idprestamo"),
            nroCobranza: $(this).data("nrocobranza"),
            cliente: $(this).data("cliente"),
            documento: $(this).data("documento"),
            capital: $(this).data("capital"),
            desembolsado: $(this).data("desembolsado")
        });
    });

    $("#btnAbrirRegistrarDesembolso").on("click", function () {
        abrirModalRegistrarDesembolso();
    });

    $("#btnAbrirGenerarPago").on("click", function () {
        abrirModalGenerarPago();
    });

    $("#FormaPago").on("change", function () {
        cargarCajasPorFormaPago($(this).val());
    });


    $("#Capital, #TipoInteres, #PorcInteresMensual, #FrecuenciaPago, #FechaInicioCobro, #FechaFinCobro, #TipoModalidad").on("change keyup", function () {
        simulacionOk = false;
    });

    $mdlPrestamo.on("hidden.bs.modal", function () {
        limpiarFormulario();
    });
    $("#TieneGarantia").on("change", function () {
        toggleGarantia();
    });
    function toggleGarantia() {
        const checked = $("#TieneGarantia").is(":checked");
        $("#panelGarantia").toggleClass("d-none", !checked);
    }



    $(function () {
        initDataTable();
        initClienteSelect();
        cargarAlmacenes();
        listarPrestamos();
    });
})();