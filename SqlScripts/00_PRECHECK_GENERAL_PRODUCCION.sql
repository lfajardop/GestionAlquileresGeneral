SET NOCOUNT ON;

DECLARE @Resultado TABLE(
    Etapa VARCHAR(50),
    Validacion VARCHAR(200),
    Resultado VARCHAR(20),
    Detalle VARCHAR(500)
);

INSERT INTO @Resultado
VALUES
(
    'PRECHECK GENERAL',
    'Base actual',
    CASE WHEN DB_NAME() = 'DB_9FA64E_bdgas' THEN 'OK' ELSE 'ALERTA' END,
    'DB_NAME()=' + DB_NAME()
);

INSERT INTO @Resultado
VALUES
(
    'PRECHECK GENERAL',
    'Version SQL Server',
    'OK',
    CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(100)) + ' | ' +
    CAST(SERVERPROPERTY('ProductLevel') AS VARCHAR(100)) + ' | ' +
    CAST(SERVERPROPERTY('Edition') AS VARCHAR(200))
);

INSERT INTO @Resultado
VALUES
(
    'PRECHECK GENERAL',
    'Schema flota',
    CASE WHEN EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'flota') THEN 'OK' ELSE 'FALTA' END,
    CASE WHEN EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'flota') THEN 'Existe schema flota' ELSE 'No existe schema flota' END
);

IF OBJECT_ID('dbo.Empresa', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('PRECHECK GENERAL', 'Empresa 6', 'FALTA', 'No existe dbo.Empresa');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT
        'PRECHECK GENERAL',
        'Empresa 6',
        CASE WHEN EXISTS (SELECT 1 FROM dbo.Empresa WHERE id_empresa = 6) THEN 'OK' ELSE 'FALTA' END,
        CASE WHEN EXISTS (SELECT 1 FROM dbo.Empresa WHERE id_empresa = 6) THEN 'Existe id_empresa=6' ELSE 'No existe id_empresa=6' END;
END;

IF OBJECT_ID('dbo.EstablecimientoComercial', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('PRECHECK GENERAL', 'Establecimiento empresa 6 est 4/4 ', 'FALTA', 'No existe dbo.EstablecimientoComercial');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT
        'PRECHECK GENERAL',
        'Establecimiento empresa 6 est 4/4 ',
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM dbo.EstablecimientoComercial
                WHERE id_empresa = 6
                  AND RTRIM(id_est) = '4'
            ) THEN 'OK'
            ELSE 'FALTA'
        END,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM dbo.EstablecimientoComercial
                WHERE id_empresa = 6
                  AND RTRIM(id_est) = '4'
            ) THEN 'Existe establecimiento para empresa 6 con id_est=''4'' o ''4 '''
            ELSE 'No existe establecimiento para empresa 6 con id_est=''4'' o ''4 '''
        END;
END;

