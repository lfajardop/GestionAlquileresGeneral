(function(){
    let usuarios = [];
    let choferes = [];
    let usuarioActual = null;
    let modo = "crear";

    const token = () => $("#flotaUsuariosMobileToken input[name='__RequestVerificationToken']").val();
    const fmtDateTime = value => value ? new Date(value).toLocaleString("es-PE") : "-";
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
    const failMessage = (xhr, fallback) => {
        const message = xhr?.responseJSON?.message
            || xhr?.responseJSON?.mensaje
            || xhr?.responseJSON?.errors?.[0]
            || xhr?.responseText;
        return message ? `${fallback}: ${message}` : fallback;
    };
    const clearSelect = ($el, placeholder) => $el.empty().append(`<option value="">${placeholder}</option>`);

    function badgeEstado(estado){
        return estado === "A"
            ? '<span class="fleet-pill fleet-pill--active">Activo</span>'
            : '<span class="fleet-pill fleet-pill--danger">Inactivo</span>';
    }

    function renderKpi(){
        $("#kpiUsuariosActivos").text(usuarios.filter(x => x.flgEstado === "A").length);
        $("#kpiUsuariosInactivos").text(usuarios.filter(x => x.flgEstado !== "A").length);
    }

    function renderChoferes(){
        const $chofer = $("#usuarioMobileChofer");
        clearSelect($chofer, "Seleccione chofer...");
        choferes.forEach(item => {
            const doc = item.documento ? ` · ${item.documento}` : "";
            $chofer.append(`<option value="${item.idChofer}">${item.nombres}${doc}</option>`);
        });
    }

    function renderLista(){
        const tbody = $("#usuariosMobileRows").empty();
        if(!usuarios.length){
            tbody.append('<tr><td colspan="7" class="fleet-empty">No hay usuarios mobile registrados todavía.</td></tr>');
            renderKpi();
            return;
        }

        usuarios.forEach(x => {
            tbody.append(`
                <tr>
                    <td><strong>${x.telefono || "-"}</strong></td>
                    <td>${x.nombre || "-"}</td>
                    <td>${x.choferNombre || "-"}</td>
                    <td>${x.documentoChofer || "-"}</td>
                    <td>${badgeEstado(x.flgEstado)}</td>
                    <td>${fmtDateTime(x.fecUltimoLogin)}</td>
                    <td>
                        <div class="fleet-admin-actions">
                            <button type="button" class="fleet-btn fleet-btn-soft js-select-usuario-mobile" data-id="${x.idUsuarioMobile}">
                                <i class="bi bi-eye"></i> Ver
                            </button>
                            <button type="button" class="fleet-btn fleet-btn-soft js-edit-usuario-mobile" data-id="${x.idUsuarioMobile}">
                                <i class="bi bi-pencil-square"></i> Editar
                            </button>
                        </div>
                    </td>
                </tr>
            `);
        });

        renderKpi();
    }

    function clearPanel(){
        usuarioActual = null;
        $("#usuarioMobileVacio").removeClass("fleet-hidden");
        $("#usuarioMobilePanel").addClass("fleet-hidden");
        $("#formResetPinMobile")[0].reset();
    }

    function renderPanel(item){
        usuarioActual = item;
        $("#usuarioMobileVacio").addClass("fleet-hidden");
        $("#usuarioMobilePanel").removeClass("fleet-hidden");
        $("#detalleUsuarioTelefono").text(item.telefono || "-");
        $("#detalleUsuarioEstado").html(badgeEstado(item.flgEstado));
        $("#detalleUsuarioNombre").text(item.nombre || "-");
        $("#detalleUsuarioChofer").text(item.choferNombre || "-");
        $("#detalleUsuarioDocumento").text(item.documentoChofer || "-");
        $("#detalleUsuarioUltimoLogin").text(fmtDateTime(item.fecUltimoLogin));
        $("#btnToggleEstadoUsuarioMobile")
            .toggleClass("fleet-btn-danger", item.flgEstado === "A")
            .toggleClass("fleet-btn-success", item.flgEstado !== "A")
            .html(item.flgEstado === "A"
                ? '<i class="bi bi-pause-circle"></i> Inactivar usuario'
                : '<i class="bi bi-play-circle"></i> Reactivar usuario');
    }

    function resetForm(){
        modo = "crear";
        $("#usuarioMobileFormTitle").text("Nuevo usuario mobile");
        $("#usuarioMobileId").val("0");
        $("#formUsuarioMobile")[0].reset();
        $("#usuarioMobileEstado").val("A").prop("disabled", false);
        $("#usuarioMobilePinWrap").removeClass("fleet-hidden");
        $("#btnCancelarEdicionUsuarioMobile").addClass("fleet-hidden");
        $("#btnGuardarUsuarioMobile").html('<i class="bi bi-save"></i> Guardar usuario');
        renderChoferes();
    }

    function fillForm(item){
        modo = "editar";
        $("#usuarioMobileFormTitle").text("Editar usuario mobile");
        $("#usuarioMobileId").val(String(item.idUsuarioMobile));
        $("#usuarioMobileTelefono").val(item.telefono || "");
        $("#usuarioMobileNombre").val(item.nombre || "");
        $("#usuarioMobileChofer").val(item.idChofer ? String(item.idChofer) : "");
        $("#usuarioMobileEstado").val(item.flgEstado || "A").prop("disabled", false);
        $("#usuarioMobilePinWrap").addClass("fleet-hidden");
        $("#btnCancelarEdicionUsuarioMobile").removeClass("fleet-hidden");
        $("#btnGuardarUsuarioMobile").html('<i class="bi bi-save"></i> Guardar cambios');
    }

    function payloadForm(){
        return {
            idUsuarioMobile: Number($("#usuarioMobileId").val() || 0),
            idChofer: Number($("#usuarioMobileChofer").val() || 0),
            telefono: ($("#usuarioMobileTelefono").val() || "").trim(),
            nombre: ($("#usuarioMobileNombre").val() || "").trim(),
            pin: ($("#usuarioMobilePin").val() || "").trim(),
            confirmarPin: ($("#usuarioMobilePinConfirmar").val() || "").trim(),
            flgEstado: ($("#usuarioMobileEstado").val() || "A").trim()
        };
    }

    function loadCatalogos(){
        return $.getJSON("/Flota/Catalogos").done(r => {
            if(!r.success){
                notify(false, r.message || "No se pudieron cargar los catálogos.");
                return;
            }
            choferes = (r.data && r.data.choferes) || [];
            renderChoferes();
        });
    }

    function loadUsuarios(){
        return $.getJSON("/Flota/UsuariosMobileListar").done(r => {
            if(!r.success){
                notify(false, r.message || "No se pudieron listar los usuarios mobile.");
                return;
            }
            usuarios = r.data || [];
            renderLista();
            if(usuarioActual){
                const current = usuarios.find(x => x.idUsuarioMobile === usuarioActual.idUsuarioMobile);
                current ? renderPanel(current) : clearPanel();
            }
        });
    }

    function reloadAll(){
        return $.when(loadCatalogos(), loadUsuarios()).done(() => {
            if(modo === "crear"){
                resetForm();
            }
        });
    }

    $(document).on("click", ".js-select-usuario-mobile", function(){
        const item = usuarios.find(x => x.idUsuarioMobile === Number($(this).data("id")));
        if(item){
            renderPanel(item);
        }
    });

    $(document).on("click", ".js-edit-usuario-mobile", function(){
        const item = usuarios.find(x => x.idUsuarioMobile === Number($(this).data("id")));
        if(item){
            renderPanel(item);
            fillForm(item);
            window.scrollTo({ top: 0, behavior: "smooth" });
        }
    });

    $("#btnNuevoUsuarioMobile").on("click", function(){
        resetForm();
        window.scrollTo({ top: 0, behavior: "smooth" });
    });

    $("#btnCancelarEdicionUsuarioMobile").on("click", resetForm);
    $("#btnRecargarUsuariosMobile").on("click", reloadAll);
    $("#btnEditarUsuarioMobile").on("click", function(){
        if(usuarioActual){
            fillForm(usuarioActual);
            window.scrollTo({ top: 0, behavior: "smooth" });
        }
    });

    $("#btnToggleEstadoUsuarioMobile").on("click", function(){
        if(!usuarioActual){
            notify(false, "Selecciona un usuario mobile.");
            return;
        }
        const next = usuarioActual.flgEstado === "A" ? "X" : "A";
        postJson("/Flota/CambiarEstadoUsuarioMobile", {
            idUsuarioMobile: usuarioActual.idUsuarioMobile,
            flgEstado: next
        }).done(r => {
            notify(r.success, r.message);
            if(r.success){
                reloadAll();
            }
        }).fail(() => notify(false, "No se pudo cambiar el estado del usuario mobile."));
    });

    $("#formResetPinMobile").on("submit", function(ev){
        ev.preventDefault();
        if(!usuarioActual){
            notify(false, "Selecciona un usuario mobile.");
            return;
        }
        postJson("/Flota/ResetPinUsuarioMobile", {
            idUsuarioMobile: usuarioActual.idUsuarioMobile,
            pin: $("#resetPin").val(),
            confirmarPin: $("#resetPinConfirmar").val()
        }).done(r => {
            notify(r.success, r.message);
            if(r.success){
                this.reset();
                reloadAll();
            }
        }).fail(() => notify(false, "No se pudo resetear el PIN mobile."));
    });

    $("#formUsuarioMobile").on("submit", function(ev){
        ev.preventDefault();
        const data = payloadForm();
        const url = modo === "editar" ? "/Flota/ActualizarUsuarioMobile" : "/Flota/CrearUsuarioMobile";
        if(modo === "editar"){
            delete data.pin;
            delete data.confirmarPin;
        }
        postJson(url, data).done(r => {
            notify(r.success, r.message);
            if(r.success){
                resetForm();
                reloadAll();
            }
        }).fail(xhr => notify(false, failMessage(
            xhr,
            modo === "editar" ? "No se pudo actualizar el usuario mobile" : "No se pudo crear el usuario mobile"
        )));
    });

    $(function(){
        reloadAll();
    });
})();
