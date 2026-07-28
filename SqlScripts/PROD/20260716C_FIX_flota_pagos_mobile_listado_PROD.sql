SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
Fix minimo y seguro - Flota pagos mobile listado

Produccion objetivo:
- DB_9FA64E_bdgas

Motivo:
- GET /Flota/PagosContratoPorContrato falla al listar porque
  flota.p_PagoContrato_ListarPorContrato no devuelve todas las columnas
  que espera FlotaRepository.ListarPagosContratoAsync

Alcance:
- recrea SOLO flota.p_PagoContrato_ListarPorContrato
- no toca calendario
- no toca intervalos
- no toca recibos
- no toca deuda
- no toca caja/cobranza
- no aplica pagos a recibos
*/
GO

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en DB_9FA64E_bdgas.',16,1);
    SET NOEXEC ON;
END;
GO

IF SCHEMA_ID('flota') IS NULL
BEGIN
    RAISERROR('No existe schema flota.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.PagoContrato','U') IS NULL
BEGIN
    RAISERROR('No existe flota.PagoContrato.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.contrato','U') IS NULL
BEGIN
    RAISERROR('No existe flota.contrato.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.chofer','U') IS NULL
BEGIN
    RAISERROR('No existe flota.chofer.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.vehiculo','U') IS NULL
BEGIN
    RAISERROR('No existe flota.vehiculo.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('dbo.formaPago','U') IS NULL
BEGIN
    RAISERROR('No existe dbo.formaPago.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.PagoContrato','IdPagoContrato') IS NULL
    OR COL_LENGTH('flota.PagoContrato','id_empresa') IS NULL
    OR COL_LENGTH('flota.PagoContrato','id_est') IS NULL
    OR COL_LENGTH('flota.PagoContrato','Id_Contrato') IS NULL
    OR COL_LENGTH('flota.PagoContrato','Id_Chofer') IS NULL
    OR COL_LENGTH('flota.PagoContrato','Id_Vehiculo') IS NULL
    OR COL_LENGTH('flota.PagoContrato','Id_OperacionDia') IS NULL
    OR COL_LENGTH('flota.PagoContrato','FechaPago') IS NULL
    OR COL_LENGTH('flota.PagoContrato','Importe') IS NULL
    OR COL_LENGTH('flota.PagoContrato','IdFormaPago') IS NULL
    OR COL_LENGTH('flota.PagoContrato','OperacionReferencia') IS NULL
    OR COL_LENGTH('flota.PagoContrato','Observacion') IS NULL
    OR COL_LENGTH('flota.PagoContrato','FlgValidado') IS NULL
    OR COL_LENGTH('flota.PagoContrato','FlgEstado') IS NULL
    OR COL_LENGTH('flota.PagoContrato','ImporteAplicado') IS NULL
    OR COL_LENGTH('flota.PagoContrato','ImporteDisponible') IS NULL
    OR COL_LENGTH('flota.PagoContrato','Fec_Creacion') IS NULL
    OR COL_LENGTH('flota.PagoContrato','Fec_Valida') IS NULL
BEGIN
    RAISERROR('Precheck: flota.PagoContrato no tiene todas las columnas requeridas.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.contrato','Id_Contrato') IS NULL
    OR COL_LENGTH('flota.contrato','Numero') IS NULL
BEGIN
    RAISERROR('Precheck: flota.contrato no tiene las columnas requeridas.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.chofer','Id_Chofer') IS NULL
    OR COL_LENGTH('flota.chofer','Nombres') IS NULL
BEGIN
    RAISERROR('Precheck: flota.chofer no tiene las columnas requeridas.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.vehiculo','Id_Vehiculo') IS NULL
    OR COL_LENGTH('flota.vehiculo','Placa') IS NULL
BEGIN
    RAISERROR('Precheck: flota.vehiculo no tiene las columnas requeridas.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('dbo.formaPago','IdFormaPago') IS NULL
    OR COL_LENGTH('dbo.formaPago','tipo') IS NULL
BEGIN
    RAISERROR('Precheck: dbo.formaPago no tiene las columnas requeridas.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.p_PagoContrato_ListarPorContrato','P') IS NOT NULL
    DROP PROCEDURE flota.p_PagoContrato_ListarPorContrato;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE flota.p_PagoContrato_ListarPorContrato
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @FlgValidado VARCHAR(1) = NULL,
    @FlgEstado VARCHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPagoContrato,
        p.Id_Contrato,
        c.Numero AS ContratoNumero,
        p.Id_Chofer,
        ISNULL(ch.Nombres, '') AS Chofer,
        p.Id_Vehiculo,
        ISNULL(v.Placa, '') AS Placa,
        p.Id_OperacionDia,
        p.FechaPago,
        p.Importe,
        p.IdFormaPago,
        fp.tipo AS FormaPago,
        fp.tipo AS FormaPagoTexto,
        p.OperacionReferencia,
        p.Observacion,
        p.FlgValidado,
        p.FlgEstado,
        p.ImporteAplicado,
        p.ImporteDisponible,
        p.Fec_Creacion,
        p.Fec_Valida
    FROM flota.PagoContrato p
    INNER JOIN flota.contrato c
        ON c.Id_Contrato = p.Id_Contrato
       AND c.id_empresa = p.id_empresa
       AND c.id_est = p.id_est
    INNER JOIN flota.chofer ch
        ON ch.Id_Chofer = p.Id_Chofer
       AND ch.id_empresa = p.id_empresa
       AND ch.id_est = p.id_est
    INNER JOIN flota.vehiculo v
        ON v.Id_Vehiculo = p.Id_Vehiculo
       AND v.id_empresa = p.id_empresa
       AND v.id_est = p.id_est
    INNER JOIN dbo.formaPago fp
        ON fp.IdFormaPago = p.IdFormaPago
    WHERE p.id_empresa = @IdEmpresa
      AND p.id_est = @IdEst
      AND p.Id_Contrato = @IdContrato
      AND (@FlgValidado IS NULL OR p.FlgValidado = @FlgValidado)
      AND (@FlgEstado IS NULL OR p.FlgEstado = @FlgEstado)
    ORDER BY p.FechaPago DESC, p.IdPagoContrato DESC;
END;
GO

PRINT 'OK: flota.p_PagoContrato_ListarPorContrato corregido para listado mobile.';
GO
