SET NOCOUNT ON;

/*
PLANTILLA SOLO PARA REVISION.
NO EJECUTAR HASTA COMPLETAR DATOS REALES Y HASH/SALT COMPATIBLES.

ESTRATEGIA SEGURA ELEGIDA:
C) El script SQL solo inserta PasswordHash y PasswordSalt ya generados externamente.

Motivo:
- El hash real se genera en C# con FlotaMobilePasswordHasher
- PBKDF2 SHA256
- Salt aleatorio de 16 bytes
- KeySize 32 bytes
- Iterations 100000

No inventar hash en SQL.
Generar hash/salt previamente con el mismo codigo C# y pegar ambos valores aqui.
*/

DECLARE @IdEmpresa INT = 6;
DECLARE @IdEst CHAR(2) = '4';
DECLARE @IdContrato INT = NULL;
DECLARE @IdChofer INT = NULL;
DECLARE @Telefono VARCHAR(20) = 'COMPLETAR';
DECLARE @Nombre VARCHAR(150) = 'COMPLETAR';
DECLARE @PinTemporal VARCHAR(20) = 'COMPLETAR';
DECLARE @PasswordHash VARCHAR(300) = 'COMPLETAR_HASH_GENERADO_EN_CSHARP';
DECLARE @PasswordSalt VARCHAR(100) = 'COMPLETAR_SALT_GENERADO_EN_CSHARP';
DECLARE @Usuario INT = NULL;

DECLARE @IdUsuarioMobile INT;
DECLARE @Mensaje VARCHAR(300);

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este seed solo debe ejecutarse en DB_9FA64E_bdgas.', 16, 1);
    RETURN;
END;

IF @IdContrato IS NULL OR @IdContrato <= 0
BEGIN
    RAISERROR('Completa @IdContrato con un valor real.', 16, 1);
    RETURN;
END;

IF @IdChofer IS NULL OR @IdChofer <= 0
BEGIN
    RAISERROR('Completa @IdChofer con un valor real.', 16, 1);
    RETURN;
END;

IF LTRIM(RTRIM(ISNULL(@Telefono, ''))) = '' OR @Telefono = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @Telefono con un valor real.', 16, 1);
    RETURN;
END;

IF LTRIM(RTRIM(ISNULL(@Nombre, ''))) = '' OR @Nombre = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @Nombre con un valor real.', 16, 1);
    RETURN;
END;

IF LTRIM(RTRIM(ISNULL(@PinTemporal, ''))) = '' OR @PinTemporal = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @PinTemporal antes de entregar el acceso.', 16, 1);
    RETURN;
END;

IF @PinTemporal = '123456'
BEGIN
    RAISERROR('No usar PIN 123456 en produccion.', 16, 1);
    RETURN;
END;

IF LTRIM(RTRIM(ISNULL(@PasswordHash, ''))) = '' OR @PasswordHash = 'COMPLETAR_HASH_GENERADO_EN_CSHARP'
BEGIN
    RAISERROR('Completa @PasswordHash con valor generado externamente en C#.', 16, 1);
    RETURN;
END;

IF LTRIM(RTRIM(ISNULL(@PasswordSalt, ''))) = '' OR @PasswordSalt = 'COMPLETAR_SALT_GENERADO_EN_CSHARP'
BEGIN
    RAISERROR('Completa @PasswordSalt con valor generado externamente en C#.', 16, 1);
    RETURN;
END;

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
    RETURN;
END;

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
    RETURN;
END;

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
    RETURN;
END;

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
    RETURN;
END;

PRINT 'PRECHECK OK: datos minimos completos.';
PRINT 'IMPORTANTE: este script no genera hash. Debes pegar PasswordHash y PasswordSalt compatibles con FlotaMobilePasswordHasher.';

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
    @IdChofer AS IdChofer;
