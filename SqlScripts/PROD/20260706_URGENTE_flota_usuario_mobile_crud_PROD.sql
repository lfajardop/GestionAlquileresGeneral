/*
FASE 1 URGENTE FLOTA - USUARIOS MOBILE CRUD ADMIN
Base objetivo: DB_9FA64E_bdgas

Incluye:
- flota.p_UsuarioMobile_ListarAdmin
- flota.p_UsuarioMobile_CrearAdmin
- flota.p_UsuarioMobile_ActualizarAdmin
- flota.p_UsuarioMobile_CambiarEstado
- flota.p_UsuarioMobile_CambiarContrato
- flota.p_UsuarioMobile_ResetPin

Reglas:
- No toca dbo.Usuarios ni dbo.SEG_Usuarios
- No toca caja/cobranza
- No aplica PagoContrato a recibos
- No liquida combustible
- UsuarioMobile pertenece al chofer y ya no depende de contrato fijo
- La columna flota.UsuarioMobile.Id_Contrato queda obsoleta y sin uso
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

IF OBJECT_ID('flota.chofer','U') IS NULL
BEGIN
    RAISERROR('No existe flota.chofer.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.UsuarioMobile','Id_Contrato') IS NOT NULL
   AND EXISTS
   (
       SELECT 1
       FROM sys.columns c
       WHERE c.object_id = OBJECT_ID('flota.UsuarioMobile')
         AND c.name = 'Id_Contrato'
         AND c.is_nullable = 0
   )
BEGIN
    ALTER TABLE flota.UsuarioMobile ALTER COLUMN Id_Contrato INT NULL;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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
        ISNULL(ch.Documento,'') AS DocumentoChofer,
        ISNULL(u.FlgEstado,'A') AS FlgEstado,
        u.Fec_Creacion,
        u.Fec_UltimoLogin
    FROM flota.UsuarioMobile u
    LEFT JOIN flota.chofer ch
        ON ch.Id_Chofer = u.Id_Chofer
       AND ch.id_empresa = u.id_empresa
       AND ch.id_est = u.id_est
    WHERE u.id_empresa = @IdEmpresa
      AND u.id_est = @IdEst
    ORDER BY u.IdUsuarioMobile DESC;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('flota.p_UsuarioMobile_CrearAdmin','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_UsuarioMobile_CrearAdmin AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_UsuarioMobile_CrearAdmin
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdChofer INT,
    @Telefono VARCHAR(20),
    @Nombre VARCHAR(150),
    @PasswordHash VARCHAR(300),
    @PasswordSalt VARCHAR(100),
    @FlgEstado VARCHAR(1),
    @Usuario INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUsuarioMobile INT = 0;

    SET @Telefono = LTRIM(RTRIM(ISNULL(@Telefono,'')));
    SET @Nombre = LTRIM(RTRIM(ISNULL(@Nombre,'')));
    SET @PasswordHash = LTRIM(RTRIM(ISNULL(@PasswordHash,'')));
    SET @PasswordSalt = LTRIM(RTRIM(ISNULL(@PasswordSalt,'')));
    SET @FlgEstado = UPPER(LTRIM(RTRIM(ISNULL(@FlgEstado,'A'))));

    IF @IdChofer <= 0
    BEGIN
        SELECT 0 AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'IdChofer invalido.' AS Mensaje;
        RETURN;
    END;

    IF @Telefono = ''
    BEGIN
        SELECT 0 AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'Telefono obligatorio.' AS Mensaje;
        RETURN;
    END;

    IF @Nombre = ''
    BEGIN
        SELECT 0 AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'Nombre obligatorio.' AS Mensaje;
        RETURN;
    END;

    IF @PasswordHash = '' OR @PasswordSalt = ''
    BEGIN
        SELECT 0 AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'PasswordHash y PasswordSalt son obligatorios.' AS Mensaje;
        RETURN;
    END;

    IF @FlgEstado NOT IN ('A','X')
    BEGIN
        SELECT 0 AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'FlgEstado invalido. Usa A o X.' AS Mensaje;
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
        SELECT 0 AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'Chofer no encontrado.' AS Mensaje;
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM flota.UsuarioMobile u
        WHERE u.id_empresa = @IdEmpresa
          AND u.id_est = @IdEst
          AND u.Telefono = @Telefono
          AND ISNULL(u.FlgEstado,'A') = 'A'
    )
    BEGIN
        SELECT 0 AS IdUsuarioMobile,@Telefono AS Telefono,'' AS FlgEstado,'Ya existe un usuario mobile activo con ese telefono.' AS Mensaje;
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM flota.UsuarioMobile u
        WHERE u.id_empresa = @IdEmpresa
          AND u.id_est = @IdEst
          AND u.Id_Chofer = @IdChofer
          AND ISNULL(u.FlgEstado,'A') = 'A'
    )
    BEGIN
        SELECT 0 AS IdUsuarioMobile,@Telefono AS Telefono,'' AS FlgEstado,'Ya existe un usuario mobile activo para ese chofer.' AS Mensaje;
        RETURN;
    END;

    INSERT INTO flota.UsuarioMobile
    (
        id_empresa,
        id_est,
        Id_Chofer,
        Telefono,
        Nombre,
        PasswordHash,
        PasswordSalt,
        FlgEstado,
        Usu_Creacion,
        Fec_Creacion
    )
    VALUES
    (
        @IdEmpresa,
        @IdEst,
        @IdChofer,
        @Telefono,
        @Nombre,
        @PasswordHash,
        @PasswordSalt,
        @FlgEstado,
        @Usuario,
        GETUTCDATE()
    );

    SET @IdUsuarioMobile = SCOPE_IDENTITY();

    SELECT
        u.IdUsuarioMobile,
        u.Telefono,
        ISNULL(u.FlgEstado,'A') AS FlgEstado,
        'Usuario mobile creado correctamente.' AS Mensaje
    FROM flota.UsuarioMobile u
    WHERE u.IdUsuarioMobile = @IdUsuarioMobile
      AND u.id_empresa = @IdEmpresa
      AND u.id_est = @IdEst;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('flota.p_UsuarioMobile_ActualizarAdmin','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_UsuarioMobile_ActualizarAdmin AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_UsuarioMobile_ActualizarAdmin
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdUsuarioMobile INT,
    @IdChofer INT,
    @Telefono VARCHAR(20),
    @Nombre VARCHAR(150),
    @FlgEstado VARCHAR(1),
    @Usuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Telefono = LTRIM(RTRIM(ISNULL(@Telefono,'')));
    SET @Nombre = LTRIM(RTRIM(ISNULL(@Nombre,'')));
    SET @FlgEstado = UPPER(LTRIM(RTRIM(ISNULL(@FlgEstado,'A'))));

    IF @IdUsuarioMobile <= 0
    BEGIN
        SELECT 0 AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'IdUsuarioMobile invalido.' AS Mensaje;
        RETURN;
    END;

    IF @IdChofer <= 0
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'IdChofer invalido.' AS Mensaje;
        RETURN;
    END;

    IF @Telefono = ''
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'Telefono obligatorio.' AS Mensaje;
        RETURN;
    END;

    IF @Nombre = ''
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'Nombre obligatorio.' AS Mensaje;
        RETURN;
    END;

    IF @FlgEstado NOT IN ('A','X')
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'FlgEstado invalido. Usa A o X.' AS Mensaje;
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.UsuarioMobile u
        WHERE u.IdUsuarioMobile = @IdUsuarioMobile
          AND u.id_empresa = @IdEmpresa
          AND u.id_est = @IdEst
    )
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'Usuario mobile no encontrado.' AS Mensaje;
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
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'Chofer no encontrado.' AS Mensaje;
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM flota.UsuarioMobile u
        WHERE u.id_empresa = @IdEmpresa
          AND u.id_est = @IdEst
          AND u.Telefono = @Telefono
          AND u.IdUsuarioMobile <> @IdUsuarioMobile
          AND ISNULL(u.FlgEstado,'A') = 'A'
    )
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,@Telefono AS Telefono,'' AS FlgEstado,'Ya existe otro usuario mobile activo con ese telefono.' AS Mensaje;
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM flota.UsuarioMobile u
        WHERE u.id_empresa = @IdEmpresa
          AND u.id_est = @IdEst
          AND u.Id_Chofer = @IdChofer
          AND u.IdUsuarioMobile <> @IdUsuarioMobile
          AND ISNULL(u.FlgEstado,'A') = 'A'
    )
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,@Telefono AS Telefono,'' AS FlgEstado,'Ya existe otro usuario mobile activo para ese chofer.' AS Mensaje;
        RETURN;
    END;

    UPDATE flota.UsuarioMobile
    SET Id_Chofer = @IdChofer,
        Telefono = @Telefono,
        Nombre = @Nombre,
        FlgEstado = @FlgEstado
    WHERE IdUsuarioMobile = @IdUsuarioMobile
      AND id_empresa = @IdEmpresa
      AND id_est = @IdEst;

    SELECT
        u.IdUsuarioMobile,
        u.Telefono,
        ISNULL(u.FlgEstado,'A') AS FlgEstado,
        'Usuario mobile actualizado correctamente.' AS Mensaje
    FROM flota.UsuarioMobile u
    WHERE u.IdUsuarioMobile = @IdUsuarioMobile
      AND u.id_empresa = @IdEmpresa
      AND u.id_est = @IdEst;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('flota.p_UsuarioMobile_CambiarEstado','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_UsuarioMobile_CambiarEstado AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_UsuarioMobile_CambiarEstado
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdUsuarioMobile INT,
    @FlgEstado VARCHAR(1),
    @Usuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SET @FlgEstado = UPPER(LTRIM(RTRIM(ISNULL(@FlgEstado,''))));

    IF @IdUsuarioMobile <= 0
    BEGIN
        SELECT 0 AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'IdUsuarioMobile invalido.' AS Mensaje;
        RETURN;
    END;

    IF @FlgEstado NOT IN ('A','X')
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'FlgEstado invalido. Usa A o X.' AS Mensaje;
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.UsuarioMobile u
        WHERE u.IdUsuarioMobile = @IdUsuarioMobile
          AND u.id_empresa = @IdEmpresa
          AND u.id_est = @IdEst
    )
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'Usuario mobile no encontrado.' AS Mensaje;
        RETURN;
    END;

    UPDATE flota.UsuarioMobile
    SET FlgEstado = @FlgEstado
    WHERE IdUsuarioMobile = @IdUsuarioMobile
      AND id_empresa = @IdEmpresa
      AND id_est = @IdEst;

    SELECT
        u.IdUsuarioMobile,
        u.Telefono,
        ISNULL(u.FlgEstado,'A') AS FlgEstado,
        CASE WHEN @FlgEstado = 'A'
             THEN 'Usuario mobile activado correctamente.'
             ELSE 'Usuario mobile inactivado correctamente.'
        END AS Mensaje
    FROM flota.UsuarioMobile u
    WHERE u.IdUsuarioMobile = @IdUsuarioMobile
      AND u.id_empresa = @IdEmpresa
      AND u.id_est = @IdEst;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('flota.p_UsuarioMobile_CambiarContrato','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_UsuarioMobile_CambiarContrato AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_UsuarioMobile_CambiarContrato
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdUsuarioMobile INT,
    @IdContrato INT = NULL,
    @Usuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @IdUsuarioMobile AS IdUsuarioMobile,
        '' AS Telefono,
        '' AS FlgEstado,
        'Operacion obsoleta. Usuario mobile ya no maneja contrato fijo.' AS Mensaje;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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

    SET @PasswordHash = LTRIM(RTRIM(ISNULL(@PasswordHash,'')));
    SET @PasswordSalt = LTRIM(RTRIM(ISNULL(@PasswordSalt,'')));

    IF @IdUsuarioMobile <= 0
    BEGIN
        SELECT 0 AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'IdUsuarioMobile invalido.' AS Mensaje;
        RETURN;
    END;

    IF @PasswordHash = '' OR @PasswordSalt = ''
    BEGIN
        SELECT @IdUsuarioMobile AS IdUsuarioMobile,'' AS Telefono,'' AS FlgEstado,'PasswordHash y PasswordSalt son obligatorios.' AS Mensaje;
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.UsuarioMobile u
        WHERE u.IdUsuarioMobile = @IdUsuarioMobile
          AND u.id_empresa = @IdEmpresa
          AND u.id_est = @IdEst
    )
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
        u.IdUsuarioMobile,
        u.Telefono,
        ISNULL(u.FlgEstado,'A') AS FlgEstado,
        'PIN mobile reseteado correctamente.' AS Mensaje
    FROM flota.UsuarioMobile u
    WHERE u.IdUsuarioMobile = @IdUsuarioMobile
      AND u.id_empresa = @IdEmpresa
      AND u.id_est = @IdEst;
END;
GO

SET NOEXEC OFF;
GO
