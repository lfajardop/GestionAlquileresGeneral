(function () {
    const $mdlPrestamo = $("#mdlPrestamo");
    const $frmPrestamo = $("#frmPrestamo");
    const $btnGuardarPrestamo = $("#btnGuardarPrestamo");
    const $btnSimularPrestamo = $("#btnSimularPrestamo");
    const $msg = $("#frmPrestamoMsg");
    const $cliente = $("#Cod_Anxo");

    let dtPrestamos = null;
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

        $cliente.off("select2:select").on("select2:select", function (e) {
            const item = e.params.data;
            $("#Cod_TipAnex").val(item.codTipAnex || "C");
        });

        $cliente.off("select2:clear").on("select2:clear", function () {
            $("#Cod_TipAnex").val("C");
        });


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
                { data: "estado", className: "text-center" }
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