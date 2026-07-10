/*
FASE 1 URGENTE FLOTA - USUARIOS MOBILE ADMIN
Base objetivo: DB_9FA64E_bdgas

Incluye:
- flota.p_UsuarioMobile_ListarAdmin
- flota.p_UsuarioMobile_ResetPin

Reglas:
- No guardar PIN plano
- No tocar contrato
- No tocar chofer
- No tocar pagos
- No tocar caja/cobranza
*/

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en DB_9FA64E_bdgas.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.UsuarioMobile','U') IS NULL
BEGIN
    RAISERROR('No existe flota.UsuarioMobile.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.p_UsuarioMobile_ListarAdmin','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_UsuarioMobile_ListarAdmin AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_UsuarioMobile_ListarAdmin
    @IdEmpresa INT,
    @IdEst CHAR(2)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.IdUsuarioMobile,
        u.Telefono,
        ISNULL(u.Nombre,'') AS Nombre,
        u.Id_Chofer,
        ISNULL(ch.Nombres,'') AS ChoferNombre,
        u.Id_Contrato,
        ISNULL(c.Numero,'') AS NumeroContrato,
        ISNULL(v.Placa,'') AS Placa,
        u.FlgEstado,
        u.Fec_Creacion,
        u.Fec_UltimoLogin
    FROM flota.UsuarioMobile u
    LEFT JOIN flota.chofer ch
        ON ch.Id_Chofer = u.Id_Chofer
    LEFT JOIN flota.contrato c
        ON c.Id_Contrato = u.Id_Contrato
    LEFT JOIN flota.vehiculo v
        ON v.Id_Vehiculo = c.Id_Vehiculo
    WHERE u.id_empresa = @IdEmpresa
      AND u.id_est = @IdEst
    ORDER BY u.IdUsuarioMobile DESC;
END;
GO

IF OBJECT_ID('flota.p_UsuarioMobile_ResetPin','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_UsuarioMobile_ResetPin AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_UsuarioMobile_ResetPin
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdUsuarioMobile INT,
    @PasswordHash VARCHAR(300),
    @PasswordSalt VARCHAR(100),
    @Usuario INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Existe INT;

    SET @PasswordHash = LTRIM(RTRIM(ISNULL(@PasswordHash,'')));
    SET @PasswordSalt = LTRIM(RTRIM(ISNULL(@PasswordSalt,'')));

    IF @IdUsuarioMobile <= 0
    BEGIN
        SELECT 0 AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'IdUsuarioMobile invalido.' AS Mensaje;
        RETURN;
    END;

    IF @PasswordHash = ''
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'PasswordHash obligatorio.' AS Mensaje;
        RETURN;
    END;

    IF @PasswordSalt = ''
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'PasswordSalt obligatorio.' AS Mensaje;
        RETURN;
    END;

    SELECT @Existe = COUNT(1)
    FROM flota.UsuarioMobile
    WHERE IdUsuarioMobile = @IdUsuarioMobile
      AND id_empresa = @IdEmpresa
      AND id_est = @IdEst;

    IF ISNULL(@Existe,0) = 0
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'Usuario mobile no encontrado.' AS Mensaje;
        RETURN;
    END;

    UPDATE flota.UsuarioMobile
    SET PasswordHash = @PasswordHash,
        PasswordSalt = @PasswordSalt,
        FlgEstado = 'A'
    WHERE IdUsuarioMobile = @IdUsuarioMobile
      AND id_empresa = @IdEmpresa
      AND id_est = @IdEst;

    SELECT
        IdUsuarioMobile,
        Telefono,
        FlgEstado,
        'PIN reseteado correctamente.' AS Mensaje
    FROM flota.UsuarioMobile
    WHERE IdUsuarioMobile = @IdUsuarioMobile
      AND id_empresa = @IdEmpresa
      AND id_est = @IdEst;
END;
GO
