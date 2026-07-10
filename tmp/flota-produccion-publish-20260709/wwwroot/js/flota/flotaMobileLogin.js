(function () {
    const feedback = $("#fmlFeedback");
    const token = () => $("#flotaMobileLoginToken input[name='__RequestVerificationToken']").val();

    function notify(msg) {
        feedback.addClass("show").text(msg || "No se pudo iniciar sesion.");
    }

    function login() {
        const payload = {
            telefono: ($("#fmlTelefono").val() || "").trim(),
            pin: ($("#fmlPin").val() || "").trim()
        };
        $("#fmlIngresar").prop("disabled", true);
        feedback.removeClass("show").text("");
        $.ajax({
            url: "/Flota/MobileLogin",
            type: "POST",
            contentType: "application/json",
            data: JSON.stringify(payload),
            headers: { RequestVerificationToken: token() }
        }).done(r => {
            if (!r.success) {
                notify(r.message);
                return;
            }
            const redirectUrl = r?.data?.redirectUrl || "/Flota/EstacionMobile";
            window.location.href = redirectUrl;
        }).fail(xhr => {
            notify(xhr?.responseJSON?.message || "No se pudo iniciar sesion.");
        }).always(() => $("#fmlIngresar").prop("disabled", false));
    }

    $("#fmlIngresar").on("click", login);
    $("#fmlPin").on("keypress", function (e) {
        if (e.key === "Enter") {
            e.preventDefault();
            login();
        }
    });
})();
