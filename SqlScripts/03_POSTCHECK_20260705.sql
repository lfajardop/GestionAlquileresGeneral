SET NOCOUNT ON;

DECLARE @Resultado TABLE(
    Etapa VARCHAR(50),
    Validacion VARCHAR(200),
    Resultado VARCHAR(20),
    Detalle VARCHAR(500)
);

INSERT INTO @Resultado
VALUES
('POSTCHECK 20260705', 'Tabla flota.AuditoriaFlota', CASE WHEN OBJECT_ID('flota.AuditoriaFlota', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.AuditoriaFlota', 'U') IS NOT NULL THEN 'Existe flota.AuditoriaFlota' ELSE 'No existe flota.AuditoriaFlota' END),
('POSTCHECK 20260705', 'Columna ReciboAlquiler.Usu_Anula', CASE WHEN COL_LENGTH('flota.ReciboAlquiler', 'Usu_Anula') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.ReciboAlquiler', 'Usu_Anula') IS NOT NULL THEN 'Existe Usu_Anula' ELSE 'Falta Usu_Anula' END),
('POSTCHECK 20260705', 'Columna ReciboAlquiler.Fec_Anula', CASE WHEN COL_LENGTH('flota.ReciboAlquiler', 'Fec_Anula') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.ReciboAlquiler', 'Fec_Anula') IS NOT NULL THEN 'Existe Fec_Anula' ELSE 'Falta Fec_Anula' END),
('POSTCHECK 20260705', 'Columna ReciboAlquiler.MotivoAnula', CASE WHEN COL_LENGTH('flota.ReciboAlquiler', 'MotivoAnula') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.ReciboAlquiler', 'MotivoAnula') IS NOT NULL THEN 'Existe MotivoAnula' ELSE 'Falta MotivoAnula' END),
('POSTCHECK 20260705', 'Columna ReciboAlquilerDetalleDia.FlgEstado', CASE WHEN COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'FlgEstado') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'FlgEstado') IS NOT NULL THEN 'Existe FlgEstado' ELSE 'Falta FlgEstado' END),
('POSTCHECK 20260705', 'Columna ReciboAlquilerDetalleDia.Usu_Anula', CASE WHEN COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'Usu_Anula') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'Usu_Anula') IS NOT NULL THEN 'Existe Usu_Anula' ELSE 'Falta Usu_Anula' END),
('POSTCHECK 20260705', 'Columna ReciboAlquilerDetalleDia.Fec_Anula', CASE WHEN COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'Fec_Anula') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'Fec_Anula') IS NOT NULL THEN 'Existe Fec_Anula' ELSE 'Falta Fec_Anula' END),
('POSTCHECK 20260705', 'Columna ReciboAlquilerDetalleDia.MotivoAnula', CASE WHEN COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'MotivoAnula') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'MotivoAnula') IS NOT NULL THEN 'Existe MotivoAnula' ELSE 'Falta MotivoAnula' END),
('POSTCHECK 20260705', 'Columna PagoReciboAlquiler.Usu_Modif', CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Usu_Modif') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Usu_Modif') IS NOT NULL THEN 'Existe Usu_Modif' ELSE 'Falta Usu_Modif' END),
('POSTCHECK 20260705', 'Columna PagoReciboAlquiler.Fec_Modif', CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Fec_Modif') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Fec_Modif') IS NOT NULL THEN 'Existe Fec_Modif' ELSE 'Falta Fec_Modif' END),
('POSTCHECK 20260705', 'Columna PagoReciboAlquiler.Usu_Anula', CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Usu_Anula') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Usu_Anula') IS NOT NULL THEN 'Existe Usu_Anula' ELSE 'Falta Usu_Anula' END),
('POSTCHECK 20260705', 'Columna PagoReciboAlquiler.Fec_Anula', CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Fec_Anula') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Fec_Anula') IS NOT NULL THEN 'Existe Fec_Anula' ELSE 'Falta Fec_Anula' END),
('POSTCHECK 20260705', 'Columna PagoReciboAlquiler.MotivoAnula', CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'MotivoAnula') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'MotivoAnula') IS NOT NULL THEN 'Existe MotivoAnula' ELSE 'Falta MotivoAnula' END),
('POSTCHECK 20260705', 'Columna PagoReciboAlquiler.MotivoValidacion', CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'MotivoValidacion') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'MotivoValidacion') IS NOT NULL THEN 'Existe MotivoValidacion' ELSE 'Falta MotivoValidacion' END),
('POSTCHECK 20260705', 'Columna PagoReciboAlquiler.Usu_Valida', CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Usu_Valida') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Usu_Valida') IS NOT NULL THEN 'Existe Usu_Valida' ELSE 'Falta Usu_Valida' END),
('POSTCHECK 20260705', 'Columna PagoReciboAlquiler.Fec_Valida', CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Fec_Valida') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.PagoReciboAlquiler', 'Fec_Valida') IS NOT NULL THEN 'Existe Fec_Valida' ELSE 'Falta Fec_Valida' END);

