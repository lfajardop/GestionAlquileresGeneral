SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
Etapa 2.1 - Flota mobile captura y validacion

Alcance:
- Crear flota.AdjuntoFlota
- Crear flota.PagoContrato
- Crear SP de adjuntos
- Crear SP de PagoContrato
- Crear SP mobile de operacion_dia

No incluye todavia:
- flota.PagoContratoAplicacion
- flota.p_PagoContrato_AplicarARecibo
- flota.p_PagoContrato_Aplicaciones_Listar

Deuda tecnica:
- PagoContrato queda como saldo validado disponible del contrato.
- Todavia no se aplica a ReciboAlquiler.
- PagoReciboAlquiler sigue usando MedioPago VARCHAR(2) como legado.
- Futura etapa: migrar PagoReciboAlquiler a IdFormaPago usando dbo.formaPago
  y recien despues aplicar PagoContrato a recibos.

Seguridad de ejecucion:
- Ejecutar preferentemente con sqlcmd -b
- O en SSMS con SQLCMD Mode y :ON ERROR EXIT
- Este script usa SET NOEXEC ON ante prevalidaciones criticas para evitar
  que continÃºe creando objetos si la base no cumple los requisitos.
*/
GO

/*==============================================================
  BLOQUE 0 - PREVALIDACIONES
==============================================================*/
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

IF OBJECT_ID('flota.operacion_dia', 'U') IS NULL
BEGIN
    RAISERROR('No existe flota.operacion_dia.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.contrato', 'U') IS NULL
BEGIN
    RAISERROR('No existe flota.contrato.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.vehiculo', 'U') IS NULL
BEGIN
    RAISERROR('No existe flota.vehiculo.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.chofer', 'U') IS NULL
BEGIN
    RAISERROR('No existe flota.chofer.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.ReciboAlquiler', 'U') IS NULL
BEGIN
    RAISERROR('No existe flota.ReciboAlquiler.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.PagoReciboAlquiler', 'U') IS NULL
