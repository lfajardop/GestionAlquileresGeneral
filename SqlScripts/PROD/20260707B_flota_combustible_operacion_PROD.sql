SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en DB_9FA64E_bdgas.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF SCHEMA_ID('flota') IS NULL
BEGIN
    RAISERROR('No existe schema flota.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.contrato', 'U') IS NULL
   OR OBJECT_ID('flota.chofer', 'U') IS NULL
   OR OBJECT_ID('flota.vehiculo', 'U') IS NULL
   OR OBJECT_ID('flota.operacion_dia', 'U') IS NULL
   OR OBJECT_ID('flota.AdjuntoFlota', 'U') IS NULL
BEGIN
    RAISERROR('Faltan tablas base requeridas para combustible mobile.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.CombustibleOperacion', 'U') IS NULL
BEGIN
    CREATE TABLE flota.CombustibleOperacion
    (
        IdCombustibleOperacion INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_flota_CombustibleOperacion PRIMARY KEY,
        id_empresa INT NOT NULL,
        id_est CHAR(2) NOT NULL,
        Id_Contrato INT NOT NULL,
        Id_Chofer INT NOT NULL,
        Id_Vehiculo INT NOT NULL,
        Id_OperacionDia INT NULL,
        Fecha DATE NOT NULL,
        FechaRegistro DATETIME NOT NULL CONSTRAINT DF_flota_CombustibleOperacion_FechaRegistro DEFAULT(GETUTCDATE()),
        Galones DECIMAL(18,3) NOT NULL,
        Importe DECIMAL(18,2) NOT NULL,
        FlgPagoCombustible VARCHAR(1) NULL,
        Observacion VARCHAR(300) NULL,
        FlgEstado VARCHAR(1) NOT NULL CONSTRAINT DF_flota_CombustibleOperacion_FlgEstado DEFAULT('A'),
        Usu_Creacion INT NOT NULL,
        Fec_Creacion DATETIME NOT NULL CONSTRAINT DF_flota_CombustibleOperacion_FecCreacion DEFAULT(GETUTCDATE()),
        Usu_Anula INT NULL,
        Fec_Anula DATETIME NULL,
        MotivoAnula VARCHAR(250) NULL,
        CONSTRAINT FK_flota_CombustibleOperacion_Contrato FOREIGN KEY (Id_Contrato) REFERENCES flota.contrato(Id_Contrato),
        CONSTRAINT FK_flota_CombustibleOperacion_Chofer FOREIGN KEY (Id_Chofer) REFERENCES flota.chofer(Id_Chofer),
        CONSTRAINT FK_flota_CombustibleOperacion_Vehiculo FOREIGN KEY (Id_Vehiculo) REFERENCES flota.vehiculo(Id_Vehiculo),
        CONSTRAINT FK_flota_CombustibleOperacion_OperacionDia FOREIGN KEY (Id_OperacionDia) REFERENCES flota.operacion_dia(Id_OperacionDia),
        CONSTRAINT CK_flota_CombustibleOperacion_Galones CHECK (Galones > 0),
        CONSTRAINT CK_flota_CombustibleOperacion_Importe CHECK (Importe >= 0),
        CONSTRAINT CK_flota_CombustibleOperacion_FlgEstado CHECK (FlgEstado IN ('A','X')),
        CONSTRAINT CK_flota_CombustibleOperacion_FlgPagoCombustible CHECK (FlgPagoCombustible IS NULL OR FlgPagoCombustible IN ('C','D','P'))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.CombustibleOperacion') AND name = 'IX_flota_CombustibleOperacion_ContratoFechaEstado')
BEGIN
    CREATE INDEX IX_flota_CombustibleOperacion_ContratoFechaEstado
        ON flota.CombustibleOperacion(id_empresa, id_est, Id_Contrato, Fecha, FlgEstado);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.CombustibleOperacion') AND name = 'IX_flota_CombustibleOperacion_OperacionDiaEstado')
BEGIN
    CREATE INDEX IX_flota_CombustibleOperacion_OperacionDiaEstado
        ON flota.CombustibleOperacion(id_empresa, id_est, Id_OperacionDia, FlgEstado);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.CombustibleOperacion') AND name = 'IX_flota_CombustibleOperacion_ChoferFecha')
BEGIN
    CREATE INDEX IX_flota_CombustibleOperacion_ChoferFecha
        ON flota.CombustibleOperacion(id_empresa, id_est, Id_Chofer, Fecha);
END;
GO

DECLARE @CheckTipoEntidad SYSNAME;
DECLARE @SqlDropCheck NVARCHAR(400);
SELECT TOP (1) @CheckTipoEntidad = cc.name
FROM sys.check_constraints cc
WHERE cc.parent_object_id = OBJECT_ID('flota.AdjuntoFlota')
  AND cc.definition LIKE '%TipoEntidad%';

IF @CheckTipoEntidad IS NOT NULL
BEGIN
    SET @SqlDropCheck = N'ALTER TABLE flota.AdjuntoFlota DROP CONSTRAINT ' + QUOTENAME(@CheckTipoEntidad) + N';';
    EXEC(@SqlDropCheck);
END;
GO

ALTER TABLE flota.AdjuntoFlota
ADD CONSTRAINT CK_flota_AdjuntoFlota_TipoEntidad
CHECK (TipoEntidad IN ('OPERACION_DIA', 'PAGO_CONTRATO', 'RECIBO', 'COMBUSTIBLE'));
GO

IF OBJECT_ID('flota.p_AdjuntoFlota_Registrar', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_AdjuntoFlota_Registrar AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_AdjuntoFlota_Registrar
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @TipoEntidad VARCHAR(20),
    @IdEntidad INT,
    @TipoAdjunto VARCHAR(20),
    @RutaArchivo VARCHAR(300),
    @NombreOriginal VARCHAR(255) = NULL,
    @MimeType VARCHAR(100) = NULL,
    @TamanoBytes BIGINT = NULL,
    @Observacion VARCHAR(300) = NULL,
    @Usuario INT,
    @IdAdjunto INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InicioTran BIT = 0;
    DECLARE @SaveName VARCHAR(32) = 'AdjFlotaRegistrar';

    SET @IdAdjunto = 0;
    SET @Mensaje = '';

    IF @TipoEntidad NOT IN ('OPERACION_DIA', 'PAGO_CONTRATO', 'RECIBO', 'COMBUSTIBLE')
    BEGIN
        SET @Mensaje = 'TipoEntidad invalido.';
        RETURN;
    END;

    IF @TipoAdjunto NOT IN ('RECIBO_GLP', 'VOUCHER_PAGO', 'OTRO')
    BEGIN
        SET @Mensaje = 'TipoAdjunto invalido.';
        RETURN;
    END;

    IF @IdEntidad <= 0
    BEGIN
        SET @Mensaje = 'IdEntidad invalido.';
        RETURN;
    END;

    IF LTRIM(RTRIM(ISNULL(@RutaArchivo, ''))) = ''
    BEGIN
        SET @Mensaje = 'RutaArchivo es obligatoria.';
        RETURN;
    END;

    IF @TamanoBytes IS NOT NULL AND @TamanoBytes < 0
    BEGIN
        SET @Mensaje = 'TamanoBytes invalido.';
        RETURN;
    END;

    IF @TipoEntidad = 'OPERACION_DIA'
       AND NOT EXISTS
       (
           SELECT 1
           FROM flota.operacion_dia
           WHERE Id_OperacionDia = @IdEntidad
             AND id_empresa = @IdEmpresa
             AND id_est = @IdEst
       )
    BEGIN
        SET @Mensaje = 'Operacion del dia no encontrada.';
        RETURN;
    END;

    IF @TipoEntidad = 'PAGO_CONTRATO'
       AND NOT EXISTS
       (
           SELECT 1
           FROM flota.PagoContrato
           WHERE IdPagoContrato = @IdEntidad
             AND id_empresa = @IdEmpresa
             AND id_est = @IdEst
             AND FlgEstado = 'A'
       )
    BEGIN
        SET @Mensaje = 'PagoContrato no encontrado.';
        RETURN;
    END;

    IF @TipoEntidad = 'RECIBO'
       AND NOT EXISTS
       (
           SELECT 1
           FROM flota.ReciboAlquiler
           WHERE Id_ReciboAlquiler = @IdEntidad
             AND id_empresa = @IdEmpresa
             AND id_est = @IdEst
       )
    BEGIN
        SET @Mensaje = 'Recibo no encontrado.';
        RETURN;
    END;

    IF @TipoEntidad = 'COMBUSTIBLE'
       AND NOT EXISTS
       (
           SELECT 1
           FROM flota.CombustibleOperacion
           WHERE IdCombustibleOperacion = @IdEntidad
             AND id_empresa = @IdEmpresa
             AND id_est = @IdEst
             AND FlgEstado = 'A'
       )
    BEGIN
        SET @Mensaje = 'Combustible no encontrado.';
        RETURN;
    END;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            SET @InicioTran = 1;
            BEGIN TRANSACTION;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION @SaveName;
        END;

        INSERT INTO flota.AdjuntoFlota
        (
            id_empresa, id_est, TipoEntidad, IdEntidad, TipoAdjunto,
            RutaArchivo, NombreOriginal, MimeType, TamanoBytes, Observacion,
            FlgEstado, Usu_Creacion, Fec_Creacion
        )
        VALUES
        (
            @IdEmpresa, @IdEst, @TipoEntidad, @IdEntidad, @TipoAdjunto,
            @RutaArchivo, @NombreOriginal, @MimeType, @TamanoBytes, @Observacion,
            'A', @Usuario, GETUTCDATE()
        );

        SET @IdAdjunto = SCOPE_IDENTITY();
        SET @Mensaje = 'Adjunto registrado correctamente.';

        IF @InicioTran = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION @SaveName;
        END;
        SET @IdAdjunto = 0;
        SET @Mensaje = ERROR_MESSAGE();
        RETURN;
    END CATCH;
END
GO

IF OBJECT_ID('flota.p_CombustibleOperacion_Registrar', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_CombustibleOperacion_Registrar AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_CombustibleOperacion_Registrar
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @IdChofer INT,
    @IdVehiculo INT,
    @Fecha DATE,
    @IdOperacionDia INT = NULL,
    @Galones DECIMAL(18,3),
    @Importe DECIMAL(18,2),
    @FlgPagoCombustible VARCHAR(1) = NULL,
    @Observacion VARCHAR(300) = NULL,
    @Usuario INT,
    @IdCombustibleOperacion INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InicioTran BIT = 0;
    DECLARE @SaveName VARCHAR(32) = 'CombustibleReg';
    DECLARE @ContratoChofer INT;
    DECLARE @ContratoVehiculo INT;
    DECLARE @ContratoEstado VARCHAR(1);
    DECLARE @OpContrato INT;
    DECLARE @OpFecha DATE;

    SET @IdCombustibleOperacion = 0;
    SET @Mensaje = '';
    SET @FlgPagoCombustible = NULLIF(UPPER(LTRIM(RTRIM(ISNULL(@FlgPagoCombustible, '')))), '');
    SET @Observacion = NULLIF(LTRIM(RTRIM(ISNULL(@Observacion, ''))), '');

    IF @IdContrato <= 0
    BEGIN
        SET @Mensaje = 'Contrato invalido.';
        RETURN;
    END;

    IF @IdChofer <= 0
    BEGIN
        SET @Mensaje = 'Chofer invalido.';
        RETURN;
    END;

    IF @IdVehiculo <= 0
    BEGIN
        SET @Mensaje = 'Vehiculo invalido.';
        RETURN;
    END;

    IF @Galones <= 0
    BEGIN
        SET @Mensaje = 'Galones debe ser mayor que cero.';
        RETURN;
    END;

    IF @Importe < 0
    BEGIN
        SET @Mensaje = 'Importe invalido.';
        RETURN;
    END;

    IF @FlgPagoCombustible IS NOT NULL AND @FlgPagoCombustible NOT IN ('C', 'D', 'P')
    BEGIN
        SET @Mensaje = 'FlgPagoCombustible invalido. Usa C, D o P.';
        RETURN;
    END;

    SELECT
        @ContratoChofer = c.Id_Chofer,
        @ContratoVehiculo = c.Id_Vehiculo,
        @ContratoEstado = c.Flg_Estado
    FROM flota.contrato c
    WHERE c.Id_Contrato = @IdContrato
      AND c.id_empresa = @IdEmpresa
      AND c.id_est = @IdEst;

    IF @ContratoChofer IS NULL
    BEGIN
        SET @Mensaje = 'Contrato no encontrado.';
        RETURN;
    END;

    IF @ContratoEstado <> 'A'
    BEGIN
        SET @Mensaje = 'El contrato no esta activo.';
        RETURN;
    END;

    IF @ContratoChofer <> @IdChofer
    BEGIN
        SET @Mensaje = 'El chofer no corresponde al contrato.';
        RETURN;
    END;

    IF @ContratoVehiculo <> @IdVehiculo
    BEGIN
        SET @Mensaje = 'El vehiculo no corresponde al contrato.';
        RETURN;
    END;

    IF @IdOperacionDia IS NOT NULL
    BEGIN
        SELECT
            @OpContrato = od.Id_Contrato,
            @OpFecha = od.Fecha
        FROM flota.operacion_dia od
        WHERE od.Id_OperacionDia = @IdOperacionDia
          AND od.id_empresa = @IdEmpresa
          AND od.id_est = @IdEst;

        IF @OpContrato IS NULL
        BEGIN
            SET @Mensaje = 'Operacion del dia no encontrada.';
            RETURN;
        END;

        IF @OpContrato <> @IdContrato
        BEGIN
            SET @Mensaje = 'La operacion del dia no corresponde al contrato.';
            RETURN;
        END;

        IF @OpFecha <> @Fecha
        BEGIN
            SET @Mensaje = 'La fecha de combustible no coincide con la operacion del dia.';
            RETURN;
        END;
    END;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            SET @InicioTran = 1;
            BEGIN TRANSACTION;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION @SaveName;
        END;

        INSERT INTO flota.CombustibleOperacion
        (
            id_empresa, id_est, Id_Contrato, Id_Chofer, Id_Vehiculo, Id_OperacionDia,
            Fecha, FechaRegistro, Galones, Importe, FlgPagoCombustible, Observacion,
            FlgEstado, Usu_Creacion, Fec_Creacion
        )
        VALUES
        (
            @IdEmpresa, @IdEst, @IdContrato, @IdChofer, @IdVehiculo, @IdOperacionDia,
            @Fecha, GETUTCDATE(), @Galones, @Importe, @FlgPagoCombustible, @Observacion,
            'A', @Usuario, GETUTCDATE()
        );

        SET @IdCombustibleOperacion = SCOPE_IDENTITY();
        SET @Mensaje = 'Carga de combustible registrada correctamente.';

        IF @InicioTran = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION @SaveName;
        END;
        SET @IdCombustibleOperacion = 0;
        SET @Mensaje = ERROR_MESSAGE();
        RETURN;
    END CATCH;
END
GO

IF OBJECT_ID('flota.p_CombustibleOperacion_ListarPorContratoFecha', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_CombustibleOperacion_ListarPorContratoFecha AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_CombustibleOperacion_ListarPorContratoFecha
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @Fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.IdCombustibleOperacion,
        c.Id_Contrato,
        c.Id_Chofer,
        c.Id_Vehiculo,
        c.Id_OperacionDia,
        c.Fecha,
        c.FechaRegistro,
        c.Galones,
        c.Importe,
        c.FlgPagoCombustible,
        c.Observacion,
        c.FlgEstado,
        c.Fec_Creacion,
        ISNULL(ch.Nombres, ch.Cod_TipAnex + '-' + ch.Cod_Anxo) AS Chofer,
        v.Placa
    FROM flota.CombustibleOperacion c
    INNER JOIN flota.chofer ch ON ch.Id_Chofer = c.Id_Chofer
    INNER JOIN flota.vehiculo v ON v.Id_Vehiculo = c.Id_Vehiculo
    WHERE c.id_empresa = @IdEmpresa
      AND c.id_est = @IdEst
      AND c.Id_Contrato = @IdContrato
      AND c.Fecha = @Fecha
      AND c.FlgEstado = 'A'
    ORDER BY c.FechaRegistro DESC, c.IdCombustibleOperacion DESC;

    SELECT
        ISNULL(SUM(c.Galones), 0) AS TotalGalones,
        ISNULL(SUM(c.Importe), 0) AS TotalImporte,
        COUNT(1) AS TotalCargas
    FROM flota.CombustibleOperacion c
    WHERE c.id_empresa = @IdEmpresa
      AND c.id_est = @IdEst
      AND c.Id_Contrato = @IdContrato
      AND c.Fecha = @Fecha
      AND c.FlgEstado = 'A';
END
GO

IF OBJECT_ID('flota.p_CombustibleOperacion_Anular', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_CombustibleOperacion_Anular AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_CombustibleOperacion_Anular
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdCombustibleOperacion INT,
    @Motivo VARCHAR(250),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InicioTran BIT = 0;
    DECLARE @SaveName VARCHAR(32) = 'CombustibleAnu';

    SET @Mensaje = '';
    SET @Motivo = LTRIM(RTRIM(ISNULL(@Motivo, '')));

    IF @IdCombustibleOperacion <= 0
    BEGIN
        SET @Mensaje = 'IdCombustibleOperacion invalido.';
        RETURN;
    END;

    IF @Motivo = ''
    BEGIN
        SET @Mensaje = 'Motivo obligatorio.';
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.CombustibleOperacion
        WHERE IdCombustibleOperacion = @IdCombustibleOperacion
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
          AND FlgEstado = 'A'
    )
    BEGIN
        SET @Mensaje = 'Carga de combustible no encontrada.';
        RETURN;
    END;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            SET @InicioTran = 1;
            BEGIN TRANSACTION;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION @SaveName;
        END;

        UPDATE flota.CombustibleOperacion
        SET FlgEstado = 'X',
            Usu_Anula = @Usuario,
            Fec_Anula = GETUTCDATE(),
            MotivoAnula = @Motivo
        WHERE IdCombustibleOperacion = @IdCombustibleOperacion
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
          AND FlgEstado = 'A';

        SET @Mensaje = 'Carga de combustible anulada correctamente.';

        IF @InicioTran = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION @SaveName;
        END;
        SET @Mensaje = ERROR_MESSAGE();
        RETURN;
    END CATCH;
END
GO

SELECT
    OBJECT_ID('flota.CombustibleOperacion', 'U') AS TablaCombustibleOperacion,
    OBJECT_ID('flota.p_CombustibleOperacion_Registrar', 'P') AS SpRegistrar,
    OBJECT_ID('flota.p_CombustibleOperacion_ListarPorContratoFecha', 'P') AS SpListar,
    OBJECT_ID('flota.p_CombustibleOperacion_Anular', 'P') AS SpAnular;
GO

