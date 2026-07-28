(function () {
    let dt = null;
    let ultimaSimulacion = null;
    let formasPagoCatalogo = [];
    let formaPagoIndex = 0;

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
        return "S/." + n.toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    function fecha(v) {
        if (!v) return "";
        const d = new Date(v);
        if (isNaN(d)) return v;
        return String(d.getDate()).padStart(2, "0") + "/" +
            String(d.getMonth() + 1).padStart(2, "0") + "/" +
            d.getFullYear();
    }

    function token() {
        return $("#frmPagoGlobal input[name='__RequestVerificationToken']").val();
    }

    function normalizarNumero(v) {
        const n = Number(String(v || "").replace(",", "."));
        return isNaN(n) ? 0 : n;
    }

    function esEfectivo(texto) {
        return String(texto || "").trim().toUpperCase() === "EFECTIVO";
    }

    function setResumen(resumen) {
        const r = resumen || {};
        $("#pgImportePago").text(money(r.importePago ?? r.ImportePago));
        $("#pgImporteAplicado").text(money(r.importeAplicado ?? r.ImporteAplicado));
        $("#pgImporteExcedente").text(money(r.importeExcedente ?? r.ImporteExcedente));
        $("#pgCuotas").text(r.cuotasAplicadas ?? r.CuotasAplicadas ?? 0);
        $("#pgPrestamos").text(r.prestamosAplicados ?? r.PrestamosAplicados ?? 0);
        $("#pgMensaje").text(r.mensaje || r.Mensaje || "Simula para ver que cuotas se pagaran primero.");
    }

    function limpiarSimulacion() {
        ultimaSimulacion = null;
        setResumen(null);
        if (dt) dt.clear().draw();
        $("#btnAplicarPagoGlobal").prop("disabled", true);
    }

    function recalcularTotalPago() {
        let total = 0;
        $(".js-pg-importe").each(function () {
            total += normalizarNumero($(this).val());
        });

        total = Math.round(total * 100) / 100;
        $("#ImportePago").val(total.toFixed(2));
        $("#ImportePagoVista").val(money(total));
        $("#pgImportePago").text(money(total));
        $("#btnAplicarPagoGlobal").prop("disabled", true);
        return total;
    }

    function opcionesFormasPago() {
        let html = '<option value="">Seleccione</option>';
        formasPagoCatalogo.forEach(x => {
            const id = x.idFormaPago ?? x.IdFormaPago;
            const tipo = x.tipo ?? x.Tipo;
            const selected = esEfectivo(tipo) ? "selected" : "";
            html += `<option value="${id}" data-tipo="${tipo}" ${selected}>${tipo}</option>`;
        });
        return html;
    }

    function cargarCajasFila($row) {
        const $forma = $row.find(".js-pg-forma");
        const $caja = $row.find(".js-pg-caja");
        const texto = $forma.find("option:selected").data("tipo") || $forma.find("option:selected").text();
        const flgEsBanco = esEfectivo(texto) ? "N" : "S";

        $caja.html('<option value="">Cargando...</option>');

        return $.getJSON("/Prestamo/ListarCajasPorBanco", { flgEsBanco })
            .done(function (r) {
                const u = unwrap(r);
                if (!u.ok) {
                    $caja.html('<option value="">Seleccione</option>');
                    WebApp.Forms.showToast(false, u.mensaje || "No se pudieron cargar cajas.");
                    return;
                }

                let html = '<option value="">Seleccione</option>';
                (u.data || []).forEach(x => {
                    const cod = x.codCajaChica ?? x.CodCajaChica;
                    const des = x.desCajaChica ?? x.DesCajaChica;
                    html += `<option value="${cod}">${des}</option>`;
                });
                $caja.html(html);
            })
            .fail(function () {
                $caja.html('<option value="">Seleccione</option>');
                WebApp.Forms.showToast(false, "Error al cargar cajas.");
            });
    }

    function renombrarFilasPago() {
        $("#tbodyFormasPago tr").each(function (i) {
            $(this).find(".js-pg-forma").attr("name", `FormasPago[${i}].IdFormaPago`);
            $(this).find(".js-pg-caja").attr("name", `FormasPago[${i}].CodCajaChica`);
            $(this).find(".js-pg-importe").attr("name", `FormasPago[${i}].Importe`);
        });
    }

    function agregarFormaPago(importe) {
        const id = ++formaPagoIndex;
        const html = `
<tr data-row="${id}">
    <td>
        <select class="form-select js-pg-forma">${opcionesFormasPago()}</select>
        <span class="field-error" data-valmsg-for="FormaPago${id}"></span>
    </td>
    <td>
        <select class="form-select js-pg-caja"><option value="">Seleccione</option></select>
        <span class="field-error" data-valmsg-for="CodCajaChica${id}"></span>
    </td>
    <td>
        <input type="number" step="0.01" min="0" class="form-control text-end js-pg-importe" value="${Number(importe || 0).toFixed(2)}" />
        <span class="field-error" data-valmsg-for="ImporteFormaPago${id}"></span>
    </td>
    <td class="text-center">
        <button type="button" class="pg-row-action js-pg-eliminar" title="Quitar linea">
            <i class="bi bi-trash"></i>
        </button>
    </td>
</tr>`.trim();

        const $row = $(html);
        $("#tbodyFormasPago").append($row);
        renombrarFilasPago();
        cargarCajasFila($row);
        recalcularTotalPago();
    }

    function cargarFormasPago() {
        return $.getJSON("/Prestamo/ListarFormasPago")
            .done(function (r) {
                const u = unwrap(r);
                if (!u.ok) {
                    WebApp.Forms.showToast(false, u.mensaje || "No se pudieron cargar formas de pago.");
                    return;
                }

                formasPagoCatalogo = u.data || [];
                if ($("#tbodyFormasPago tr").length === 0) {
                    agregarFormaPago(0);
                }
            })
            .fail(function () {
                WebApp.Forms.showToast(false, "Error al cargar formas de pago.");
            });
    }

    function initCliente() {
        const $cliente = $("#ClientePagoGlobal");

        $cliente.select2({
            placeholder: "Buscar cliente...",
            allowClear: true,
            width: "100%",
            minimumInputLength: 2,
            ajax: {
                url: "/Prestamo/BuscarClientes",
                dataType: "json",
                delay: 250,
                data: function (params) {
                    return { texto: params.term || "" };
                },
                processResults: function (r) {
                    const u = unwrap(r);
                    const rows = u.data || [];
                    return {
                        results: rows.map(x => ({
                            id: (x.cod_TipAnex ?? x.Cod_TipAnex) + "|" + (x.cod_Anxo ?? x.Cod_Anxo),
                            text: x.textoMostrar ?? x.TextoMostrar ?? x.nombreCompleto ?? x.NombreCompleto,
                            codTipAnex: x.cod_TipAnex ?? x.Cod_TipAnex,
                            codAnxo: x.cod_Anxo ?? x.Cod_Anxo
                        }))
                    };
                }
            }
        });

        $cliente.on("select2:select", function (e) {
            const d = e.params.data || {};
            $("#Cod_TipAnex").val(d.codTipAnex || "");
            $("#Cod_Anxo").val(d.codAnxo || "");
            limpiarSimulacion();
        });

        $cliente.on("select2:clear", function () {
            $("#Cod_TipAnex").val("");
            $("#Cod_Anxo").val("");
            limpiarSimulacion();
        });
    }

    function initTabla() {
        dt = $("#tblPagoGlobal").DataTable({
            paging: true,
            searching: true,
            ordering: true,
            pageLength: 15,
            autoWidth: false,
            dom: '<"pg-dt-top"lf>rt<"pg-dt-bottom"ip>',
            language: { url: "https://cdn.datatables.net/plug-ins/1.13.8/i18n/es-ES.json" },
            columns: [
                { data: "ordenAplicacion", className: "text-center" },
                { data: "id_Prestamo", className: "text-center" },
                { data: "nroCobranza" },
                { data: "numCuota", className: "text-center" },
                { data: "fec_Venc", render: fecha },
                { data: "deudaAntes", render: money, className: "text-end" },
                { data: "importeAplicado", render: money, className: "text-end fw-bold text-success" },
                { data: "saldoDespues", render: money, className: "text-end" }
            ]
        });
    }

    function dataBase() {
        recalcularTotalPago();
        const data = {
            __RequestVerificationToken: token(),
            Cod_TipAnex: $("#Cod_TipAnex").val(),
            Cod_Anxo: $("#Cod_Anxo").val(),
            ImportePago: $("#ImportePago").val(),
            FecPago: $("#FecPago").val(),
            Glosa: $("#Glosa").val(),
            SoloVencidas: $("#SoloVencidas").is(":checked") ? "S" : "N",
            PermitirExcedente: $("#PermitirExcedente").is(":checked")
        };

        $("#tbodyFormasPago tr").each(function (i) {
            data[`FormasPago[${i}].IdFormaPago`] = $(this).find(".js-pg-forma").val();
            data[`FormasPago[${i}].CodCajaChica`] = $(this).find(".js-pg-caja").val();
            data[`FormasPago[${i}].Importe`] = $(this).find(".js-pg-importe").val();
        });

        return data;
    }

    function simular() {
        WebApp.Forms.clearErrors($("#frmPagoGlobal"));
        $("#btnAplicarPagoGlobal").prop("disabled", true);

        return WebApp.UI.withSpinner(() => $.ajax({
            url: "/Prestamo/SimularPagoGlobal",
            type: "POST",
            data: dataBase()
        }), "Simulando pago global...")
            .done(function (r) {
                const u = unwrap(r);
                if (!u.ok) {
                    limpiarSimulacion();
                    WebApp.Forms.mapErrors($("#frmPagoGlobal"), u.errors);
                    WebApp.Forms.showToast(false, u.mensaje || "No se pudo simular.");
                    return;
                }

                ultimaSimulacion = u.data || {};
                const resumen = ultimaSimulacion.resumen || ultimaSimulacion.Resumen || {};
                const detalle = ultimaSimulacion.detalle || ultimaSimulacion.Detalle || [];

                setResumen(resumen);
                dt.clear().rows.add(detalle).draw();
                $("#btnAplicarPagoGlobal").prop("disabled", detalle.length === 0);
            })
            .fail(function () {
                limpiarSimulacion();
                WebApp.Forms.showToast(false, "Error al simular pago global.");
            });
    }

    async function aplicar() {
        if (!ultimaSimulacion) {
            WebApp.Forms.showToast(false, "Primero simula el pago.");
            return;
        }

        const resumen = ultimaSimulacion.resumen || ultimaSimulacion.Resumen || {};
        const aplicado = resumen.importeAplicado ?? resumen.ImporteAplicado ?? 0;
        const cuotas = resumen.cuotasAplicadas ?? resumen.CuotasAplicadas ?? 0;
        const lineas = $("#tbodyFormasPago tr").length;

        const ok = await WebApp.UI.confirm({
            title: "Aplicar pago global",
            message: `Se registrara ${money(aplicado)} distribuido en ${cuotas} cuota(s), usando ${lineas} forma(s) de pago. Esta operacion modifica pagos y saldos.`,
            okText: "Aplicar pago",
            cancelText: "Revisar",
            danger: false
        });

        if (!ok) return;

        return WebApp.UI.withSpinner(() => $.ajax({
            url: "/Prestamo/AplicarPagoGlobal",
            type: "POST",
            data: dataBase()
        }), "Aplicando pago global...")
            .done(function (r) {
                const u = unwrap(r);
                WebApp.Forms.showToast(u.ok, u.mensaje || (u.ok ? "Pago global registrado." : "No se pudo registrar."));

                if (u.ok) {
                    simular();
                }
            })
            .fail(function () {
                WebApp.Forms.showToast(false, "Error al aplicar pago global.");
            });
    }

    $("#btnAgregarFormaPago").on("click", function () {
        agregarFormaPago(0);
    });

    $(document).on("change", ".js-pg-forma", function () {
        cargarCajasFila($(this).closest("tr"));
        $("#btnAplicarPagoGlobal").prop("disabled", true);
    });

    $(document).on("input change", ".js-pg-importe", function () {
        recalcularTotalPago();
    });

    $(document).on("click", ".js-pg-eliminar", function () {
        if ($("#tbodyFormasPago tr").length <= 1) {
            WebApp.Forms.showToast(false, "Debe existir al menos una forma de pago.");
            return;
        }

        $(this).closest("tr").remove();
        renombrarFilasPago();
        recalcularTotalPago();
    });

    $("#btnSimularPagoGlobal").on("click", simular);
    $("#btnAplicarPagoGlobal").on("click", aplicar);
    $("#SoloVencidas,#PermitirExcedente").on("change", function () {
        $("#btnAplicarPagoGlobal").prop("disabled", true);
    });

    $(function () {
        initCliente();
        initTabla();
        cargarFormasPago();
        limpiarSimulacion();
    });
})();