BEGIN
    RAISERROR('No existe flota.PagoReciboAlquiler.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('dbo.formaPago', 'U') IS NULL
BEGIN
    RAISERROR('No existe dbo.formaPago.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.operacion_dia', 'KmInicial') IS NULL
    OR COL_LENGTH('flota.operacion_dia', 'KmFinal') IS NULL
    OR COL_LENGTH('flota.operacion_dia', 'GalonesCargados') IS NULL
    OR COL_LENGTH('flota.operacion_dia', 'ImporteCombustible') IS NULL
    OR COL_LENGTH('flota.operacion_dia', 'Observacion') IS NULL
BEGIN
    RAISERROR('Faltan columnas necesarias en flota.operacion_dia.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 1 AND ISNULL(Estado, 0) = 1)
BEGIN
    RAISERROR('No existe dbo.formaPago activo para IdFormaPago=1.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 3 AND ISNULL(Estado, 0) = 1)
BEGIN
    RAISERROR('No existe dbo.formaPago activo para IdFormaPago=3.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 5 AND ISNULL(Estado, 0) = 1)
BEGIN
    RAISERROR('No existe dbo.formaPago activo para IdFormaPago=5.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.formaPago WHERE IdFormaPago = 6 AND ISNULL(Estado, 0) = 1)
BEGIN
    RAISERROR('No existe dbo.formaPago activo para IdFormaPago=6.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.AdjuntoFlota', 'U') IS NOT NULL
BEGIN
    RAISERROR('Ya existe flota.AdjuntoFlota. Revisar antes de reaplicar.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.PagoContrato', 'U') IS NOT NULL
BEGIN
    RAISERROR('Ya existe flota.PagoContrato. Revisar antes de reaplicar.', 16, 1);
    SET NOEXEC ON;
END;
GO

/*==============================================================
  BLOQUE 1 - TABLA flota.AdjuntoFlota
==============================================================*/
CREATE TABLE flota.AdjuntoFlota
(
    IdAdjunto INT IDENTITY(1,1) NOT NULL,
    id_empresa INT NOT NULL,
    id_est CHAR(2) NOT NULL,
    TipoEntidad VARCHAR(20) NOT NULL,
    IdEntidad INT NOT NULL,
    TipoAdjunto VARCHAR(20) NOT NULL,
    RutaArchivo VARCHAR(300) NOT NULL,
    NombreOriginal VARCHAR(255) NULL,
    MimeType VARCHAR(100) NULL,
    TamanoBytes BIGINT NULL,
    Observacion VARCHAR(300) NULL,
    FlgEstado VARCHAR(1) NOT NULL CONSTRAINT DF_flota_AdjuntoFlota_FlgEstado DEFAULT('A'),
    Usu_Creacion INT NOT NULL,
    Fec_Creacion DATETIME NOT NULL CONSTRAINT DF_flota_AdjuntoFlota_FecCreacion DEFAULT(GETUTCDATE()),
    Usu_Anula INT NULL,
    Fec_Anula DATETIME NULL,
    MotivoAnula VARCHAR(250) NULL,
    CONSTRAINT PK_flota_AdjuntoFlota PRIMARY KEY (IdAdjunto),
    CONSTRAINT CK_flota_AdjuntoFlota_TipoEntidad CHECK (TipoEntidad IN ('OPERACION_DIA', 'PAGO_CONTRATO', 'RECIBO')),
    CONSTRAINT CK_flota_AdjuntoFlota_TipoAdjunto CHECK (TipoAdjunto IN ('RECIBO_GLP', 'VOUCHER_PAGO', 'OTRO')),
    CONSTRAINT CK_flota_AdjuntoFlota_FlgEstado CHECK (FlgEstado IN ('A', 'X')),
    CONSTRAINT CK_flota_AdjuntoFlota_Tamano CHECK (TamanoBytes IS NULL OR TamanoBytes >= 0)
);
GO

/*==============================================================
  BLOQUE 2 - TABLA flota.PagoContrato
==============================================================*/
CREATE TABLE flota.PagoContrato
(
    IdPagoContrato INT IDENTITY(1,1) NOT NULL,
    id_empresa INT NOT NULL,
    id_est CHAR(2) NOT NULL,
    Id_Contrato INT NOT NULL,
    Id_Chofer INT NOT NULL,
    Id_Vehiculo INT NOT NULL,
    Id_OperacionDia INT NULL,
    FechaPago DATETIME NOT NULL,
    Importe DECIMAL(18,2) NOT NULL,
    IdFormaPago INT NOT NULL,
    OperacionReferencia VARCHAR(100) NULL,
    Observacion VARCHAR(300) NULL,
    FlgValidado VARCHAR(1) NOT NULL CONSTRAINT DF_flota_PagoContrato_FlgValidado DEFAULT('N'),
    FlgEstado VARCHAR(1) NOT NULL CONSTRAINT DF_flota_PagoContrato_FlgEstado DEFAULT('A'),
    ImporteAplicado DECIMAL(18,2) NOT NULL CONSTRAINT DF_flota_PagoContrato_ImporteAplicado DEFAULT(0),
    ImporteDisponible DECIMAL(18,2) NOT NULL,
    Usu_Creacion INT NOT NULL,
    Fec_Creacion DATETIME NOT NULL CONSTRAINT DF_flota_PagoContrato_FecCreacion DEFAULT(GETUTCDATE()),
    Usu_Valida INT NULL,
    Fec_Valida DATETIME NULL,
    MotivoValidacion VARCHAR(250) NULL,
    Usu_Anula INT NULL,
    Fec_Anula DATETIME NULL,
    MotivoAnula VARCHAR(250) NULL,
    CONSTRAINT PK_flota_PagoContrato PRIMARY KEY (IdPagoContrato),
    CONSTRAINT FK_flota_PagoContrato_Contrato FOREIGN KEY (Id_Contrato) REFERENCES flota.contrato(Id_Contrato),
    CONSTRAINT FK_flota_PagoContrato_Chofer FOREIGN KEY (Id_Chofer) REFERENCES flota.chofer(Id_Chofer),
    CONSTRAINT FK_flota_PagoContrato_Vehiculo FOREIGN KEY (Id_Vehiculo) REFERENCES flota.vehiculo(Id_Vehiculo),
    CONSTRAINT FK_flota_PagoContrato_OperacionDia FOREIGN KEY (Id_OperacionDia) REFERENCES flota.operacion_dia(Id_OperacionDia),
    CONSTRAINT FK_flota_PagoContrato_FormaPago FOREIGN KEY (IdFormaPago) REFERENCES dbo.formaPago(IdFormaPago),
    CONSTRAINT CK_flota_PagoContrato_Importe CHECK (Importe > 0),
    CONSTRAINT CK_flota_PagoContrato_Aplicado CHECK (ImporteAplicado >= 0 AND ImporteAplicado <= Importe),
    CONSTRAINT CK_flota_PagoContrato_Disponible CHECK (ImporteDisponible >= 0 AND ImporteDisponible <= Importe),
    CONSTRAINT CK_flota_PagoContrato_SumaImportes CHECK (ImporteAplicado + ImporteDisponible = Importe),
    CONSTRAINT CK_flota_PagoContrato_FlgValidado CHECK (FlgValidado IN ('S', 'N')),
    CONSTRAINT CK_flota_PagoContrato_FlgEstado CHECK (FlgEstado IN ('A', 'X'))
);
GO

/*==============================================================
  BLOQUE 3 - INDICES
==============================================================*/
CREATE INDEX IX_flota_AdjuntoFlota_Entidad
    ON flota.AdjuntoFlota(id_empresa, id_est, TipoEntidad, IdEntidad, FlgEstado);
GO

CREATE INDEX IX_flota_AdjuntoFlota_Tipo
    ON flota.AdjuntoFlota(TipoAdjunto, FlgEstado);
GO

CREATE INDEX IX_flota_PagoContrato_ContratoEstado
    ON flota.PagoContrato(id_empresa, id_est, Id_Contrato, FlgEstado, FlgValidado, FechaPago);
GO

CREATE INDEX IX_flota_PagoContrato_OperacionDia
    ON flota.PagoContrato(id_empresa, id_est, Id_OperacionDia, FlgEstado);
GO

CREATE INDEX IX_flota_PagoContrato_Disponible
    ON flota.PagoContrato(id_empresa, id_est, Id_Contrato, FlgEstado, FlgValidado, ImporteDisponible);
GO

CREATE INDEX IX_flota_PagoContrato_ChoferFecha
    ON flota.PagoContrato(id_empresa, id_est, Id_Chofer, FechaPago);
GO

/*==============================================================
  BLOQUE 4 - SP ADJUNTOS
==============================================================*/
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

    IF @TipoEntidad NOT IN ('OPERACION_DIA', 'PAGO_CONTRATO', 'RECIBO')
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

IF OBJECT_ID('flota.p_AdjuntoFlota_ListarPorEntidad', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_AdjuntoFlota_ListarPorEntidad AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_AdjuntoFlota_ListarPorEntidad
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @TipoEntidad VARCHAR(20),
    @IdEntidad INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdAdjunto,
        id_empresa,
        id_est,
        TipoEntidad,
        IdEntidad,
        TipoAdjunto,
        RutaArchivo,
        NombreOriginal,
        MimeType,
        TamanoBytes,
        Observacion,
        FlgEstado,
        Usu_Creacion,
        Fec_Creacion,
        Usu_Anula,
        Fec_Anula,
        MotivoAnula
    FROM flota.AdjuntoFlota
    WHERE id_empresa = @IdEmpresa
      AND id_est = @IdEst
      AND TipoEntidad = @TipoEntidad
      AND IdEntidad = @IdEntidad
      AND FlgEstado = 'A'
    ORDER BY Fec_Creacion DESC, IdAdjunto DESC;
END
GO

IF OBJECT_ID('flota.p_AdjuntoFlota_Anular', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_AdjuntoFlota_Anular AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_AdjuntoFlota_Anular
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdAdjunto INT,
    @Motivo VARCHAR(250),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InicioTran BIT = 0;
    DECLARE @SaveName VARCHAR(32) = 'AdjFlotaAnular';

    SET @Mensaje = '';

    IF @IdAdjunto <= 0
    BEGIN
        SET @Mensaje = 'IdAdjunto invalido.';
        RETURN;
    END;

    IF LTRIM(RTRIM(ISNULL(@Motivo, ''))) = ''
    BEGIN
        SET @Mensaje = 'Motivo obligatorio.';
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.AdjuntoFlota
        WHERE IdAdjunto = @IdAdjunto
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
          AND FlgEstado = 'A'
    )
    BEGIN
        SET @Mensaje = 'Adjunto no encontrado.';
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

        UPDATE flota.AdjuntoFlota
        SET FlgEstado = 'X',
            Usu_Anula = @Usuario,
            Fec_Anula = GETUTCDATE(),
            MotivoAnula = @Motivo
        WHERE IdAdjunto = @IdAdjunto
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
          AND FlgEstado = 'A';

        SET @Mensaje = 'Adjunto anulado correctamente.';

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

/*==============================================================
  BLOQUE 5 - SP PAGOCONTRATO
==============================================================*/
IF OBJECT_ID('flota.p_PagoContrato_Registrar', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_PagoContrato_Registrar AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_PagoContrato_Registrar
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @IdChofer INT,
    @IdVehiculo INT,
    @IdOperacionDia INT = NULL,
    @FechaPago DATETIME,
    @Importe DECIMAL(18,2),
    @IdFormaPago INT,
    @OperacionReferencia VARCHAR(100) = NULL,
    @Observacion VARCHAR(300) = NULL,
    @Usuario INT,
    @IdPagoContrato INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InicioTran BIT = 0;
    DECLARE @SaveName VARCHAR(32) = 'PagoContratoReg';
    DECLARE @ContratoChofer INT;
    DECLARE @ContratoVehiculo INT;
    DECLARE @ContratoEstado VARCHAR(1);
    DECLARE @OpContrato INT;

    SET @IdPagoContrato = 0;
    SET @Mensaje = '';

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

    IF @Importe <= 0
    BEGIN
        SET @Mensaje = 'El importe debe ser mayor que cero.';
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

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.chofer
        WHERE Id_Chofer = @IdChofer
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
    )
    BEGIN
        SET @Mensaje = 'Chofer no encontrado.';
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.vehiculo
        WHERE Id_Vehiculo = @IdVehiculo
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
    )
    BEGIN
        SET @Mensaje = 'Vehiculo no encontrado.';
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.formaPago
        WHERE IdFormaPago = @IdFormaPago
          AND ISNULL(Estado, 0) = 1
    )
    BEGIN
        SET @Mensaje = 'Forma de pago invalida o inactiva.';
        RETURN;
    END;

    IF @IdOperacionDia IS NOT NULL
    BEGIN
        SELECT @OpContrato = od.Id_Contrato
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

        INSERT INTO flota.PagoContrato
        (
            id_empresa, id_est, Id_Contrato, Id_Chofer, Id_Vehiculo, Id_OperacionDia,
            FechaPago, Importe, IdFormaPago, OperacionReferencia, Observacion,
            FlgValidado, FlgEstado, ImporteAplicado, ImporteDisponible,
            Usu_Creacion, Fec_Creacion
        )
        VALUES
        (
            @IdEmpresa, @IdEst, @IdContrato, @IdChofer, @IdVehiculo, @IdOperacionDia,
            @FechaPago, @Importe, @IdFormaPago, @OperacionReferencia, @Observacion,
            'N', 'A', 0, @Importe,
            @Usuario, GETUTCDATE()
        );

        SET @IdPagoContrato = SCOPE_IDENTITY();
        SET @Mensaje = 'Pago declarado registrado correctamente.';

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
        SET @IdPagoContrato = 0;
        SET @Mensaje = ERROR_MESSAGE();
        RETURN;
    END CATCH;
END
GO

IF OBJECT_ID('flota.p_PagoContrato_Obtener', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_PagoContrato_Obtener AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_PagoContrato_Obtener
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdPagoContrato INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPagoContrato,
        p.id_empresa,
        p.id_est,
        p.Id_Contrato,
        p.Id_Chofer,
        p.Id_Vehiculo,
        p.Id_OperacionDia,
        p.FechaPago,
        p.Importe,
        p.IdFormaPago,
        fp.tipo AS FormaPago,
        fp.tipo AS FormaPagoTexto,
        fp.abrev AS FormaPagoAbrev,
        p.OperacionReferencia,
        p.Observacion,
        p.FlgValidado,
        p.FlgEstado,
        p.ImporteAplicado,
        p.ImporteDisponible,
        p.Usu_Creacion,
        p.Fec_Creacion,
        p.Usu_Valida,
        p.Fec_Valida,
        p.MotivoValidacion,
        p.Usu_Anula,
        p.Fec_Anula,
        p.MotivoAnula,
        c.Numero AS ContratoNumero,
        v.Placa,
        ISNULL(ch.Nombres, ch.Cod_TipAnex + '-' + ch.Cod_Anxo) AS Chofer
    FROM flota.PagoContrato p
    INNER JOIN flota.contrato c ON c.Id_Contrato = p.Id_Contrato
    INNER JOIN flota.vehiculo v ON v.Id_Vehiculo = p.Id_Vehiculo
    INNER JOIN flota.chofer ch ON ch.Id_Chofer = p.Id_Chofer
    INNER JOIN dbo.formaPago fp ON fp.IdFormaPago = p.IdFormaPago
    WHERE p.IdPagoContrato = @IdPagoContrato
      AND p.id_empresa = @IdEmpresa
      AND p.id_est = @IdEst;

    SELECT
        IdAdjunto,
        TipoAdjunto,
        RutaArchivo,
        NombreOriginal,
        MimeType,
        TamanoBytes,
        Observacion,
        Fec_Creacion
    FROM flota.AdjuntoFlota
    WHERE id_empresa = @IdEmpresa
      AND id_est = @IdEst
      AND TipoEntidad = 'PAGO_CONTRATO'
      AND IdEntidad = @IdPagoContrato
      AND FlgEstado = 'A'
    ORDER BY Fec_Creacion DESC, IdAdjunto DESC;
END
GO

IF OBJECT_ID('flota.p_PagoContrato_ListarPorContrato', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_PagoContrato_ListarPorContrato AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_PagoContrato_ListarPorContrato
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
        p.FechaPago,
        p.Importe,
        p.IdFormaPago,
        fp.tipo AS FormaPago,
        p.OperacionReferencia,
        p.Observacion,
        p.FlgValidado,
        p.FlgEstado,
        p.ImporteAplicado,
        p.ImporteDisponible,
        p.Fec_Creacion,
        p.Fec_Valida
    FROM flota.PagoContrato p
    INNER JOIN dbo.formaPago fp
        ON fp.IdFormaPago = p.IdFormaPago
    WHERE p.id_empresa = @IdEmpresa
      AND p.id_est = @IdEst
      AND p.Id_Contrato = @IdContrato
      AND (@FlgValidado IS NULL OR p.FlgValidado = @FlgValidado)
      AND (@FlgEstado IS NULL OR p.FlgEstado = @FlgEstado)
    ORDER BY p.FechaPago DESC, p.IdPagoContrato DESC;
END
GO

IF OBJECT_ID('flota.p_PagoContrato_ListarPendientes', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_PagoContrato_ListarPendientes AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_PagoContrato_ListarPendientes
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT = NULL,
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @Texto VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @Texto = NULLIF(LTRIM(RTRIM(@Texto)), '');

    SELECT
        p.IdPagoContrato,
        p.Id_Contrato,
        c.Numero AS ContratoNumero,
        p.Id_Chofer,
        ISNULL(ch.Nombres, ch.Cod_TipAnex + '-' + ch.Cod_Anxo) AS Chofer,
        p.Id_Vehiculo,
        v.Placa,
        p.Id_OperacionDia,
        p.FechaPago,
        p.Importe,
        p.ImporteAplicado,
        p.ImporteDisponible,
        p.IdFormaPago,
        fp.tipo AS FormaPago,
        fp.tipo AS FormaPagoTexto,
        p.OperacionReferencia,
        p.Observacion,
        p.FlgValidado,
        p.FlgEstado,
        p.Fec_Creacion
    FROM flota.PagoContrato p
    INNER JOIN flota.contrato c ON c.Id_Contrato = p.Id_Contrato
    INNER JOIN flota.chofer ch ON ch.Id_Chofer = p.Id_Chofer
    INNER JOIN flota.vehiculo v ON v.Id_Vehiculo = p.Id_Vehiculo
    INNER JOIN dbo.formaPago fp ON fp.IdFormaPago = p.IdFormaPago
    WHERE p.id_empresa = @IdEmpresa
      AND p.id_est = @IdEst
      AND p.FlgEstado = 'A'
      AND p.FlgValidado = 'N'
      AND (@IdContrato IS NULL OR p.Id_Contrato = @IdContrato)
      AND (@FechaDesde IS NULL OR p.FechaPago >= @FechaDesde)
      AND (@FechaHasta IS NULL OR p.FechaPago < DATEADD(DAY, 1, @FechaHasta))
      AND
      (
          @Texto IS NULL
          OR c.Numero LIKE '%' + @Texto + '%'
          OR ISNULL(ch.Nombres, ch.Cod_TipAnex + '-' + ch.Cod_Anxo) LIKE '%' + @Texto + '%'
          OR v.Placa LIKE '%' + @Texto + '%'
          OR ISNULL(p.OperacionReferencia, '') LIKE '%' + @Texto + '%'
          OR fp.tipo LIKE '%' + @Texto + '%'
      )
    ORDER BY p.FechaPago DESC, p.IdPagoContrato DESC;
END
GO

IF OBJECT_ID('flota.p_PagoContrato_Validar', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_PagoContrato_Validar AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_PagoContrato_Validar
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdPagoContrato INT,
    @FlgValidado VARCHAR(1),
    @Motivo VARCHAR(250),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InicioTran BIT = 0;
    DECLARE @SaveName VARCHAR(32) = 'PagoContratoVal';

    SET @Mensaje = '';
    SET @FlgValidado = UPPER(LTRIM(RTRIM(ISNULL(@FlgValidado, ''))));

    IF @IdPagoContrato <= 0
    BEGIN
        SET @Mensaje = 'PagoContrato invalido.';
        RETURN;
    END;

    IF @FlgValidado NOT IN ('S', 'N')
    BEGIN
        SET @Mensaje = 'FlgValidado invalido. Usa S o N.';
        RETURN;
    END;

    IF LTRIM(RTRIM(ISNULL(@Motivo, ''))) = ''
    BEGIN
        SET @Mensaje = 'Motivo obligatorio.';
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.PagoContrato
        WHERE IdPagoContrato = @IdPagoContrato
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
          AND FlgEstado = 'A'
    )
    BEGIN
        SET @Mensaje = 'PagoContrato no encontrado.';
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

        UPDATE flota.PagoContrato
        SET FlgValidado = @FlgValidado,
            Usu_Valida = @Usuario,
            Fec_Valida = GETUTCDATE(),
            MotivoValidacion = @Motivo
        WHERE IdPagoContrato = @IdPagoContrato
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
          AND FlgEstado = 'A';

        SET @Mensaje = 'Validacion de pago declarada actualizada correctamente.';

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

IF OBJECT_ID('flota.p_PagoContrato_Anular', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_PagoContrato_Anular AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_PagoContrato_Anular
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdPagoContrato INT,
    @Motivo VARCHAR(250),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InicioTran BIT = 0;
    DECLARE @SaveName VARCHAR(32) = 'PagoContratoAnu';

    SET @Mensaje = '';

    IF @IdPagoContrato <= 0
    BEGIN
        SET @Mensaje = 'PagoContrato invalido.';
        RETURN;
    END;

    IF LTRIM(RTRIM(ISNULL(@Motivo, ''))) = ''
    BEGIN
        SET @Mensaje = 'Motivo obligatorio.';
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.PagoContrato
        WHERE IdPagoContrato = @IdPagoContrato
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
          AND FlgEstado = 'A'
    )
    BEGIN
        SET @Mensaje = 'PagoContrato no encontrado.';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM flota.PagoContrato
        WHERE IdPagoContrato = @IdPagoContrato
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
          AND ImporteAplicado > 0
    )
    BEGIN
        SET @Mensaje = 'No se puede anular un PagoContrato con importe aplicado.';
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

        UPDATE flota.PagoContrato
        SET FlgEstado = 'X',
            Usu_Anula = @Usuario,
            Fec_Anula = GETUTCDATE(),
            MotivoAnula = @Motivo
        WHERE IdPagoContrato = @IdPagoContrato
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst
          AND FlgEstado = 'A';

        SET @Mensaje = 'Pago declarado anulado correctamente.';

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

/*==============================================================
  BLOQUE 6 - SP OPERACION MOBILE
==============================================================*/
IF OBJECT_ID('flota.p_OperacionDia_Mobile_Obtener', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_OperacionDia_Mobile_Obtener AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_OperacionDia_Mobile_Obtener
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @Fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Id_Contrato,
        c.Numero,
        c.Cod_Modalidad,
        c.Cod_Periodicidad,
        c.FechaInicio,
        c.FechaFin,
        c.TarifaDia,
        c.Flg_ControlKm,
        c.Flg_CobraDomingo,
        c.Observacion,
        v.Id_Vehiculo,
        v.Placa,
        ISNULL(v.MarcaTexto, '') AS Marca,
        ISNULL(v.ModeloTexto, '') AS Modelo,
        ISNULL(v.GalonesTanque, 0) AS GalonesTanque,
        ISNULL(v.PrecioGalon, 0) AS PrecioGalon,
        ISNULL(v.RendimientoTanqueKm, 0) AS RendimientoTanqueKm,
        ch.Id_Chofer,
        ISNULL(ch.Nombres, ch.Cod_TipAnex + '-' + ch.Cod_Anxo) AS Chofer
    FROM flota.contrato c
    INNER JOIN flota.vehiculo v ON v.Id_Vehiculo = c.Id_Vehiculo
    INNER JOIN flota.chofer ch ON ch.Id_Chofer = c.Id_Chofer
    WHERE c.Id_Contrato = @IdContrato
      AND c.id_empresa = @IdEmpresa
      AND c.id_est = @IdEst
      AND c.Flg_Estado = 'A';

    SELECT
        od.Id_OperacionDia,
        od.Fecha,
        od.Flg_Trabajo,
        od.Cod_Motivo,
        od.Flg_Cobrable,
        od.ImporteGenerado,
        od.KmInicial,
        od.KmFinal,
        od.KmRecorrido,
        od.ImporteCombustible,
        od.GalonesCargados,
        od.Flg_PagoCombustible,
        od.CostoConsumoEstimado,
        od.Observacion,
        od.Fec_Creacion,
        od.Fec_Modif
    FROM flota.operacion_dia od
    WHERE od.Id_Contrato = @IdContrato
      AND od.id_empresa = @IdEmpresa
      AND od.id_est = @IdEst
      AND od.Fecha = @Fecha;

    SELECT
        a.IdAdjunto,
        a.TipoAdjunto,
        a.RutaArchivo,
        a.NombreOriginal,
        a.MimeType,
        a.TamanoBytes,
        a.Observacion,
        a.Fec_Creacion
    FROM flota.AdjuntoFlota a
    WHERE a.id_empresa = @IdEmpresa
      AND a.id_est = @IdEst
      AND a.TipoEntidad = 'OPERACION_DIA'
      AND a.IdEntidad IN
      (
          SELECT od.Id_OperacionDia
          FROM flota.operacion_dia od
          WHERE od.Id_Contrato = @IdContrato
            AND od.id_empresa = @IdEmpresa
            AND od.id_est = @IdEst
            AND od.Fecha = @Fecha
      )
      AND a.FlgEstado = 'A'
    ORDER BY a.Fec_Creacion DESC, a.IdAdjunto DESC;

    SELECT
        fp.IdFormaPago,
        fp.tipo,
        fp.abrev,
        fp.descripcion
    FROM dbo.formaPago fp
    WHERE ISNULL(fp.Estado, 0) = 1
      AND fp.IdFormaPago IN (1, 3, 5, 6)
    ORDER BY fp.IdFormaPago;
END
GO

IF OBJECT_ID('flota.p_OperacionDia_Mobile_Guardar', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_OperacionDia_Mobile_Guardar AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_OperacionDia_Mobile_Guardar
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @Fecha DATE,
    @FlgTrabajo VARCHAR(1),
    @CodMotivo VARCHAR(3),
    @FlgCobrable VARCHAR(1),
    @KmInicial DECIMAL(12,2) = NULL,
    @KmFinal DECIMAL(12,2) = NULL,
    @GalonesCargados DECIMAL(12,3) = 0,
    @ImporteCombustible DECIMAL(18,2) = 0,
    @FlgPagoCombustible VARCHAR(1) = NULL,
    @Observacion VARCHAR(300) = NULL,
    @Usuario INT,
    @IdOperacionDia INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ContratoEstado VARCHAR(1);
    DECLARE @ControlKm VARCHAR(1);
    DECLARE @TrabajoBit BIT;
    DECLARE @CobrableBit BIT;

    SET @IdOperacionDia = 0;
    SET @Mensaje = '';
    SET @FlgTrabajo = UPPER(LTRIM(RTRIM(ISNULL(@FlgTrabajo, ''))));
    SET @FlgCobrable = UPPER(LTRIM(RTRIM(ISNULL(@FlgCobrable, ''))));

    IF @IdContrato <= 0
    BEGIN
        SET @Mensaje = 'Contrato invalido.';
        RETURN;
    END;

    IF @FlgTrabajo NOT IN ('S', 'N')
    BEGIN
        SET @Mensaje = 'FlgTrabajo invalido. Usa S o N.';
        RETURN;
    END;

    IF @FlgCobrable NOT IN ('S', 'N')
    BEGIN
        SET @Mensaje = 'FlgCobrable invalido. Usa S o N.';
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.motivo_dia
        WHERE Cod_Motivo = @CodMotivo
          AND Flg_Activo = 'S'
    )
    BEGIN
        SET @Mensaje = 'CodMotivo invalido.';
        RETURN;
    END;

    SELECT
        @ControlKm = c.Flg_ControlKm,
        @ContratoEstado = c.Flg_Estado
    FROM flota.contrato c
    WHERE c.Id_Contrato = @IdContrato
      AND c.id_empresa = @IdEmpresa
      AND c.id_est = @IdEst;

    IF @ControlKm IS NULL
    BEGIN
        SET @Mensaje = 'Contrato no encontrado.';
        RETURN;
    END;

    IF @ContratoEstado <> 'A'
    BEGIN
        SET @Mensaje = 'El contrato no esta activo.';
        RETURN;
    END;

    IF @ControlKm = 'S'
    BEGIN
        IF @KmInicial IS NULL OR @KmFinal IS NULL OR @KmFinal < @KmInicial
        BEGIN
            SET @Mensaje = 'Ingrese kilometraje inicial y final validos.';
            RETURN;
        END;
    END;
    ELSE
    BEGIN
        IF @KmInicial IS NOT NULL AND @KmFinal IS NOT NULL AND @KmFinal < @KmInicial
        BEGIN
            SET @Mensaje = 'Kilometraje final no puede ser menor al inicial.';
            RETURN;
        END;
    END;

    IF @GalonesCargados < 0
    BEGIN
        SET @Mensaje = 'GalonesCargados invalido.';
        RETURN;
    END;

    IF @ImporteCombustible < 0
    BEGIN
        SET @Mensaje = 'ImporteCombustible invalido.';
        RETURN;
    END;

    SET @TrabajoBit = CASE WHEN @FlgTrabajo = 'S' THEN 1 ELSE 0 END;
    SET @CobrableBit = CASE WHEN @FlgCobrable = 'S' THEN 1 ELSE 0 END;

    EXEC flota.p_trabajo_dia_guardar
        @id_empresa = @IdEmpresa,
        @id_est = @IdEst,
        @IdContrato = @IdContrato,
        @Fecha = @Fecha,
        @Trabajo = @TrabajoBit,
        @CodMotivo = @CodMotivo,
        @Cobrable = @CobrableBit,
        @KmInicial = @KmInicial,
        @KmFinal = @KmFinal,
        @ImporteCombustible = @ImporteCombustible,
        @Galones = @GalonesCargados,
        @PagoCombustible = @FlgPagoCombustible,
        @Observacion = @Observacion,
        @Usuario = @Usuario,
        @Id = @IdOperacionDia OUTPUT,
        @Mensaje = @Mensaje OUTPUT;

    IF @IdOperacionDia > 0 AND LTRIM(RTRIM(ISNULL(@Mensaje, ''))) = ''
    BEGIN
        SET @Mensaje = 'Operacion diaria mobile guardada correctamente.';
    END;
END
GO

/*==============================================================
  BLOQUE 7 - POSTVALIDACIONES
==============================================================*/
IF OBJECT_ID('flota.AdjuntoFlota', 'U') IS NULL
BEGIN
    RAISERROR('Postvalidacion: falta flota.AdjuntoFlota.', 16, 1);
    RETURN;
END;
GO

IF OBJECT_ID('flota.PagoContrato', 'U') IS NULL
BEGIN
    RAISERROR('Postvalidacion: falta flota.PagoContrato.', 16, 1);
    RETURN;
END;
GO

IF OBJECT_ID('flota.p_AdjuntoFlota_Registrar', 'P') IS NULL
    OR OBJECT_ID('flota.p_AdjuntoFlota_ListarPorEntidad', 'P') IS NULL
    OR OBJECT_ID('flota.p_AdjuntoFlota_Anular', 'P') IS NULL
    OR OBJECT_ID('flota.p_PagoContrato_Registrar', 'P') IS NULL
    OR OBJECT_ID('flota.p_PagoContrato_Obtener', 'P') IS NULL
    OR OBJECT_ID('flota.p_PagoContrato_ListarPorContrato', 'P') IS NULL
    OR OBJECT_ID('flota.p_PagoContrato_ListarPendientes', 'P') IS NULL
    OR OBJECT_ID('flota.p_PagoContrato_Validar', 'P') IS NULL
    OR OBJECT_ID('flota.p_PagoContrato_Anular', 'P') IS NULL
    OR OBJECT_ID('flota.p_OperacionDia_Mobile_Obtener', 'P') IS NULL
    OR OBJECT_ID('flota.p_OperacionDia_Mobile_Guardar', 'P') IS NULL
BEGIN
    RAISERROR('Postvalidacion: faltan procedimientos almacenados de Etapa 2.1.', 16, 1);
    RETURN;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID('flota.PagoContrato')
      AND referenced_object_id = OBJECT_ID('dbo.formaPago')
)
BEGIN
    RAISERROR('Postvalidacion: falta FK flota.PagoContrato -> dbo.formaPago.', 16, 1);
    RETURN;
END;
GO

IF OBJECT_ID('flota.PagoContratoAplicacion', 'U') IS NOT NULL
BEGIN
    RAISERROR('Postvalidacion: no debio crearse flota.PagoContratoAplicacion en Etapa 2.1.', 16, 1);
    RETURN;
END;
GO

IF OBJECT_ID('flota.p_PagoContrato_AplicarARecibo', 'P') IS NOT NULL
BEGIN
    RAISERROR('Postvalidacion: no debio crearse flota.p_PagoContrato_AplicarARecibo en Etapa 2.1.', 16, 1);
    RETURN;
END;
GO

IF OBJECT_ID('flota.p_PagoContrato_Aplicaciones_Listar', 'P') IS NOT NULL
BEGIN
    RAISERROR('Postvalidacion: no debio crearse flota.p_PagoContrato_Aplicaciones_Listar en Etapa 2.1.', 16, 1);
    RETURN;
END;
GO

PRINT 'Etapa 2.1 Flota mobile captura: script generado para desarrollo y listo para revision.';
GO

