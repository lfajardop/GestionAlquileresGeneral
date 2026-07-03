SET NOCOUNT ON;

DECLARE @Resultado TABLE(
    Etapa VARCHAR(50),
    Validacion VARCHAR(200),
    Resultado VARCHAR(20),
    Detalle VARCHAR(500)
);

INSERT INTO @Resultado
VALUES
('POSTCHECK 20260704', 'Tabla flota.periodicidad_cobro', CASE WHEN OBJECT_ID('flota.periodicidad_cobro', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.periodicidad_cobro', 'U') IS NOT NULL THEN 'Existe flota.periodicidad_cobro' ELSE 'No existe flota.periodicidad_cobro' END),
('POSTCHECK 20260704', 'Tabla flota.medio_pago_alquiler', CASE WHEN OBJECT_ID('flota.medio_pago_alquiler', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.medio_pago_alquiler', 'U') IS NOT NULL THEN 'Existe flota.medio_pago_alquiler' ELSE 'No existe flota.medio_pago_alquiler' END),
('POSTCHECK 20260704', 'Tabla flota.ReciboAlquiler', CASE WHEN OBJECT_ID('flota.ReciboAlquiler', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.ReciboAlquiler', 'U') IS NOT NULL THEN 'Existe flota.ReciboAlquiler' ELSE 'No existe flota.ReciboAlquiler' END),
('POSTCHECK 20260704', 'Tabla flota.ReciboAlquilerDetalleDia', CASE WHEN OBJECT_ID('flota.ReciboAlquilerDetalleDia', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.ReciboAlquilerDetalleDia', 'U') IS NOT NULL THEN 'Existe flota.ReciboAlquilerDetalleDia' ELSE 'No existe flota.ReciboAlquilerDetalleDia' END),
('POSTCHECK 20260704', 'Tabla flota.PagoReciboAlquiler', CASE WHEN OBJECT_ID('flota.PagoReciboAlquiler', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.PagoReciboAlquiler', 'U') IS NOT NULL THEN 'Existe flota.PagoReciboAlquiler' ELSE 'No existe flota.PagoReciboAlquiler' END),
('POSTCHECK 20260704', 'Type flota.FechaSeleccionadaType', CASE WHEN TYPE_ID('flota.FechaSeleccionadaType') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN TYPE_ID('flota.FechaSeleccionadaType') IS NOT NULL THEN 'Existe flota.FechaSeleccionadaType' ELSE 'No existe flota.FechaSeleccionadaType' END),
('POSTCHECK 20260704', 'Columna flota.contrato.Cod_Periodicidad', CASE WHEN COL_LENGTH('flota.contrato', 'Cod_Periodicidad') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.contrato', 'Cod_Periodicidad') IS NOT NULL THEN 'Existe columna Cod_Periodicidad' ELSE 'Falta columna Cod_Periodicidad' END),
('POSTCHECK 20260704', 'Columna flota.operacion_dia.FlgOrigen', CASE WHEN COL_LENGTH('flota.operacion_dia', 'FlgOrigen') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.operacion_dia', 'FlgOrigen') IS NOT NULL THEN 'Existe columna FlgOrigen' ELSE 'Falta columna FlgOrigen' END);

IF OBJECT_ID('flota.periodicidad_cobro', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260704', 'Periodicidad S', 'FALTA', 'No existe flota.periodicidad_cobro');
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260704', 'Periodicidad Q', 'FALTA', 'No existe flota.periodicidad_cobro');
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260704', 'Periodicidad M', 'FALTA', 'No existe flota.periodicidad_cobro');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT 'POSTCHECK 20260704', 'Periodicidad S',
           CASE WHEN EXISTS (SELECT 1 FROM flota.periodicidad_cobro WHERE Cod_Periodicidad = 'S') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.periodicidad_cobro WHERE Cod_Periodicidad = 'S') THEN 'Existe periodicidad S' ELSE 'Falta periodicidad S' END
    UNION ALL
    SELECT 'POSTCHECK 20260704', 'Periodicidad Q',
           CASE WHEN EXISTS (SELECT 1 FROM flota.periodicidad_cobro WHERE Cod_Periodicidad = 'Q') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.periodicidad_cobro WHERE Cod_Periodicidad = 'Q') THEN 'Existe periodicidad Q' ELSE 'Falta periodicidad Q' END
    UNION ALL
    SELECT 'POSTCHECK 20260704', 'Periodicidad M',
           CASE WHEN EXISTS (SELECT 1 FROM flota.periodicidad_cobro WHERE Cod_Periodicidad = 'M') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.periodicidad_cobro WHERE Cod_Periodicidad = 'M') THEN 'Existe periodicidad M' ELSE 'Falta periodicidad M' END;
END;

IF OBJECT_ID('flota.medio_pago_alquiler', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260704', 'Medio pago EF', 'FALTA', 'No existe flota.medio_pago_alquiler');
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260704', 'Medio pago YA', 'FALTA', 'No existe flota.medio_pago_alquiler');
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260704', 'Medio pago TR', 'FALTA', 'No existe flota.medio_pago_alquiler');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT 'POSTCHECK 20260704', 'Medio pago EF',
           CASE WHEN EXISTS (SELECT 1 FROM flota.medio_pago_alquiler WHERE Cod_MedioPago = 'EF') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.medio_pago_alquiler WHERE Cod_MedioPago = 'EF') THEN 'Existe medio pago EF' ELSE 'Falta medio pago EF' END
    UNION ALL
    SELECT 'POSTCHECK 20260704', 'Medio pago YA',
           CASE WHEN EXISTS (SELECT 1 FROM flota.medio_pago_alquiler WHERE Cod_MedioPago = 'YA') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.medio_pago_alquiler WHERE Cod_MedioPago = 'YA') THEN 'Existe medio pago YA' ELSE 'Falta medio pago YA' END
    UNION ALL
    SELECT 'POSTCHECK 20260704', 'Medio pago TR',
           CASE WHEN EXISTS (SELECT 1 FROM flota.medio_pago_alquiler WHERE Cod_MedioPago = 'TR') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.medio_pago_alquiler WHERE Cod_MedioPago = 'TR') THEN 'Existe medio pago TR' ELSE 'Falta medio pago TR' END;
END;

INSERT INTO @Resultado
VALUES
('POSTCHECK 20260704', 'SP flota.p_ReciboAlquiler_Generar', CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_Generar', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_Generar', 'P') IS NOT NULL THEN 'Existe flota.p_ReciboAlquiler_Generar' ELSE 'Falta flota.p_ReciboAlquiler_Generar' END),
('POSTCHECK 20260704', 'SP flota.p_ReciboAlquiler_GenerarManual', CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_GenerarManual', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_GenerarManual', 'P') IS NOT NULL THEN 'Existe flota.p_ReciboAlquiler_GenerarManual' ELSE 'Falta flota.p_ReciboAlquiler_GenerarManual' END),
('POSTCHECK 20260704', 'SP flota.p_PagoReciboAlquiler_Registrar', CASE WHEN OBJECT_ID('flota.p_PagoReciboAlquiler_Registrar', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_PagoReciboAlquiler_Registrar', 'P') IS NOT NULL THEN 'Existe flota.p_PagoReciboAlquiler_Registrar' ELSE 'Falta flota.p_PagoReciboAlquiler_Registrar' END),
('POSTCHECK 20260704', 'SP flota.p_ReciboAlquiler_ListarPorContrato', CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_ListarPorContrato', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_ListarPorContrato', 'P') IS NOT NULL THEN 'Existe flota.p_ReciboAlquiler_ListarPorContrato' ELSE 'Falta flota.p_ReciboAlquiler_ListarPorContrato' END),
('POSTCHECK 20260704', 'SP flota.p_ReciboAlquiler_ObtenerDetalle', CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_ObtenerDetalle', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_ObtenerDetalle', 'P') IS NOT NULL THEN 'Existe flota.p_ReciboAlquiler_ObtenerDetalle' ELSE 'Falta flota.p_ReciboAlquiler_ObtenerDetalle' END),
('POSTCHECK 20260704', 'SP flota.p_AdminCalendario_Obtener', CASE WHEN OBJECT_ID('flota.p_AdminCalendario_Obtener', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_AdminCalendario_Obtener', 'P') IS NOT NULL THEN 'Existe flota.p_AdminCalendario_Obtener' ELSE 'Falta flota.p_AdminCalendario_Obtener' END),
('POSTCHECK 20260704', 'SP flota.p_Contrato_Admin_Listar', CASE WHEN OBJECT_ID('flota.p_Contrato_Admin_Listar', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_Contrato_Admin_Listar', 'P') IS NOT NULL THEN 'Existe flota.p_Contrato_Admin_Listar' ELSE 'Falta flota.p_Contrato_Admin_Listar' END);

SELECT Etapa, Validacion, Resultado, Detalle
FROM @Resultado
ORDER BY
    CASE Resultado WHEN 'FALTA' THEN 1 WHEN 'ALERTA' THEN 2 WHEN 'OK' THEN 3 ELSE 4 END,
    Validacion;
