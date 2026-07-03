IF DB_NAME() <> 'db_9fa64e_adminfg'
BEGIN
    RAISERROR('Este seed solo debe ejecutarse en db_9fa64e_adminfg.',16,1);
    RETURN;
END
GO

DECLARE @IdUsuarioMobile INT;
DECLARE @Mensaje VARCHAR(300);

EXEC flota.p_UsuarioMobile_RegistrarTemporal
    @IdEmpresa = 6,
    @IdEst = '4',
    @IdChofer = 3,
    @IdContrato = 4,
    @Telefono = '999888777',
    @Nombre = 'Usuario Mobile Prueba',
    @PasswordHash = 'O+QkqqoAvoxDF2h5HZdGRyb2znWLnBA2sKJZ9iaIQFg=',
    @PasswordSalt = 'IIEAUbHezbgRYVbOPgBCrQ==',
    @Usuario = 1007,
    @IdUsuarioMobile = @IdUsuarioMobile OUTPUT,
    @Mensaje = @Mensaje OUTPUT;

SELECT @IdUsuarioMobile AS IdUsuarioMobile, @Mensaje AS Mensaje;
GO
