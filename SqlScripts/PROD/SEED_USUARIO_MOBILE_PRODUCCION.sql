SET NOCOUNT ON;

/*
SEED PRODUCTIVO DE USUARIO MOBILE FLOTA
NO EJECUTAR HASTA COMPLETAR TODOS LOS DATOS REALES.

Reglas:
- Base objetivo: DB_9FA64E_bdgas
- No guardar PIN plano
- PasswordHash y PasswordSalt deben generarse externamente con:
  Aplicacion.Common.FlotaMobilePasswordHasher
  PBKDF2 SHA256
  SaltSize = 16
  KeySize = 32
  Iterations = 100000

El PIN temporal NO debe quedar escrito en este archivo.
Solo deben pegarse PasswordHash y PasswordSalt ya generados.
*/

DECLARE @IdEmpresa INT = 6;
DECLARE @IdEst CHAR(2) = '4';
DECLARE @IdContrato INT = NULL; -- COMPLETAR
DECLARE @IdChofer INT = NULL; -- COMPLETAR
DECLARE @Telefono VARCHAR(20) = '949222682';
DECLARE @Nombre VARCHAR(150) = 'COMPLETAR';
DECLARE @PasswordHash VARCHAR(300) = 'COMPLETAR_HASH_GENERADO_EN_CSHARP';
DECLARE @PasswordSalt VARCHAR(100) = 'COMPLETAR_SALT_GENERADO_EN_CSHARP';
DECLARE @Usuario INT = NULL; -- COMPLETAR

DECLARE @IdUsuarioMobile INT = 0;
DECLARE @Mensaje VARCHAR(300) = '';

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este seed solo debe ejecutarse en DB_9FA64E_bdgas.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.UsuarioMobile', 'U') IS NULL
BEGIN
    RAISERROR('No existe flota.UsuarioMobile.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.contrato', 'U') IS NULL
BEGIN
    RAISERROR('No existe flota.contrato.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.chofer', 'U') IS NULL
BEGIN
    RAISERROR('No existe flota.chofer.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.UsuarioMobile', 'id_empresa') IS NULL
    OR COL_LENGTH('flota.UsuarioMobile', 'id_est') IS NULL
    OR COL_LENGTH('flota.UsuarioMobile', 'Id_Chofer') IS NULL
    OR COL_LENGTH('flota.UsuarioMobile', 'Id_Contrato') IS NULL
    OR COL_LENGTH('flota.UsuarioMobile', 'Telefono') IS NULL
    OR COL_LENGTH('flota.UsuarioMobile', 'Nombre') IS NULL
    OR COL_LENGTH('flota.UsuarioMobile', 'PasswordHash') IS NULL
    OR COL_LENGTH('flota.UsuarioMobile', 'PasswordSalt') IS NULL
    OR COL_LENGTH('flota.UsuarioMobile', 'FlgEstado') IS NULL
BEGIN
    RAISERROR('La estructura de flota.UsuarioMobile no coincide con la esperada.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF @IdContrato IS NULL OR @IdContrato <= 0
BEGIN
    RAISERROR('Completa @IdContrato con un valor real.', 16, 1);
    SET NOEXEC ON;
END;

IF @IdChofer IS NULL OR @IdChofer <= 0
BEGIN
    RAISERROR('Completa @IdChofer con un valor real.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@Telefono, ''))) = ''
BEGIN
    RAISERROR('Completa @Telefono con un valor real.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@Nombre, ''))) = '' OR @Nombre = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @Nombre con un valor real.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@PasswordHash, ''))) = '' OR @PasswordHash = 'COMPLETAR_HASH_GENERADO_EN_CSHARP'
BEGIN
    RAISERROR('Completa @PasswordHash con el valor generado desde C#.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@PasswordSalt, ''))) = '' OR @PasswordSalt = 'COMPLETAR_SALT_GENERADO_EN_CSHARP'
BEGIN
    RAISERROR('Completa @PasswordSalt con el valor generado desde C#.', 16, 1);
    SET NOEXEC ON;
END;

IF @Usuario IS NULL OR @Usuario <= 0
BEGIN
    RAISERROR('Completa @Usuario con el responsable real.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM flota.contrato c
    WHERE c.Id_Contrato = @IdContrato
      AND c.id_empresa = @IdEmpresa
      AND c.id_est = @IdEst
)
BEGIN
    RAISERROR('El contrato no existe en el tenant indicado.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM flota.chofer ch
    WHERE ch.Id_Chofer = @IdChofer
      AND ch.id_empresa = @IdEmpresa
      AND ch.id_est = @IdEst
)
BEGIN
    RAISERROR('El chofer no existe en el tenant indicado.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF EXISTS
(
    SELECT 1
    FROM flota.contrato c
    WHERE c.Id_Contrato = @IdContrato
      AND c.id_empresa = @IdEmpresa
      AND c.id_est = @IdEst
      AND c.Id_Chofer IS NOT NULL
      AND c.Id_Chofer <> @IdChofer
)
BEGIN
    RAISERROR('El contrato pertenece a otro chofer.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF EXISTS
(
    SELECT 1
    FROM flota.UsuarioMobile u
    WHERE u.id_empresa = @IdEmpresa
      AND u.id_est = @IdEst
      AND u.Telefono = @Telefono
      AND u.FlgEstado = 'A'
)
BEGIN
    RAISERROR('Ya existe un usuario mobile activo con ese telefono.', 16, 1);
    SET NOEXEC ON;
END;
GO

EXEC flota.p_UsuarioMobile_RegistrarTemporal
    @IdEmpresa = @IdEmpresa,
    @IdEst = @IdEst,
    @IdChofer = @IdChofer,
    @IdContrato = @IdContrato,
    @Telefono = @Telefono,
    @Nombre = @Nombre,
    @PasswordHash = @PasswordHash,
    @PasswordSalt = @PasswordSalt,
    @Usuario = @Usuario,
    @IdUsuarioMobile = @IdUsuarioMobile OUTPUT,
    @Mensaje = @Mensaje OUTPUT;

SELECT
    @IdUsuarioMobile AS IdUsuarioMobile,
    @Mensaje AS Mensaje,
    @Telefono AS Telefono,
    @IdContrato AS IdContrato,
    @IdChofer AS IdChofer,
    @IdEmpresa AS IdEmpresa,
    @IdEst AS IdEst;
