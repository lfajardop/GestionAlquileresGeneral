/*
PLANTILLA DE ALTA INICIAL DE MAESTROS FLOTA PILOTO - PRODUCCION

Objetivo:
- Crear vehiculo
- Crear chofer
- Crear contrato
- Devolver IDs generados

Importante:
- NO crea UsuarioMobile.
- NO toca caja/cobranza.
- NO toca pagos.
- NO aplica PagoContrato a recibos.
- NO liquida.
- Requiere completar los datos reales antes de ejecutar.
- Debe ejecutarse solo despues de los scripts estructurales PROD:
  20260706_flota_fase2_mobile_captura_PROD.sql
  20260706A_flota_pagocontrato_filtros_admin_PROD.sql
  20260707_flota_usuario_mobile_PROD.sql
  20260707B_flota_combustible_operacion_PROD.sql
  20260707C_flota_operacion_dia_horas_PROD.sql
  20260707D_flota_pagocontrato_edicion_mobile_PROD.sql
*/

DECLARE @IdEmpresa INT = 6;
DECLARE @IdEst CHAR(2) = '4';
DECLARE @Usuario INT = 1007;

-- VEHICULO
DECLARE @Placa VARCHAR(20) = 'COMPLETAR';
DECLARE @Marca VARCHAR(80) = 'COMPLETAR';
DECLARE @Modelo VARCHAR(80) = 'COMPLETAR';
DECLARE @Anio INT = NULL;
DECLARE @Color VARCHAR(50) = NULL;
DECLARE @GalonesTanque DECIMAL(10,3) = NULL;
DECLARE @PrecioGalon DECIMAL(10,2) = NULL;
DECLARE @RendimientoTanqueKm DECIMAL(10,2) = NULL;
DECLARE @Compartido BIT = 0;

-- CHOFER
DECLARE @NombreChofer VARCHAR(150) = 'COMPLETAR';
DECLARE @DocumentoChofer VARCHAR(20) = 'COMPLETAR';
DECLARE @TelefonoChofer VARCHAR(20) = '949222682';
DECLARE @LicenciaChofer VARCHAR(30) = NULL;

-- CONTRATO
DECLARE @IdVehiculo INT = NULL;
DECLARE @IdChofer INT = NULL;
DECLARE @CodModalidad VARCHAR(10) = 'COMPLETAR';
DECLARE @FechaInicio DATE = NULL;
DECLARE @FechaFin DATE = NULL;
DECLARE @TarifaDia DECIMAL(18,2) = NULL;
DECLARE @CodPeriodicidad VARCHAR(10) = 'COMPLETAR';
DECLARE @CobraDomingo BIT = 0;
DECLARE @ControlKm BIT = 0;
DECLARE @ObservacionContrato VARCHAR(300) = 'Piloto mobile Flota.';

DECLARE @IdContrato INT = 0;
DECLARE @MensajeVehiculo VARCHAR(250) = '';
DECLARE @MensajeChofer VARCHAR(250) = '';
DECLARE @MensajeContrato VARCHAR(250) = '';

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en DB_9FA64E_bdgas.', 16, 1);
    SET NOEXEC ON;
END;

IF OBJECT_ID('flota.p_vehiculo_crear', 'P') IS NULL
BEGIN
    RAISERROR('Falta flota.p_vehiculo_crear. Ejecuta primero los scripts estructurales/base.', 16, 1);
    SET NOEXEC ON;
END;

IF OBJECT_ID('flota.p_chofer_crear', 'P') IS NULL
BEGIN
    RAISERROR('Falta flota.p_chofer_crear. Ejecuta primero los scripts estructurales/base.', 16, 1);
    SET NOEXEC ON;
END;

IF OBJECT_ID('flota.p_contrato_crear', 'P') IS NULL
BEGIN
    RAISERROR('Falta flota.p_contrato_crear. Ejecuta primero los scripts estructurales/base.', 16, 1);
    SET NOEXEC ON;
END;

IF OBJECT_ID('flota.vehiculo', 'U') IS NULL
   OR OBJECT_ID('flota.chofer', 'U') IS NULL
   OR OBJECT_ID('flota.contrato', 'U') IS NULL
BEGIN
    RAISERROR('Faltan tablas base de Flota. Ejecuta primero los scripts estructurales/base.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@Placa, ''))) = '' OR @Placa = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @Placa.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@Marca, ''))) = '' OR @Marca = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @Marca.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@Modelo, ''))) = '' OR @Modelo = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @Modelo.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@NombreChofer, ''))) = '' OR @NombreChofer = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @NombreChofer.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@DocumentoChofer, ''))) = '' OR @DocumentoChofer = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @DocumentoChofer.', 16, 1);
    SET NOEXEC ON;
END;

IF @FechaInicio IS NULL
BEGIN
    RAISERROR('Completa @FechaInicio.', 16, 1);
    SET NOEXEC ON;
END;

IF @TarifaDia IS NULL OR @TarifaDia <= 0
BEGIN
    RAISERROR('Completa @TarifaDia con un valor mayor a cero.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@CodModalidad, ''))) = '' OR @CodModalidad = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @CodModalidad.', 16, 1);
    SET NOEXEC ON;
