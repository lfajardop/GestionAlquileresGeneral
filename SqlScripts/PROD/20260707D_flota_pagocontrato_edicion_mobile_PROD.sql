SET NOCOUNT ON;

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en DB_9FA64E_bdgas.', 16, 1);
    SET NOEXEC ON;
END;

IF OBJECT_ID('flota.PagoContrato', 'U') IS NULL
BEGIN
    RAISERROR('No existe flota.PagoContrato.', 16, 1);
    SET NOEXEC ON;
END;

IF OBJECT_ID('dbo.formaPago', 'U') IS NULL
BEGIN
    RAISERROR('No existe dbo.formaPago.', 16, 1);
    SET NOEXEC ON;
END;

IF COL_LENGTH('flota.PagoContrato', 'Usu_Modif') IS NULL
BEGIN
    ALTER TABLE flota.PagoContrato ADD Usu_Modif INT NULL;
END;

IF COL_LENGTH('flota.PagoContrato', 'Fec_Modif') IS NULL
BEGIN
    ALTER TABLE flota.PagoContrato ADD Fec_Modif DATETIME NULL;
END;
GO

IF OBJECT_ID('flota.p_PagoContrato_EditarMobile','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_PagoContrato_EditarMobile AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_PagoContrato_EditarMobile
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdPagoContrato INT,
    @FechaPago DATE,
    @Importe DECIMAL(18, 2),
    @IdFormaPago INT,
    @OperacionReferencia VARCHAR(100) = NULL,
    @Observacion VARCHAR(500) = NULL,
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InicioTran BIT = 0;
    DECLARE @SaveName VARCHAR(32) = 'PagoContratoEditMob';
    DECLARE @FlgEstado VARCHAR(1);
    DECLARE @FlgValidado VARCHAR(1);
    DECLARE @ImporteAplicado DECIMAL(18, 2);

    SET @Mensaje = '';

    IF @IdPagoContrato IS NULL OR @IdPagoContrato <= 0
    BEGIN
        SET @Mensaje = 'Pago declarado no valido.';
        RETURN;
    END;

    IF @FechaPago IS NULL
    BEGIN
        SET @Mensaje = 'La fecha de pago es obligatoria.';
        RETURN;
    END;

    IF @Importe IS NULL OR @Importe <= 0
    BEGIN
        SET @Mensaje = 'El importe debe ser mayor que cero.';
        RETURN;
    END;

    IF @IdFormaPago IS NULL OR @IdFormaPago <= 0
    BEGIN
        SET @Mensaje = 'La forma de pago es obligatoria.';
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.formaPago fp
        WHERE fp.IdFormaPago = @IdFormaPago
          AND ISNULL(fp.Estado, 0) = 1
    )
    BEGIN
        SET @Mensaje = 'La forma de pago no esta activa.';
        RETURN;
    END;

    SELECT
        @FlgEstado = pc.FlgEstado,
        @FlgValidado = pc.FlgValidado,
        @ImporteAplicado = ISNULL(pc.ImporteAplicado, 0)
    FROM flota.PagoContrato pc
    WHERE pc.IdPagoContrato = @IdPagoContrato
      AND pc.id_empresa = @IdEmpresa
      AND pc.id_est = @IdEst;

    IF @FlgEstado IS NULL
    BEGIN
        SET @Mensaje = 'Pago declarado no encontrado.';
        RETURN;
    END;

    IF @FlgEstado <> 'A'
    BEGIN
        SET @Mensaje = 'Solo se puede editar un pago declarado activo.';
        RETURN;
    END;

    IF @FlgValidado <> 'N'
    BEGIN
        SET @Mensaje = 'Solo se puede editar un pago declarado pendiente de validacion.';
        RETURN;
    END;

    IF ISNULL(@ImporteAplicado, 0) > 0
    BEGIN
        SET @Mensaje = 'No se puede editar un pago que ya tiene importe aplicado.';
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
        SET FechaPago = @FechaPago,
            Importe = @Importe,
            ImporteDisponible = @Importe,
            IdFormaPago = @IdFormaPago,
            OperacionReferencia = NULLIF(LTRIM(RTRIM(@OperacionReferencia)), ''),
            Observacion = NULLIF(LTRIM(RTRIM(@Observacion)), ''),
            Usu_Modif = @Usuario,
            Fec_Modif = GETUTCDATE()
        WHERE IdPagoContrato = @IdPagoContrato
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst;

        IF @InicioTran = 1
        BEGIN
            COMMIT TRANSACTION;
        END;

        SET @Mensaje = 'Pago declarado editado correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
            BEGIN
                ROLLBACK TRANSACTION;
            END
            ELSE
            BEGIN
                ROLLBACK TRANSACTION @SaveName;
            END;
        END;

        SET @Mensaje = ERROR_MESSAGE();
        RETURN;
    END CATCH;
END;
GO

