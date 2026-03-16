window.WebApp = window.WebApp || {};
WebApp.Forms = (function () {

    function showMsg($msg, ok, text) {
        $msg.removeClass("d-none alert-danger alert-success")
            .addClass(ok ? "alert-success" : "alert-danger")
            .text(text || "");
    }

    function hideMsg($msg) {
        $msg.addClass("d-none").text("");
    }

    function clearErrors($form) {
        $form.find(".field-error").text("");
        $form.find(".input-error").removeClass("input-error");
    }

    function setFieldError($form, field, msg) {
        $form.find(`[data-valmsg-for='${field}']`).text(msg || "");
        $form.find(`#${field}`).addClass("input-error");
    }

    // Soporta "Campo|Mensaje" o solo "Mensaje"
    function mapErrors($form, errors) {
        if (!Array.isArray(errors)) return;

        errors.forEach(e => {
            const s = String(e || "");
            const idx = s.indexOf("|");
            if (idx < 0) return; // sin campo, no se puede pintar input
            const field = s.substring(0, idx);
            const msg = s.substring(idx + 1);
            setFieldError($form, field, msg);
        });
    }

    // mensaje global: primer error (solo mensaje)
    function firstErrorMessage(errors) {
        if (!Array.isArray(errors) || !errors.length) return "";
        const s = String(errors[0] || "");
        const idx = s.indexOf("|");
        return idx >= 0 ? s.substring(idx + 1) : s;
    }

    // wrapper ajax (form post)
    function postForm($form, options) {
        const cfg = options || {};
        const url = cfg.url || $form.attr("action") || window.location.pathname;

        return $.ajax({
            url,
            type: "POST",
            data: $form.serialize()
        });
    }
    let appToast = null;
    function showToast(ok, msg) {
        const el = document.getElementById("appToast");
        const body = document.getElementById("appToastBody");
        body.textContent = msg || (ok ? "OK" : "Ocurrió un error");

        el.classList.remove("text-bg-primary", "text-bg-success", "text-bg-danger", "text-bg-warning");
        el.classList.add(ok ? "text-bg-success" : "text-bg-danger");

        if (!appToast) appToast = new bootstrap.Toast(el, { delay: 7000 });
        appToast.show();
    }

    (function (w) {
        w.WebApp = w.WebApp || {};
        w.WebApp.UI = w.WebApp.UI || {};

        const SPINNER_ID = "#appSpinner";
        let counter = 0;

        w.WebApp.UI.showSpinner = function (text) {
            const $sp = $(SPINNER_ID);
            if (!$sp.length) return;
            if (text) $sp.find(".app-spinner__text").text(text);
            counter++;
            $sp.removeClass("d-none");
        };

        w.WebApp.UI.hideSpinner = function () {
            const $sp = $(SPINNER_ID);
            if (!$sp.length) return;
            counter = Math.max(0, counter - 1);
            if (counter === 0) $sp.addClass("d-none");
        };

        // Devuelve jqXHR y permite .done/.fail/.always
        w.WebApp.UI.withSpinner = function (xhrFactory, text) {
            w.WebApp.UI.showSpinner(text || "Procesando...");
            let xhr;
            try {
                xhr = xhrFactory(); // debe retornar jqXHR
            } catch (e) {
                w.WebApp.UI.hideSpinner();
                throw e;
            }

            // Si es jqXHR, tiene .always
            if (xhr && typeof xhr.always === "function") {
                xhr.always(function () {
                    w.WebApp.UI.hideSpinner();
                });
                return xhr;
            }

            // Fallback: si no retornó jqXHR, apaga y retorna lo que sea
            w.WebApp.UI.hideSpinner();
            return xhr;
        };
    })(window);


    // ===========================
    // WebApp.UI.confirm (Bootstrap 5)
    // ===========================
    window.WebApp = window.WebApp || {};
    WebApp.UI = WebApp.UI || {};

    (function () {
        let _confirmModalEl = null;
        let _confirmModal = null;

        function ensureConfirmModal() {
            if (_confirmModalEl) return;

            const html = `
<div class="modal fade" id="waConfirmModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content rounded-4 shadow">
      <div class="modal-header">
        <h5 class="modal-title" id="waConfirmTitle">Confirmar</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body">
        <div id="waConfirmMessage" class="text-body"></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline-secondary" id="waConfirmCancel" data-bs-dismiss="modal">Cancelar</button>
        <button type="button" class="btn btn-primary" id="waConfirmOk">Aceptar</button>
      </div>
    </div>
  </div>
</div>`.trim();

            document.body.insertAdjacentHTML("beforeend", html);

            _confirmModalEl = document.getElementById("waConfirmModal");
            _confirmModal = new bootstrap.Modal(_confirmModalEl, { backdrop: "static", keyboard: false });
        }

        WebApp.UI.confirm = function (opts) {
            ensureConfirmModal();

            const o = opts || {};
            const title = o.title ?? "Confirmar";
            const message = o.message ?? "¿Deseas continuar?";
            const okText = o.okText ?? "Sí";
            const cancelText = o.cancelText ?? "Cancelar";
            const danger = !!o.danger;

            const $title = _confirmModalEl.querySelector("#waConfirmTitle");
            const $msg = _confirmModalEl.querySelector("#waConfirmMessage");
            const $btnOk = _confirmModalEl.querySelector("#waConfirmOk");
            const $btnCancel = _confirmModalEl.querySelector("#waConfirmCancel");

            $title.textContent = title;

            // message puede ser texto o HTML simple si pasas o.html=true
            if (o.html) $msg.innerHTML = message;
            else $msg.textContent = message;

            $btnOk.textContent = okText;
            $btnCancel.textContent = cancelText;

            // estilo OK button (primary o danger)
            $btnOk.classList.remove("btn-primary", "btn-danger");
            $btnOk.classList.add(danger ? "btn-danger" : "btn-primary");

            return new Promise(resolve => {
                let done = false;

                const cleanup = () => {
                    $btnOk.removeEventListener("click", onOk);
                    _confirmModalEl.removeEventListener("hidden.bs.modal", onHidden);
                };

                const finish = (val) => {
                    if (done) return;
                    done = true;
                    cleanup();
                    resolve(val);
                };

                const onOk = () => {
                    finish(true);
                    _confirmModal.hide();
                    if (typeof o.onOk === "function") o.onOk();
                };

                const onHidden = () => {
                    // si se cerró por X o Cancel => false
                    finish(false);
                    if (typeof o.onCancel === "function") o.onCancel();
                };

                $btnOk.addEventListener("click", onOk);
                _confirmModalEl.addEventListener("hidden.bs.modal", onHidden, { once: false });

                // Mostrar modal
                _confirmModal.show();

                // Enfocar OK por defecto
                setTimeout(() => $btnOk.focus(), 150);
            });
        };
    })();




    return {
        showMsg,
        hideMsg,
        clearErrors,
        setFieldError,
        mapErrors,
        firstErrorMessage,
        postForm,
        showToast
    };
})();
