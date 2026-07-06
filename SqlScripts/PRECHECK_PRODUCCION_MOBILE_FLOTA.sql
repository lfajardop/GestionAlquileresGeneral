SET NOCOUNT ON;

DECLARE @Resultado TABLE
(
    Etapa VARCHAR(50),
    Validacion VARCHAR(200),
    Resultado VARCHAR(20),
    Detalle VARCHAR(500)
);

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'DB_NAME()', CASE WHEN DB_NAME() = 'DB_9FA64E_bdgas' THEN 'OK' ELSE 'ALERTA' END,
       'Base actual: ' + DB_NAME();

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Version SQL Server', 'OK', CAST(@@VERSION AS VARCHAR(500));

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Schema flota',
       CASE WHEN EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'flota') THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'flota') THEN 'Existe schema flota.' ELSE 'No existe schema flota.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla flota.contrato',
       CASE WHEN OBJECT_ID('flota.contrato', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.contrato', 'U') IS NOT NULL THEN 'Existe flota.contrato.' ELSE 'No existe flota.contrato.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla flota.operacion_dia',
       CASE WHEN OBJECT_ID('flota.operacion_dia', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.operacion_dia', 'U') IS NOT NULL THEN 'Existe flota.operacion_dia.' ELSE 'No existe flota.operacion_dia.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla flota.vehiculo',
       CASE WHEN OBJECT_ID('flota.vehiculo', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.vehiculo', 'U') IS NOT NULL THEN 'Existe flota.vehiculo.' ELSE 'No existe flota.vehiculo.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla flota.chofer',
       CASE WHEN OBJECT_ID('flota.chofer', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.chofer', 'U') IS NOT NULL THEN 'Existe flota.chofer.' ELSE 'No existe flota.chofer.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla flota.ReciboAlquiler',
       CASE WHEN OBJECT_ID('flota.ReciboAlquiler', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.ReciboAlquiler', 'U') IS NOT NULL THEN 'Existe flota.ReciboAlquiler.' ELSE 'No existe flota.ReciboAlquiler.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla flota.PagoReciboAlquiler',
       CASE WHEN OBJECT_ID('flota.PagoReciboAlquiler', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.PagoReciboAlquiler', 'U') IS NOT NULL THEN 'Existe flota.PagoReciboAlquiler.' ELSE 'No existe flota.PagoReciboAlquiler.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla dbo.formaPago',
       CASE WHEN OBJECT_ID('dbo.formaPago', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('dbo.formaPago', 'U') IS NOT NULL THEN 'Existe dbo.formaPago.' ELSE 'No existe dbo.formaPago.' END;

IF OBJECT_ID('dbo.formaPago', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('PRECHECK MOBILE', 'FormaPago activa 1', 'FALTA', 'No existe dbo.formaPago.');
    INSERT INTO @Resultado VALUES ('PRECHECK MOBILE', 'FormaPago activa 3', 'FALTA', 'No existe dbo.formaPago.');
    INSERT INTO @Resultado VALUES ('PRECHECK MOBILE', 'FormaPago activa 5', 'FALTA', 'No existe dbo.formaPago.');
    INSERT INTO @Resultado VALUES ('PRECHECK MOBILE', 'FormaPago activa 6', 'FALTA', 'No existe dbo.formaPago.');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT 'PRECHECK MOBILE', 'FormaPago activa 1',
           CASE WHEN EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 1 AND ISNULL(Estado,0) = 1) THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 1 AND ISNULL(Estado,0) = 1) THEN 'Existe IdFormaPago 1 activo.' ELSE 'Falta IdFormaPago 1 activo.' END;

    INSERT INTO @Resultado
    SELECT 'PRECHECK MOBILE', 'FormaPago activa 3',
           CASE WHEN EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 3 AND ISNULL(Estado,0) = 1) THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 3 AND ISNULL(Estado,0) = 1) THEN 'Existe IdFormaPago 3 activo.' ELSE 'Falta IdFormaPago 3 activo.' END;

    INSERT INTO @Resultado
    SELECT 'PRECHECK MOBILE', 'FormaPago activa 5',
           CASE WHEN EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 5 AND ISNULL(Estado,0) = 1) THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 5 AND ISNULL(Estado,0) = 1) THEN 'Existe IdFormaPago 5 activo.' ELSE 'Falta IdFormaPago 5 activo.' END;

    INSERT INTO @Resultado
    SELECT 'PRECHECK MOBILE', 'FormaPago activa 6',
           CASE WHEN EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 6 AND ISNULL(Estado,0) = 1) THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 6 AND ISNULL(Estado,0) = 1) THEN 'Existe IdFormaPago 6 activo.' ELSE 'Falta IdFormaPago 6 activo.' END;