INSERT INTO @Resultado
SELECT
    'POSTCHECK 20260705',
    'Indice IX_flota_ReciboDetalleDia_ReciboEstadoFecha',
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.ReciboAlquilerDetalleDia', 'U') AND name = 'IX_flota_ReciboDetalleDia_ReciboEstadoFecha') THEN 'OK' ELSE 'FALTA' END,
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.ReciboAlquilerDetalleDia', 'U') AND name = 'IX_flota_ReciboDetalleDia_ReciboEstadoFecha') THEN 'Existe indice IX_flota_ReciboDetalleDia_ReciboEstadoFecha' ELSE 'Falta indice IX_flota_ReciboDetalleDia_ReciboEstadoFecha' END
UNION ALL
SELECT
    'POSTCHECK 20260705',
    'Indice IX_flota_PagoReciboAlquiler_ReciboEstadoFecha',
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.PagoReciboAlquiler', 'U') AND name = 'IX_flota_PagoReciboAlquiler_ReciboEstadoFecha') THEN 'OK' ELSE 'FALTA' END,
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.PagoReciboAlquiler', 'U') AND name = 'IX_flota_PagoReciboAlquiler_ReciboEstadoFecha') THEN 'Existe indice IX_flota_PagoReciboAlquiler_ReciboEstadoFecha' ELSE 'Falta indice IX_flota_PagoReciboAlquiler_ReciboEstadoFecha' END
UNION ALL
SELECT
    'POSTCHECK 20260705',
    'Indice UX_flota_ReciboDetalle_Operacion_Activa',
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.ReciboAlquilerDetalleDia', 'U') AND name = 'UX_flota_ReciboDetalle_Operacion_Activa') THEN 'OK' ELSE 'FALTA' END,
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.ReciboAlquilerDetalleDia', 'U') AND name = 'UX_flota_ReciboDetalle_Operacion_Activa') THEN 'Existe indice UX_flota_ReciboDetalle_Operacion_Activa' ELSE 'Falta indice UX_flota_ReciboDetalle_Operacion_Activa' END;