INSERT INTO @Resultado
VALUES
('PRECHECK GENERAL', 'Tabla antigua flota.vehiculo', CASE WHEN OBJECT_ID('flota.vehiculo', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.vehiculo', 'U') IS NOT NULL THEN 'Existe flota.vehiculo' ELSE 'No existe flota.vehiculo' END),
('PRECHECK GENERAL', 'Tabla antigua flota.chofer', CASE WHEN OBJECT_ID('flota.chofer', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.chofer', 'U') IS NOT NULL THEN 'Existe flota.chofer' ELSE 'No existe flota.chofer' END),
('PRECHECK GENERAL', 'Tabla antigua flota.alquiler_dia', CASE WHEN OBJECT_ID('flota.alquiler_dia', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.alquiler_dia', 'U') IS NOT NULL THEN 'Existe flota.alquiler_dia' ELSE 'No existe flota.alquiler_dia' END),
('PRECHECK GENERAL', 'Tabla antigua flota.trabajo_dia', CASE WHEN OBJECT_ID('flota.trabajo_dia', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.trabajo_dia', 'U') IS NOT NULL THEN 'Existe flota.trabajo_dia' ELSE 'No existe flota.trabajo_dia' END),
('PRECHECK GENERAL', 'Tabla nueva flota.contrato aun no existe', CASE WHEN OBJECT_ID('flota.contrato', 'U') IS NULL THEN 'OK' ELSE 'ALERTA' END, CASE WHEN OBJECT_ID('flota.contrato', 'U') IS NULL THEN 'Correcto: aun no existe flota.contrato' ELSE 'Ya existe flota.contrato' END),
('PRECHECK GENERAL', 'Tabla nueva flota.operacion_dia aun no existe', CASE WHEN OBJECT_ID('flota.operacion_dia', 'U') IS NULL THEN 'OK' ELSE 'ALERTA' END, CASE WHEN OBJECT_ID('flota.operacion_dia', 'U') IS NULL THEN 'Correcto: aun no existe flota.operacion_dia' ELSE 'Ya existe flota.operacion_dia' END),
('PRECHECK GENERAL', 'Tabla nueva flota.ReciboAlquiler aun no existe', CASE WHEN OBJECT_ID('flota.ReciboAlquiler', 'U') IS NULL THEN 'OK' ELSE 'ALERTA' END, CASE WHEN OBJECT_ID('flota.ReciboAlquiler', 'U') IS NULL THEN 'Correcto: aun no existe flota.ReciboAlquiler' ELSE 'Ya existe flota.ReciboAlquiler' END),
('PRECHECK GENERAL', 'Tabla nueva flota.PagoReciboAlquiler aun no existe', CASE WHEN OBJECT_ID('flota.PagoReciboAlquiler', 'U') IS NULL THEN 'OK' ELSE 'ALERTA' END, CASE WHEN OBJECT_ID('flota.PagoReciboAlquiler', 'U') IS NULL THEN 'Correcto: aun no existe flota.PagoReciboAlquiler' ELSE 'Ya existe flota.PagoReciboAlquiler' END),
('PRECHECK GENERAL', 'Columna flota.vehiculo.id_empresa', CASE WHEN COL_LENGTH('flota.vehiculo', 'id_empresa') IS NOT NULL THEN 'ALERTA' ELSE 'OK' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'id_empresa') IS NOT NULL THEN 'Ya existe id_empresa en flota.vehiculo' ELSE 'No existe id_empresa en flota.vehiculo' END),
('PRECHECK GENERAL', 'Columna flota.vehiculo.id_est', CASE WHEN COL_LENGTH('flota.vehiculo', 'id_est') IS NOT NULL THEN 'ALERTA' ELSE 'OK' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'id_est') IS NOT NULL THEN 'Ya existe id_est en flota.vehiculo' ELSE 'No existe id_est en flota.vehiculo' END),
('PRECHECK GENERAL', 'Columna flota.chofer.id_empresa', CASE WHEN COL_LENGTH('flota.chofer', 'id_empresa') IS NOT NULL THEN 'ALERTA' ELSE 'OK' END, CASE WHEN COL_LENGTH('flota.chofer', 'id_empresa') IS NOT NULL THEN 'Ya existe id_empresa en flota.chofer' ELSE 'No existe id_empresa en flota.chofer' END),
('PRECHECK GENERAL', 'Columna flota.chofer.id_est', CASE WHEN COL_LENGTH('flota.chofer', 'id_est') IS NOT NULL THEN 'ALERTA' ELSE 'OK' END, CASE WHEN COL_LENGTH('flota.chofer', 'id_est') IS NOT NULL THEN 'Ya existe id_est en flota.chofer' ELSE 'No existe id_est en flota.chofer' END),
('PRECHECK GENERAL', 'Columna flota.chofer.Id_Chofer', CASE WHEN COL_LENGTH('flota.chofer', 'Id_Chofer') IS NOT NULL THEN 'ALERTA' ELSE 'OK' END, CASE WHEN COL_LENGTH('flota.chofer', 'Id_Chofer') IS NOT NULL THEN 'Ya existe Id_Chofer en flota.chofer' ELSE 'No existe Id_Chofer en flota.chofer' END);

IF OBJECT_ID('flota.chofer', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('PRECHECK GENERAL', 'Cantidad filas flota.chofer', 'FALTA', 'No existe flota.chofer');
    INSERT INTO @Resultado VALUES ('PRECHECK GENERAL', 'Riesgo flota.chofer con datos sin Id_Chofer', 'FALTA', 'No existe flota.chofer');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT
        'PRECHECK GENERAL',
        'Cantidad filas flota.chofer',
        'OK',
        'Filas=' + CAST(COUNT(*) AS VARCHAR(30))
    FROM flota.chofer;

    INSERT INTO @Resultado
    SELECT
        'PRECHECK GENERAL',
        'Riesgo flota.chofer con datos sin Id_Chofer',
        CASE
            WHEN COL_LENGTH('flota.chofer', 'Id_Chofer') IS NOT NULL THEN 'OK'
            WHEN COUNT(*) > 0 THEN 'ALERTA'
            ELSE 'OK'
        END,
        CASE
            WHEN COL_LENGTH('flota.chofer', 'Id_Chofer') IS NOT NULL THEN 'Id_Chofer ya existe'
            WHEN COUNT(*) > 0 THEN 'flota.chofer tiene datos y no existe Id_Chofer; validar ALTER IDENTITY en produccion'
            ELSE 'flota.chofer sin datos; riesgo menor para agregar Id_Chofer'
        END
    FROM flota.chofer;
END;

IF OBJECT_ID('flota.vehiculo', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('PRECHECK GENERAL', 'Cantidad filas flota.vehiculo', 'FALTA', 'No existe flota.vehiculo');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT
        'PRECHECK GENERAL',
        'Cantidad filas flota.vehiculo',
        'OK',
        'Filas=' + CAST(COUNT(*) AS VARCHAR(30))
    FROM flota.vehiculo;
END;

IF OBJECT_ID('flota.vehiculo', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('PRECHECK GENERAL', 'Estructura flota.vehiculo', 'FALTA', 'No existe flota.vehiculo');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT
        'PRECHECK GENERAL',
        'Estructura flota.vehiculo',
        'INFO',
        c.COLUMN_NAME + ' | ' + c.DATA_TYPE +
        CASE
            WHEN c.CHARACTER_MAXIMUM_LENGTH IS NULL THEN ''
            ELSE '(' + CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(20)) + ')'
        END +
        ' | NULL=' + c.IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_SCHEMA = 'flota'
      AND c.TABLE_NAME = 'vehiculo'
    ORDER BY c.ORDINAL_POSITION;
END;

IF OBJECT_ID('flota.chofer', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('PRECHECK GENERAL', 'Estructura flota.chofer', 'FALTA', 'No existe flota.chofer');
    INSERT INTO @Resultado VALUES ('PRECHECK GENERAL', 'Valores actuales Cod_TipAnex / Cod_Anxo en flota.chofer', 'FALTA', 'No existe flota.chofer');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT
        'PRECHECK GENERAL',
        'Estructura flota.chofer',
        'INFO',
        c.COLUMN_NAME + ' | ' + c.DATA_TYPE +
        CASE
            WHEN c.CHARACTER_MAXIMUM_LENGTH IS NULL THEN ''
            ELSE '(' + CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(20)) + ')'
        END +
        ' | NULL=' + c.IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_SCHEMA = 'flota'
      AND c.TABLE_NAME = 'chofer'
    ORDER BY c.ORDINAL_POSITION;

    IF COL_LENGTH('flota.chofer', 'Cod_TipAnex') IS NULL OR COL_LENGTH('flota.chofer', 'Cod_Anxo') IS NULL
    BEGIN
        INSERT INTO @Resultado
        VALUES
        (
            'PRECHECK GENERAL',
            'Valores actuales Cod_TipAnex / Cod_Anxo en flota.chofer',
            'ALERTA',
            'Faltan columnas Cod_TipAnex y/o Cod_Anxo en flota.chofer'
        );
    END
    ELSE
    BEGIN
        INSERT INTO @Resultado
        SELECT
            'PRECHECK GENERAL',
            'Valores actuales Cod_TipAnex / Cod_Anxo en flota.chofer',
            'INFO',
            'Cod_TipAnex=' + ISNULL(CAST(Cod_TipAnex AS VARCHAR(50)), '(NULL)') +
            ' | Cod_Anxo=' + ISNULL(CAST(Cod_Anxo AS VARCHAR(50)), '(NULL)') +
            ' | Filas=' + CAST(COUNT(*) AS VARCHAR(20))
        FROM flota.chofer
        GROUP BY Cod_TipAnex, Cod_Anxo;
    END;
END;

SELECT Etapa, Validacion, Resultado, Detalle
FROM @Resultado
ORDER BY
    CASE Resultado WHEN 'FALTA' THEN 1 WHEN 'ALERTA' THEN 2 WHEN 'OK' THEN 3 ELSE 4 END,
    Validacion,
    Detalle;