END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla flota.AdjuntoFlota',
       CASE WHEN OBJECT_ID('flota.AdjuntoFlota', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.AdjuntoFlota', 'U') IS NOT NULL THEN 'Existe flota.AdjuntoFlota.' ELSE 'No existe flota.AdjuntoFlota.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla flota.PagoContrato',
       CASE WHEN OBJECT_ID('flota.PagoContrato', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.PagoContrato', 'U') IS NOT NULL THEN 'Existe flota.PagoContrato.' ELSE 'No existe flota.PagoContrato.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla flota.UsuarioMobile',
       CASE WHEN OBJECT_ID('flota.UsuarioMobile', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.UsuarioMobile', 'U') IS NOT NULL THEN 'Existe flota.UsuarioMobile.' ELSE 'No existe flota.UsuarioMobile.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Tabla flota.CombustibleOperacion',
       CASE WHEN OBJECT_ID('flota.CombustibleOperacion', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.CombustibleOperacion', 'U') IS NOT NULL THEN 'Existe flota.CombustibleOperacion.' ELSE 'No existe flota.CombustibleOperacion.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Columna operacion_dia.FechaHoraInicio',
       CASE WHEN COL_LENGTH('flota.operacion_dia', 'FechaHoraInicio') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN COL_LENGTH('flota.operacion_dia', 'FechaHoraInicio') IS NOT NULL THEN 'Existe FechaHoraInicio.' ELSE 'Falta FechaHoraInicio.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Columna operacion_dia.FechaHoraFin',
       CASE WHEN COL_LENGTH('flota.operacion_dia', 'FechaHoraFin') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN COL_LENGTH('flota.operacion_dia', 'FechaHoraFin') IS NOT NULL THEN 'Existe FechaHoraFin.' ELSE 'Falta FechaHoraFin.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Columna PagoContrato.Usu_Modif',
       CASE WHEN COL_LENGTH('flota.PagoContrato', 'Usu_Modif') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN COL_LENGTH('flota.PagoContrato', 'Usu_Modif') IS NOT NULL THEN 'Existe Usu_Modif.' ELSE 'Falta Usu_Modif.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'Columna PagoContrato.Fec_Modif',
       CASE WHEN COL_LENGTH('flota.PagoContrato', 'Fec_Modif') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN COL_LENGTH('flota.PagoContrato', 'Fec_Modif') IS NOT NULL THEN 'Existe Fec_Modif.' ELSE 'Falta Fec_Modif.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'SP flota.p_PagoContrato_EditarMobile',
       CASE WHEN OBJECT_ID('flota.p_PagoContrato_EditarMobile', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.p_PagoContrato_EditarMobile', 'P') IS NOT NULL THEN 'Existe SP flota.p_PagoContrato_EditarMobile.' ELSE 'Falta SP flota.p_PagoContrato_EditarMobile.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'SP flota.p_UsuarioMobile_Login',
       CASE WHEN OBJECT_ID('flota.p_UsuarioMobile_Login', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.p_UsuarioMobile_Login', 'P') IS NOT NULL THEN 'Existe SP flota.p_UsuarioMobile_Login.' ELSE 'Falta SP flota.p_UsuarioMobile_Login.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'SP flota.p_UsuarioMobile_RegistrarTemporal',
       CASE WHEN OBJECT_ID('flota.p_UsuarioMobile_RegistrarTemporal', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.p_UsuarioMobile_RegistrarTemporal', 'P') IS NOT NULL THEN 'Existe SP flota.p_UsuarioMobile_RegistrarTemporal.' ELSE 'Falta SP flota.p_UsuarioMobile_RegistrarTemporal.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'SP flota.p_CombustibleOperacion_Registrar',
       CASE WHEN OBJECT_ID('flota.p_CombustibleOperacion_Registrar', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.p_CombustibleOperacion_Registrar', 'P') IS NOT NULL THEN 'Existe SP flota.p_CombustibleOperacion_Registrar.' ELSE 'Falta SP flota.p_CombustibleOperacion_Registrar.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'SP flota.p_CombustibleOperacion_ListarPorContratoFecha',
       CASE WHEN OBJECT_ID('flota.p_CombustibleOperacion_ListarPorContratoFecha', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.p_CombustibleOperacion_ListarPorContratoFecha', 'P') IS NOT NULL THEN 'Existe SP flota.p_CombustibleOperacion_ListarPorContratoFecha.' ELSE 'Falta SP flota.p_CombustibleOperacion_ListarPorContratoFecha.' END;

INSERT INTO @Resultado
SELECT 'PRECHECK MOBILE', 'SP flota.p_CombustibleOperacion_Anular',
       CASE WHEN OBJECT_ID('flota.p_CombustibleOperacion_Anular', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END,
       CASE WHEN OBJECT_ID('flota.p_CombustibleOperacion_Anular', 'P') IS NOT NULL THEN 'Existe SP flota.p_CombustibleOperacion_Anular.' ELSE 'Falta SP flota.p_CombustibleOperacion_Anular.' END;

SELECT Etapa, Validacion, Resultado, Detalle
FROM @Resultado
ORDER BY
    CASE Resultado WHEN 'ALERTA' THEN 1 WHEN 'FALTA' THEN 2 ELSE 3 END,
    Validacion;
