/*
FASE 1 URGENTE FLOTA - FINALIZAR CONTRATO
Base objetivo: DB_9FA64E_bdgas

Reglas:
- No borrar contratos
- No borrar recibos
- No tocar pagos
- No tocar caja/cobranza
- No aplicar PagoContrato a ReciboAlquiler
- No liquidar combustible

Convencion usada:
- Flg_Estado = 'A' activo
- Flg_Estado = 'C' cerrado

Observacion:
- En la data auditada hoy solo se encontro 'A'.
- Se usa 'C' como codigo controlado de cierre por no existir catalogo de estados.
*/

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en DB_9FA64E_bdgas.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.contrato','U') IS NULL
BEGIN
    RAISERROR('No existe flota.contrato.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.contrato','Flg_Estado') IS NULL
BEGIN
    RAISERROR('flota.contrato no tiene columna Flg_Estado.',16,1);
    SET NOEXEC ON;
END;
GO

IF EXISTS (SELECT 1 FROM flota.contrato WHERE Flg_Estado NOT IN ('A','C'))
BEGIN
    RAISERROR('Se detectaron estados de contrato no esperados. Revisar antes de continuar.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.p_contrato_finalizar','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_contrato_finalizar AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_contrato_finalizar
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @FechaFin DATE,
    @MotivoCierre VARCHAR(2),
    @Observacion VARCHAR(250),
    @Usuario INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaInicio DATE;
    DECLARE @EstadoActual VARCHAR(1);
    DECLARE @ObservacionActual VARCHAR(300);
    DECLARE @Mensaje VARCHAR(250);

    SELECT
        @FechaInicio = c.FechaInicio,
        @EstadoActual = c.Flg_Estado,
        @ObservacionActual = c.Observacion
    FROM flota.contrato c
    WHERE c.Id_Contrato = @IdContrato
      AND c.id_empresa = @IdEmpresa
      AND c.id_est = @IdEst;

    IF @FechaInicio IS NULL
    BEGIN
        SELECT 0 AS IdContrato,'' AS Flg_Estado,CAST(NULL AS DATE) AS FechaFin,'Contrato no encontrado para el tenant indicado.' AS Mensaje;
        RETURN;
    END;

    IF ISNULL(@EstadoActual,'') <> 'A'
    BEGIN
        SELECT @IdContrato AS IdContrato,@EstadoActual AS Flg_Estado,@FechaFin AS FechaFin,'Solo se puede cerrar un contrato activo.' AS Mensaje;
        RETURN;
    END;

    IF @FechaFin IS NULL
    BEGIN
        SELECT @IdContrato AS IdContrato,@EstadoActual AS Flg_Estado,CAST(NULL AS DATE) AS FechaFin,'FechaFin es obligatoria.' AS Mensaje;
        RETURN;
    END;

    IF @FechaFin < @FechaInicio
    BEGIN
        SELECT @IdContrato AS IdContrato,@EstadoActual AS Flg_Estado,@FechaFin AS FechaFin,'La fecha de cierre no puede ser menor que la fecha de inicio.' AS Mensaje;
        RETURN;
    END;

    SET @MotivoCierre = UPPER(LTRIM(RTRIM(ISNULL(@MotivoCierre,''))));
    SET @Observacion = LTRIM(RTRIM(ISNULL(@Observacion,'')));

    SET @Mensaje = 'CIERRE [' + CASE WHEN @MotivoCierre='' THEN '--' ELSE @MotivoCierre END + '] ' +
                   CONVERT(VARCHAR(10),@FechaFin,120) + ' Usuario=' + CONVERT(VARCHAR(20),@Usuario);

    IF @Observacion <> ''
        SET @Mensaje = @Mensaje + ' Obs=' + @Observacion;

    UPDATE flota.contrato
    SET FechaFin = @FechaFin,
        Flg_Estado = 'C',
        Observacion = CASE
            WHEN ISNULL(LTRIM(RTRIM(@ObservacionActual)),'') = '' THEN @Mensaje
            ELSE LEFT(@ObservacionActual + ' | ' + @Mensaje,300)
        END
    WHERE Id_Contrato = @IdContrato
      AND id_empresa = @IdEmpresa
      AND id_est = @IdEst;

    SELECT
        Id_Contrato AS IdContrato,
        Flg_Estado,
        FechaFin,
        'Contrato cerrado correctamente.' AS Mensaje
    FROM flota.contrato
    WHERE Id_Contrato = @IdContrato
      AND id_empresa = @IdEmpresa
      AND id_est = @IdEst;
END;
GO

IF OBJECT_ID('flota.periodicidad_cobro','U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM flota.periodicidad_cobro WHERE Cod_Periodicidad='D')
BEGIN
    INSERT INTO flota.periodicidad_cobro(Cod_Periodicidad,Nombre,Flg_Activo)
    VALUES('D','Diario','S');
END;
GO

IF OBJECT_ID('flota.p_contrato_crear','P') IS NULL
BEGIN
    RAISERROR('No existe flota.p_contrato_crear.',16,1);
    SET NOEXEC ON;
END;
GO

ALTER PROCEDURE flota.p_contrato_crear
    @id_empresa INT,
    @id_est CHAR(2),
    @IdVehiculo INT,
    @IdChofer INT,
    @Modalidad VARCHAR(1),
    @Periodicidad VARCHAR(1)='S',
    @FechaInicio DATE,
    @FechaFin DATE=NULL,
    @TarifaDia DECIMAL(18,2),
    @CobraDomingo BIT=0,
    @ControlKm BIT=0,
    @Observacion VARCHAR(300)=NULL,
    @Usuario INT,
    @Id INT OUTPUT,
    @Mensaje VARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Id = 0;

    SET @Modalidad = UPPER(LTRIM(RTRIM(ISNULL(@Modalidad,''))));
    SET @Periodicidad = UPPER(LTRIM(RTRIM(ISNULL(@Periodicidad,''))));

    IF @Modalidad = 'D' AND @Periodicidad = ''
        SET @Periodicidad = 'D';

    IF @TarifaDia <= 0
    BEGIN
        SET @Mensaje = 'La tarifa debe ser mayor a cero.';
        RETURN;
    END;

    IF NOT EXISTS(SELECT 1 FROM flota.periodicidad_cobro WHERE Cod_Periodicidad=@Periodicidad AND Flg_Activo='S')
    BEGIN
        SET @Mensaje = 'Periodicidad no valida.';
        RETURN;
    END;

    IF EXISTS(SELECT 1 FROM flota.contrato WHERE id_empresa=@id_empresa AND id_est=@id_est AND Id_Vehiculo=@IdVehiculo AND Flg_Estado='A')
    BEGIN
        SET @Mensaje = 'Este vehiculo ya tiene contrato activo. Primero cierre el contrato activo.';
        RETURN;
    END;

    INSERT flota.contrato
    (
        id_empresa,id_est,Id_Vehiculo,Id_Chofer,Cod_Modalidad,Cod_Periodicidad,
        FechaInicio,FechaFin,TarifaDia,Flg_CobraDomingo,Flg_ControlKm,Observacion,Usu_Creacion,Fec_Creacion,Flg_Estado
    )
    VALUES
    (
        @id_empresa,@id_est,@IdVehiculo,@IdChofer,@Modalidad,@Periodicidad,
        @FechaInicio,@FechaFin,@TarifaDia,
        CASE WHEN @CobraDomingo=1 THEN 'S' ELSE 'N' END,
        CASE WHEN @ControlKm=1 THEN 'S' ELSE 'N' END,
        @Observacion,@Usuario,GETUTCDATE(),'A'
    );

    SET @Id = SCOPE_IDENTITY();

    UPDATE flota.contrato
    SET Numero='ALQ-'+RIGHT('000000'+CONVERT(VARCHAR(6),@Id),6)
    WHERE Id_Contrato=@Id;

    SET @Mensaje = 'Contrato creado.';
END;
GO
