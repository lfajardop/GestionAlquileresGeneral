SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en DB_9FA64E_bdgas.',16,1);
    SET NOEXEC ON;
END
GO

IF OBJECT_ID('flota.UsuarioMobile', 'U') IS NULL
BEGIN
    CREATE TABLE flota.UsuarioMobile
    (
        IdUsuarioMobile INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_flota_UsuarioMobile PRIMARY KEY,
        id_empresa INT NOT NULL,
        id_est CHAR(2) NOT NULL,
        Id_Chofer INT NULL,
        Id_Contrato INT NULL,
        Telefono VARCHAR(20) NOT NULL,
        Nombre VARCHAR(150) NULL,
        PasswordHash VARCHAR(300) NOT NULL,
        PasswordSalt VARCHAR(100) NULL,
        FlgEstado VARCHAR(1) NOT NULL CONSTRAINT DF_flota_UsuarioMobile_FlgEstado DEFAULT('A'),
        Fec_Creacion DATETIME NOT NULL CONSTRAINT DF_flota_UsuarioMobile_FecCreacion DEFAULT(GETUTCDATE()),
        Usu_Creacion INT NULL,
        Fec_UltimoLogin DATETIME NULL,
        CONSTRAINT CK_flota_UsuarioMobile_FlgEstado CHECK (FlgEstado IN ('A','X')),
        CONSTRAINT FK_flota_UsuarioMobile_Chofer FOREIGN KEY (Id_Chofer) REFERENCES flota.chofer(Id_Chofer),
        CONSTRAINT FK_flota_UsuarioMobile_Contrato FOREIGN KEY (Id_Contrato) REFERENCES flota.contrato(Id_Contrato)
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('flota.UsuarioMobile')
      AND name = 'IX_flota_UsuarioMobile_TelefonoEstado'
)
BEGIN
    CREATE INDEX IX_flota_UsuarioMobile_TelefonoEstado
        ON flota.UsuarioMobile(id_empresa, id_est, Telefono, FlgEstado);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('flota.UsuarioMobile')
      AND name = 'UX_flota_UsuarioMobile_TelefonoActivo'
)
BEGIN
    CREATE UNIQUE INDEX UX_flota_UsuarioMobile_TelefonoActivo
        ON flota.UsuarioMobile(id_empresa, id_est, Telefono)
        WHERE FlgEstado = 'A';
END
GO

IF OBJECT_ID('flota.p_UsuarioMobile_Login', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_UsuarioMobile_Login AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_UsuarioMobile_Login
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @Telefono VARCHAR(20),
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Telefono = LTRIM(RTRIM(ISNULL(@Telefono,'')));
    SET @Mensaje = '';

    IF @Telefono = ''
    BEGIN
        SET @Mensaje = 'Ingresa el telefono.';
        RETURN;
    END;

    SELECT TOP (1)
        u.IdUsuarioMobile,
        u.Id_Chofer,
        u.Id_Contrato,
        u.Telefono,
        u.Nombre,
        u.PasswordHash,
        u.PasswordSalt,
        u.FlgEstado,
        u.Fec_UltimoLogin
    FROM flota.UsuarioMobile u
    WHERE u.id_empresa = @IdEmpresa
      AND u.id_est = @IdEst
      AND u.Telefono = @Telefono
      AND u.FlgEstado = 'A'
    ORDER BY u.IdUsuarioMobile DESC;

    IF @@ROWCOUNT = 0
        SET @Mensaje = 'Usuario mobile no encontrado o inactivo.';
END
GO

IF OBJECT_ID('flota.p_UsuarioMobile_RegistrarTemporal', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_UsuarioMobile_RegistrarTemporal AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_UsuarioMobile_RegistrarTemporal
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdChofer INT = NULL,
    @IdContrato INT = NULL,
    @Telefono VARCHAR(20),
    @Nombre VARCHAR(150) = NULL,
    @PasswordHash VARCHAR(300),
    @PasswordSalt VARCHAR(100) = NULL,
    @Usuario INT = NULL,
    @IdUsuarioMobile INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InicioTran BIT = 0;
    DECLARE @SaveName VARCHAR(32) = 'UsrMobileReg';

    SET @IdUsuarioMobile = 0;
    SET @Mensaje = '';
    SET @Telefono = LTRIM(RTRIM(ISNULL(@Telefono,'')));
    SET @Nombre = NULLIF(LTRIM(RTRIM(ISNULL(@Nombre,''))), '');
    SET @PasswordHash = LTRIM(RTRIM(ISNULL(@PasswordHash,'')));
    SET @PasswordSalt = NULLIF(LTRIM(RTRIM(ISNULL(@PasswordSalt,''))), '');

    IF @Telefono = ''
    BEGIN
        SET @Mensaje = 'Telefono obligatorio.';
        RETURN;
    END;

    IF @PasswordHash = ''
    BEGIN
        SET @Mensaje = 'PasswordHash obligatorio.';
        RETURN;
    END;

    IF @IdChofer IS NOT NULL
       AND NOT EXISTS
       (
            SELECT 1
            FROM flota.chofer
            WHERE Id_Chofer = @IdChofer
              AND id_empresa = @IdEmpresa
              AND id_est = @IdEst
       )
    BEGIN
        SET @Mensaje = 'Chofer no encontrado para el tenant.';
        RETURN;
    END;

    IF @IdContrato IS NOT NULL
       AND NOT EXISTS
       (
            SELECT 1
            FROM flota.contrato
            WHERE Id_Contrato = @IdContrato
              AND id_empresa = @IdEmpresa
              AND id_est = @IdEst
       )
    BEGIN
        SET @Mensaje = 'Contrato no encontrado para el tenant.';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM flota.UsuarioMobile
        WHERE id_empresa = @IdEmpresa
          AND id_est = @IdEst
          AND Telefono = @Telefono
          AND FlgEstado = 'A'
    )
    BEGIN
        SET @Mensaje = 'Ya existe un usuario mobile activo con ese telefono.';
        RETURN;
    END;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @InicioTran = 1;
        END
        ELSE
            SAVE TRANSACTION @SaveName;

        INSERT INTO flota.UsuarioMobile
        (
            id_empresa, id_est, Id_Chofer, Id_Contrato, Telefono, Nombre,
            PasswordHash, PasswordSalt, FlgEstado, Fec_Creacion, Usu_Creacion
        )
        VALUES
        (
            @IdEmpresa, @IdEst, @IdChofer, @IdContrato, @Telefono, @Nombre,
            @PasswordHash, @PasswordSalt, 'A', GETUTCDATE(), @Usuario
        );

        SET @IdUsuarioMobile = SCOPE_IDENTITY();
        SET @Mensaje = 'Usuario mobile registrado correctamente.';

        IF @InicioTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1 ROLLBACK TRANSACTION;
            ELSE ROLLBACK TRANSACTION @SaveName;
        END;
        SET @IdUsuarioMobile = 0;
        SET @Mensaje = ERROR_MESSAGE();
        RETURN;
    END CATCH
END
GO