END;

IF LTRIM(RTRIM(ISNULL(@CodPeriodicidad, ''))) = '' OR @CodPeriodicidad = 'COMPLETAR'
BEGIN
    RAISERROR('Completa @CodPeriodicidad.', 16, 1);
    SET NOEXEC ON;
END;

IF EXISTS
(
    SELECT 1
    FROM flota.vehiculo
    WHERE id_empresa = @IdEmpresa
      AND RTRIM(ISNULL(id_est, '')) = RTRIM(@IdEst)
      AND UPPER(LTRIM(RTRIM(Placa))) = UPPER(LTRIM(RTRIM(@Placa)))
      AND ISNULL(flg_activo, 1) = 1
)
BEGIN
    RAISERROR('Ya existe un vehiculo activo con la misma placa.', 16, 1);
    SET NOEXEC ON;
END;

IF EXISTS
(
    SELECT 1
    FROM flota.chofer
    WHERE id_empresa = @IdEmpresa
      AND RTRIM(ISNULL(id_est, '')) = RTRIM(@IdEst)
      AND
      (
          (LTRIM(RTRIM(ISNULL(@DocumentoChofer, ''))) <> '' AND Documento = @DocumentoChofer)
          OR
          (LTRIM(RTRIM(ISNULL(@TelefonoChofer, ''))) <> '' AND Telefono = @TelefonoChofer)
      )
      AND ISNULL(Activo, 1) = 1
)
BEGIN
    RAISERROR('Ya existe un chofer activo con el mismo documento o telefono.', 16, 1);
    SET NOEXEC ON;
END;

EXEC flota.p_vehiculo_crear
    @id_empresa = @IdEmpresa,
    @id_est = @IdEst,
    @Placa = @Placa,
    @Marca = @Marca,
    @Modelo = @Modelo,
    @Anio = @Anio,
    @Color = @Color,
    @GalonesTanque = @GalonesTanque,
    @PrecioGalon = @PrecioGalon,
    @RendimientoTanqueKm = @RendimientoTanqueKm,
    @Compartido = @Compartido,
    @Usuario = @Usuario,
    @Id = @IdVehiculo OUTPUT,
    @Mensaje = @MensajeVehiculo OUTPUT;

IF ISNULL(@IdVehiculo, 0) <= 0
BEGIN
    RAISERROR('No se pudo crear el vehiculo: %s', 16, 1, @MensajeVehiculo);
    SET NOEXEC ON;
END;

EXEC flota.p_chofer_crear
    @id_empresa = @IdEmpresa,
    @id_est = @IdEst,
    @Documento = @DocumentoChofer,
    @Nombres = @NombreChofer,
    @Telefono = @TelefonoChofer,
    @Licencia = @LicenciaChofer,
    @Usuario = @Usuario,
    @Id = @IdChofer OUTPUT,
    @Mensaje = @MensajeChofer OUTPUT;

IF ISNULL(@IdChofer, 0) <= 0
BEGIN
    RAISERROR('No se pudo crear el chofer: %s', 16, 1, @MensajeChofer);
    SET NOEXEC ON;
END;

EXEC flota.p_contrato_crear
    @id_empresa = @IdEmpresa,
    @id_est = @IdEst,
    @IdVehiculo = @IdVehiculo,
    @IdChofer = @IdChofer,
    @Modalidad = LEFT(@CodModalidad, 1),
    @Periodicidad = LEFT(@CodPeriodicidad, 1),
    @FechaInicio = @FechaInicio,
    @FechaFin = @FechaFin,
    @TarifaDia = @TarifaDia,
    @CobraDomingo = @CobraDomingo,
    @ControlKm = @ControlKm,
    @Observacion = @ObservacionContrato,
    @Usuario = @Usuario,
    @Id = @IdContrato OUTPUT,
    @Mensaje = @MensajeContrato OUTPUT;

IF ISNULL(@IdContrato, 0) <= 0
BEGIN
    RAISERROR('No se pudo crear el contrato: %s', 16, 1, @MensajeContrato);
    SET NOEXEC ON;
END;

SELECT
    @IdVehiculo AS IdVehiculoGenerado,
    @IdChofer AS IdChoferGenerado,
    @IdContrato AS IdContratoGenerado,
    @MensajeVehiculo AS MensajeVehiculo,
    @MensajeChofer AS MensajeChofer,
    @MensajeContrato AS MensajeContrato;

SELECT
    v.Id_Vehiculo,
    v.Placa,
    c.Id_Chofer,
    c.Nombres AS Chofer,
    ct.Id_Contrato,
    ct.Numero AS ContratoNumero,
    ct.Cod_Modalidad,
    ct.Cod_Periodicidad,
    ct.TarifaDia,
    ct.Flg_Estado
FROM flota.contrato ct
INNER JOIN flota.vehiculo v
    ON v.Id_Vehiculo = ct.Id_Vehiculo
INNER JOIN flota.chofer c
    ON c.Id_Chofer = ct.Id_Chofer
WHERE ct.Id_Contrato = @IdContrato;