INSERT INTO @Resultado
VALUES
('POSTCHECK 20260705', 'SP flota.p_AuditoriaFlota_Registrar', CASE WHEN OBJECT_ID('flota.p_AuditoriaFlota_Registrar', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_AuditoriaFlota_Registrar', 'P') IS NOT NULL THEN 'Existe flota.p_AuditoriaFlota_Registrar' ELSE 'Falta flota.p_AuditoriaFlota_Registrar' END),
('POSTCHECK 20260705', 'SP flota.p_ReciboAlquiler_Recalcular', CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_Recalcular', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_Recalcular', 'P') IS NOT NULL THEN 'Existe flota.p_ReciboAlquiler_Recalcular' ELSE 'Falta flota.p_ReciboAlquiler_Recalcular' END),
('POSTCHECK 20260705', 'SP flota.p_ReciboAlquiler_Anular', CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_Anular', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_Anular', 'P') IS NOT NULL THEN 'Existe flota.p_ReciboAlquiler_Anular' ELSE 'Falta flota.p_ReciboAlquiler_Anular' END),
('POSTCHECK 20260705', 'SP flota.p_ReciboAlquiler_QuitarDia', CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_QuitarDia', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_ReciboAlquiler_QuitarDia', 'P') IS NOT NULL THEN 'Existe flota.p_ReciboAlquiler_QuitarDia' ELSE 'Falta flota.p_ReciboAlquiler_QuitarDia' END),
('POSTCHECK 20260705', 'SP flota.p_PagoReciboAlquiler_Editar', CASE WHEN OBJECT_ID('flota.p_PagoReciboAlquiler_Editar', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_PagoReciboAlquiler_Editar', 'P') IS NOT NULL THEN 'Existe flota.p_PagoReciboAlquiler_Editar' ELSE 'Falta flota.p_PagoReciboAlquiler_Editar' END),
('POSTCHECK 20260705', 'SP flota.p_PagoReciboAlquiler_Anular', CASE WHEN OBJECT_ID('flota.p_PagoReciboAlquiler_Anular', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_PagoReciboAlquiler_Anular', 'P') IS NOT NULL THEN 'Existe flota.p_PagoReciboAlquiler_Anular' ELSE 'Falta flota.p_PagoReciboAlquiler_Anular' END),
('POSTCHECK 20260705', 'SP flota.p_PagoReciboAlquiler_Validar', CASE WHEN OBJECT_ID('flota.p_PagoReciboAlquiler_Validar', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_PagoReciboAlquiler_Validar', 'P') IS NOT NULL THEN 'Existe flota.p_PagoReciboAlquiler_Validar' ELSE 'Falta flota.p_PagoReciboAlquiler_Validar' END),
('POSTCHECK 20260705', 'SP flota.p_OperacionDia_Corregir', CASE WHEN OBJECT_ID('flota.p_OperacionDia_Corregir', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_OperacionDia_Corregir', 'P') IS NOT NULL THEN 'Existe flota.p_OperacionDia_Corregir' ELSE 'Falta flota.p_OperacionDia_Corregir' END);

IF OBJECT_ID('flota.ReciboAlquilerDetalleDia', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260705', 'Duplicados activos de Id_OperacionDia', 'FALTA', 'No existe flota.ReciboAlquilerDetalleDia');
END
ELSE IF COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'Id_OperacionDia') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260705', 'Duplicados activos de Id_OperacionDia', 'ALERTA', 'No existe columna Id_OperacionDia en flota.ReciboAlquilerDetalleDia');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT
        'POSTCHECK 20260705',
        'Duplicados activos de Id_OperacionDia',
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM flota.ReciboAlquilerDetalleDia
                WHERE Id_OperacionDia IS NOT NULL
                  AND ISNULL(FlgEstado, 'A') = 'A'
                GROUP BY Id_OperacionDia
                HAVING COUNT(*) > 1
            ) THEN 'ALERTA'
            ELSE 'OK'
        END,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM flota.ReciboAlquilerDetalleDia
                WHERE Id_OperacionDia IS NOT NULL
                  AND ISNULL(FlgEstado, 'A') = 'A'
                GROUP BY Id_OperacionDia
                HAVING COUNT(*) > 1
            ) THEN 'Existen duplicados activos de Id_OperacionDia'
            ELSE 'No existen duplicados activos de Id_OperacionDia'
        END;
END;

IF OBJECT_ID('flota.ReciboAlquiler', 'U') IS NULL OR OBJECT_ID('flota.ReciboAlquilerDetalleDia', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260705', 'Recibos anulados con detalles activos', 'FALTA', 'Faltan tablas de recibos');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT
        'POSTCHECK 20260705',
        'Recibos anulados con detalles activos',
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM flota.ReciboAlquiler r
                INNER JOIN flota.ReciboAlquilerDetalleDia d
                    ON d.Id_ReciboAlquiler = r.Id_ReciboAlquiler
                WHERE r.Estado = 'X'
                  AND ISNULL(d.FlgEstado, 'A') = 'A'
            ) THEN 'ALERTA'
            ELSE 'OK'
        END,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM flota.ReciboAlquiler r
                INNER JOIN flota.ReciboAlquilerDetalleDia d
                    ON d.Id_ReciboAlquiler = r.Id_ReciboAlquiler
                WHERE r.Estado = 'X'
                  AND ISNULL(d.FlgEstado, 'A') = 'A'
            ) THEN 'Existen recibos anulados con detalles activos'
            ELSE 'No existen recibos anulados con detalles activos'
        END;
END;

SELECT Etapa, Validacion, Resultado, Detalle
FROM @Resultado
ORDER BY
    CASE Resultado WHEN 'FALTA' THEN 1 WHEN 'ALERTA' THEN 2 WHEN 'OK' THEN 3 ELSE 4 END,
    Validacion;
