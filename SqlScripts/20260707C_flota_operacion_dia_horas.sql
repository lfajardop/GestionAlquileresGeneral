SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
Etapa 2.5A - Horas reales, inicio/fin mobile y correccion admin basica

Solo desarrollo:
- db_9fa64e_adminfg

No tocar:
- DB_9FA64E_bdgas
- caja/cobranza

Reglas:
- Fecha sigue siendo el dia operativo.
- FechaHoraInicio y FechaHoraFin guardan la hora real reportada.
- Los campos de sistema siguen usando GETUTCDATE().
- Los campos de negocio FechaHoraInicio/FechaHoraFin se reciben desde aplicacion.
*/
GO

IF DB_NAME() <> 'db_9fa64e_adminfg'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en db_9fa64e_adminfg.',16,1);
    SET NOEXEC ON;
END;
GO

IF SCHEMA_ID('flota') IS NULL
BEGIN
    RAISERROR('No existe schema flota.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.operacion_dia','U') IS NULL
BEGIN
    RAISERROR('No existe flota.operacion_dia.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.operacion_dia','FechaHoraInicio') IS NULL
BEGIN
    ALTER TABLE flota.operacion_dia ADD FechaHoraInicio DATETIME NULL;
END;
GO

IF COL_LENGTH('flota.operacion_dia','FechaHoraFin') IS NULL
BEGIN
    ALTER TABLE flota.operacion_dia ADD FechaHoraFin DATETIME NULL;
END;
GO

IF OBJECT_ID('flota.p_AdminCalendario_Obtener','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_AdminCalendario_Obtener AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_AdminCalendario_Obtener
    @id_empresa INT,
    @id_est CHAR(2),
    @IdContrato INT,
    @Anio INT,
    @Mes INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Id_Contrato,
        c.Numero,
        v.Placa,
        ISNULL(v.MarcaTexto,'') + ' ' + ISNULL(v.ModeloTexto,'') AS Vehiculo,
        ISNULL(ch.Nombres,'') AS Chofer,
        c.Cod_Modalidad,
        c.TarifaDia,
        c.Cod_Periodicidad
    FROM flota.contrato c
    JOIN flota.vehiculo v ON v.Id_Vehiculo = c.Id_Vehiculo
    JOIN flota.chofer ch ON ch.Id_Chofer = c.Id_Chofer
    WHERE c.Id_Contrato = @IdContrato
      AND c.id_empresa = @id_empresa
      AND c.id_est = @id_est;

    SELECT
        o.Id_OperacionDia,
        o.Fecha,
        o.FechaHoraInicio,
        o.FechaHoraFin,
        o.Flg_Trabajo,
        o.Cod_Motivo,
        m.Nombre AS Motivo,
        o.Flg_Cobrable,
        o.ImporteGenerado,
        o.KmInicial,
        o.KmFinal,
        ISNULL(o.KmRecorrido,0) AS KmRecorrido,
        o.Observacion,
        o.FlgOrigen,
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM flota.ReciboAlquilerDetalleDia d
                JOIN flota.ReciboAlquiler r ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
                WHERE d.Id_OperacionDia = o.Id_OperacionDia
                  AND r.Estado <> 'X'
            ) THEN 'S' ELSE 'N'
        END AS TieneRecibo
    FROM flota.operacion_dia o
    JOIN flota.motivo_dia m ON m.Cod_Motivo = o.Cod_Motivo
    WHERE o.Id_Contrato = @IdContrato
      AND YEAR(o.Fecha) = @Anio
      AND MONTH(o.Fecha) = @Mes
    ORDER BY o.Fecha;

    SELECT Cod_MedioPago AS Codigo, Nombre
    FROM flota.medio_pago_alquiler
    WHERE Flg_Activo = 'S'
    ORDER BY Nombre;
END;
GO

IF OBJECT_ID('flota.p_OperacionDia_Mobile_Obtener','P') IS NULL
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
        od.FechaHoraInicio,
        od.FechaHoraFin,
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
END;
GO

IF OBJECT_ID('flota.p_OperacionDia_Mobile_Guardar','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_OperacionDia_Mobile_Guardar AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_OperacionDia_Mobile_Guardar
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @Fecha DATE,
    @ModoRegistro VARCHAR(1) = NULL,
    @FlgTrabajo VARCHAR(1),
    @CodMotivo VARCHAR(3),
    @FlgCobrable VARCHAR(1),
    @KmInicial DECIMAL(12,2) = NULL,
    @KmFinal DECIMAL(12,2) = NULL,
    @GalonesCargados DECIMAL(12,3) = 0,
    @ImporteCombustible DECIMAL(18,2) = 0,
    @FlgPagoCombustible VARCHAR(1) = NULL,
    @FechaHoraInicio DATETIME = NULL,
    @FechaHoraFin DATETIME = NULL,
    @Observacion VARCHAR(300) = NULL,
    @Usuario INT,
    @IdOperacionDia INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Tarifa DECIMAL(18,2);
    DECLARE @Modalidad VARCHAR(1);
    DECLARE @Domingo VARCHAR(1);
    DECLARE @ControlKm VARCHAR(1);
    DECLARE @CostoKm DECIMAL(18,6);
    DECLARE @ContratoEstado VARCHAR(1);
    DECLARE @IdOperacionExistente INT;
    DECLARE @KmInicialActual DECIMAL(12,2);
    DECLARE @KmFinalActual DECIMAL(12,2);
    DECLARE @FechaHoraInicioActual DATETIME;
    DECLARE @FechaHoraFinActual DATETIME;
    DECLARE @ImporteCombustibleActual DECIMAL(18,2);
    DECLARE @GalonesActuales DECIMAL(12,3);
    DECLARE @FlgPagoCombustibleActual VARCHAR(1);
    DECLARE @FlgTrabajoFinal VARCHAR(1);
    DECLARE @CodMotivoFinal VARCHAR(3);
    DECLARE @FlgCobrableFinal VARCHAR(1);
    DECLARE @KmInicialFinal DECIMAL(12,2);
    DECLARE @KmFinalFinal DECIMAL(12,2);
    DECLARE @FechaHoraInicioFinal DATETIME;
    DECLARE @FechaHoraFinFinal DATETIME;
    DECLARE @ObservacionFinal VARCHAR(300);
    DECLARE @ImporteGeneradoFinal DECIMAL(18,2);
    DECLARE @CostoConsumoFinal DECIMAL(18,2);
    DECLARE @EsDomingo BIT;

    SET @IdOperacionDia = 0;
    SET @Mensaje = '';
    SET @ModoRegistro = UPPER(LTRIM(RTRIM(ISNULL(@ModoRegistro, ''))));
    SET @FlgTrabajo = UPPER(LTRIM(RTRIM(ISNULL(@FlgTrabajo, ''))));
    SET @FlgCobrable = UPPER(LTRIM(RTRIM(ISNULL(@FlgCobrable, ''))));

    IF @IdContrato <= 0
    BEGIN
        SET @Mensaje = 'Contrato invalido.';
        RETURN;
    END;

    IF @ModoRegistro NOT IN ('', 'I', 'F')
    BEGIN
        SET @Mensaje = 'ModoRegistro invalido.';
        RETURN;
    END;

    IF @ModoRegistro = ''
        SET @ModoRegistro = CASE WHEN @KmFinal IS NOT NULL THEN 'F' ELSE 'I' END;

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
        @Tarifa = c.TarifaDia,
        @Modalidad = c.Cod_Modalidad,
        @Domingo = c.Flg_CobraDomingo,
        @ControlKm = c.Flg_ControlKm,
        @ContratoEstado = c.Flg_Estado,
        @CostoKm = CASE WHEN ISNULL(v.RendimientoTanqueKm,0) > 0 THEN (ISNULL(v.GalonesTanque,0) * ISNULL(v.PrecioGalon,0)) / v.RendimientoTanqueKm ELSE 0 END
    FROM flota.contrato c
    INNER JOIN flota.vehiculo v ON v.Id_Vehiculo = c.Id_Vehiculo
    WHERE c.Id_Contrato = @IdContrato
      AND c.id_empresa = @IdEmpresa
      AND c.id_est = @IdEst;

    IF @Tarifa IS NULL
    BEGIN
        SET @Mensaje = 'Contrato no encontrado.';
        RETURN;
    END;

    IF @ContratoEstado <> 'A'
    BEGIN
        SET @Mensaje = 'El contrato no esta activo.';
        RETURN;
    END;

    IF @KmInicial IS NOT NULL AND @KmInicial < 0
    BEGIN
        SET @Mensaje = 'Km inicial invalido.';
        RETURN;
    END;

    IF @KmFinal IS NOT NULL AND @KmFinal < 0
    BEGIN
        SET @Mensaje = 'Km final invalido.';
        RETURN;
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

    SELECT
        @IdOperacionExistente = od.Id_OperacionDia,
        @KmInicialActual = od.KmInicial,
        @KmFinalActual = od.KmFinal,
        @FechaHoraInicioActual = od.FechaHoraInicio,
        @FechaHoraFinActual = od.FechaHoraFin,
        @ImporteCombustibleActual = od.ImporteCombustible,
        @GalonesActuales = od.GalonesCargados,
        @FlgPagoCombustibleActual = od.Flg_PagoCombustible
    FROM flota.operacion_dia od
    WHERE od.Id_Contrato = @IdContrato
      AND od.Fecha = @Fecha
      AND od.id_empresa = @IdEmpresa
      AND od.id_est = @IdEst;

    IF @ModoRegistro = 'I'
    BEGIN
        IF @KmInicial IS NULL
        BEGIN
            SET @Mensaje = 'Ingresa el km inicial.';
            RETURN;
        END;

        SET @KmInicialFinal = @KmInicial;
        SET @KmFinalFinal = @KmFinalActual;
        SET @FechaHoraInicioFinal = ISNULL(@FechaHoraInicio, @FechaHoraInicioActual);
        SET @FechaHoraFinFinal = @FechaHoraFinActual;
    END;
    ELSE
    BEGIN
        IF @IdOperacionExistente IS NULL OR @KmInicialActual IS NULL
        BEGIN
            SET @Mensaje = 'Primero registra el km inicial.';
            RETURN;
        END;

        IF @KmFinal IS NULL
        BEGIN
            SET @Mensaje = 'Ingresa el km final.';
            RETURN;
        END;

        IF @KmFinal < @KmInicialActual
        BEGIN
            SET @Mensaje = 'El km final no puede ser menor que el km inicial.';
            RETURN;
        END;

        SET @KmInicialFinal = @KmInicialActual;
        SET @KmFinalFinal = @KmFinal;
        SET @FechaHoraInicioFinal = @FechaHoraInicioActual;
        SET @FechaHoraFinFinal = ISNULL(@FechaHoraFin, @FechaHoraFinActual);
    END;

    IF @ControlKm = 'S' AND @FlgTrabajo = 'S'
    BEGIN
        IF @KmInicialFinal IS NULL
        BEGIN
            SET @Mensaje = 'Ingresa el km inicial.';
            RETURN;
        END;

        IF @ModoRegistro = 'F' AND @KmFinalFinal IS NULL
        BEGIN
            SET @Mensaje = 'Ingresa el km final.';
            RETURN;
        END;

        IF @KmFinalFinal IS NOT NULL AND @KmFinalFinal < @KmInicialFinal
        BEGIN
            SET @Mensaje = 'El km final no puede ser menor que el km inicial.';
            RETURN;
        END;
    END;

    SET @FlgTrabajoFinal = @FlgTrabajo;
    SET @CodMotivoFinal = @CodMotivo;
    SET @FlgCobrableFinal = @FlgCobrable;
    SET @ObservacionFinal = @Observacion;
    SET @EsDomingo = CASE WHEN DATEDIFF(DAY,'19000107',@Fecha)%7 = 0 THEN 1 ELSE 0 END;
    SET @ImporteGeneradoFinal =
        CASE
            WHEN @FlgCobrableFinal = 'N' THEN 0
            WHEN @Modalidad = 'L' AND @EsDomingo = 1 AND @Domingo = 'N' THEN 0
            WHEN @Modalidad = 'D' AND @FlgTrabajoFinal = 'N' THEN 0
            ELSE @Tarifa
        END;
    SET @CostoConsumoFinal = ROUND(ISNULL(@KmFinalFinal - @KmInicialFinal, 0) * ISNULL(@CostoKm, 0), 2);

    IF @IdOperacionExistente IS NULL
    BEGIN
        INSERT INTO flota.operacion_dia
        (
            id_empresa,id_est,Id_Contrato,Fecha,Flg_Trabajo,Cod_Motivo,Flg_Cobrable,
            ImporteGenerado,KmInicial,KmFinal,ImporteCombustible,GalonesCargados,Flg_PagoCombustible,
            CostoConsumoEstimado,Observacion,FechaHoraInicio,FechaHoraFin,Usu_Creacion,Fec_Creacion
        )
        VALUES
        (
            @IdEmpresa,@IdEst,@IdContrato,@Fecha,@FlgTrabajoFinal,@CodMotivoFinal,
            CASE WHEN @ImporteGeneradoFinal > 0 THEN 'S' ELSE 'N' END,
            @ImporteGeneradoFinal,@KmInicialFinal,@KmFinalFinal,
            @ImporteCombustible,@GalonesCargados,@FlgPagoCombustible,
            @CostoConsumoFinal,@ObservacionFinal,@FechaHoraInicioFinal,@FechaHoraFinFinal,@Usuario,GETUTCDATE()
        );

        SET @IdOperacionDia = SCOPE_IDENTITY();
    END;
    ELSE
    BEGIN
        UPDATE flota.operacion_dia
        SET Flg_Trabajo = @FlgTrabajoFinal,
            Cod_Motivo = @CodMotivoFinal,
            Flg_Cobrable = CASE WHEN @ImporteGeneradoFinal > 0 THEN 'S' ELSE 'N' END,
            ImporteGenerado = @ImporteGeneradoFinal,
            KmInicial = @KmInicialFinal,
            KmFinal = @KmFinalFinal,
            CostoConsumoEstimado = @CostoConsumoFinal,
            Observacion = @ObservacionFinal,
            FechaHoraInicio = @FechaHoraInicioFinal,
            FechaHoraFin = @FechaHoraFinFinal,
            Usu_Modif = @Usuario,
            Fec_Modif = GETUTCDATE()
        WHERE Id_OperacionDia = @IdOperacionExistente
          AND id_empresa = @IdEmpresa
          AND id_est = @IdEst;

        SET @IdOperacionDia = @IdOperacionExistente;
    END;

    SET @Mensaje = CASE WHEN @ModoRegistro = 'I' THEN 'Inicio registrado correctamente.' ELSE 'Fin registrado correctamente.' END;
END;
GO

IF OBJECT_ID('flota.p_OperacionDia_Corregir','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_OperacionDia_Corregir AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_OperacionDia_Corregir
    @id_empresa INT,
    @id_est CHAR(2),
    @IdOperacionDia INT,
    @FlgTrabajo VARCHAR(1),
    @CodMotivo VARCHAR(3),
    @FlgCobrable VARCHAR(1),
    @KmInicial DECIMAL(12,2) = NULL,
    @KmFinal DECIMAL(12,2) = NULL,
    @FechaHoraInicio DATETIME = NULL,
    @FechaHoraFin DATETIME = NULL,
    @Observacion VARCHAR(300) = NULL,
    @Motivo VARCHAR(300),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InicioTran BIT = 0;
    DECLARE @IdContrato INT;
    DECLARE @TarifaDia DECIMAL(18,2);
    DECLARE @Modalidad VARCHAR(1);
    DECLARE @Domingo VARCHAR(1);
    DECLARE @ControlKm VARCHAR(1);
    DECLARE @CostoKm DECIMAL(18,6);
    DECLARE @Fecha DATE;
    DECLARE @KmInicialActual DECIMAL(12,2);
    DECLARE @KmFinalActual DECIMAL(12,2);
    DECLARE @ObservacionActual VARCHAR(300);
    DECLARE @FechaHoraInicioActual DATETIME;
    DECLARE @FechaHoraFinActual DATETIME;
    DECLARE @KmInicialFinal DECIMAL(12,2);
    DECLARE @KmFinalFinal DECIMAL(12,2);
    DECLARE @ObservacionFinal VARCHAR(300);
    DECLARE @FechaHoraInicioFinal DATETIME;
    DECLARE @FechaHoraFinFinal DATETIME;
    DECLARE @ImporteGeneradoNuevo DECIMAL(18,2);
    DECLARE @CostoConsumoNuevo DECIMAL(18,2);
    DECLARE @EsDomingo BIT;
    DECLARE @DatosAntesOperacion VARCHAR(MAX);
    DECLARE @DatosDespuesOperacion VARCHAR(MAX);
    DECLARE @IdReciboLoop INT;

    SET @Mensaje = '';
    SET @FlgTrabajo = UPPER(LTRIM(RTRIM(ISNULL(@FlgTrabajo,''))));
    SET @FlgCobrable = UPPER(LTRIM(RTRIM(ISNULL(@FlgCobrable,''))));

    IF @FlgTrabajo NOT IN ('S','N')
    BEGIN
        SET @Mensaje = 'FlgTrabajo invalido. Valores permitidos: S o N.';
        RETURN;
    END;

    IF @FlgCobrable NOT IN ('S','N')
    BEGIN
        SET @Mensaje = 'FlgCobrable invalido. Valores permitidos: S o N.';
        RETURN;
    END;

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Motivo,''))),'') IS NULL
    BEGIN
        SET @Mensaje = 'El motivo es obligatorio para corregir el dia.';
        RETURN;
    END;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @InicioTran = 1;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION SP_OperacionDiaCorregir;
        END;

        SELECT
            @IdContrato = o.Id_Contrato,
            @Fecha = o.Fecha,
            @KmInicialActual = o.KmInicial,
            @KmFinalActual = o.KmFinal,
            @ObservacionActual = o.Observacion,
            @FechaHoraInicioActual = o.FechaHoraInicio,
            @FechaHoraFinActual = o.FechaHoraFin,
            @DatosAntesOperacion =
                'FlgTrabajo=' + ISNULL(o.Flg_Trabajo,'') +
                ';CodMotivo=' + ISNULL(o.Cod_Motivo,'') +
                ';FlgCobrable=' + ISNULL(o.Flg_Cobrable,'') +
                ';KmInicial=' + ISNULL(CONVERT(VARCHAR(30),o.KmInicial),'') +
                ';KmFinal=' + ISNULL(CONVERT(VARCHAR(30),o.KmFinal),'') +
                ';FechaHoraInicio=' + ISNULL(CONVERT(VARCHAR(19),o.FechaHoraInicio,120),'') +
                ';FechaHoraFin=' + ISNULL(CONVERT(VARCHAR(19),o.FechaHoraFin,120),'') +
                ';ImporteGenerado=' + CONVERT(VARCHAR(30),ISNULL(o.ImporteGenerado,0)) +
                ';Observacion=' + ISNULL(o.Observacion,'')
        FROM flota.operacion_dia o
        WHERE o.Id_OperacionDia = @IdOperacionDia
          AND o.id_empresa = @id_empresa
          AND o.id_est = @id_est;

        IF @IdContrato IS NULL
        BEGIN
            SET @Mensaje = 'Operacion de dia no encontrada para la empresa y estacion indicadas.';
            GOTO FIN_OK;
        END;

        SELECT
            @TarifaDia = c.TarifaDia,
            @Modalidad = c.Cod_Modalidad,
            @Domingo = c.Flg_CobraDomingo,
            @ControlKm = c.Flg_ControlKm,
            @CostoKm = CASE WHEN ISNULL(v.RendimientoTanqueKm,0) > 0 THEN (ISNULL(v.GalonesTanque,0) * ISNULL(v.PrecioGalon,0)) / v.RendimientoTanqueKm ELSE 0 END
        FROM flota.contrato c
        INNER JOIN flota.vehiculo v ON v.Id_Vehiculo = c.Id_Vehiculo
        WHERE c.Id_Contrato = @IdContrato
          AND c.id_empresa = @id_empresa
          AND c.id_est = @id_est;

        SET @KmInicialFinal = ISNULL(@KmInicial, @KmInicialActual);
        SET @KmFinalFinal = ISNULL(@KmFinal, @KmFinalActual);
        SET @ObservacionFinal = COALESCE(@Observacion, @ObservacionActual);
        SET @FechaHoraInicioFinal = COALESCE(@FechaHoraInicio, @FechaHoraInicioActual);
        SET @FechaHoraFinFinal = COALESCE(@FechaHoraFin, @FechaHoraFinActual);

        IF @KmInicialFinal IS NOT NULL AND @KmInicialFinal < 0
        BEGIN
            SET @Mensaje = 'Km inicial invalido.';
            GOTO FIN_OK;
        END;

        IF @KmFinalFinal IS NOT NULL AND @KmFinalFinal < 0
        BEGIN
            SET @Mensaje = 'Km final invalido.';
            GOTO FIN_OK;
        END;

        IF @KmInicialFinal IS NOT NULL AND @KmFinalFinal IS NOT NULL AND @KmFinalFinal < @KmInicialFinal
        BEGIN
            SET @Mensaje = 'El km final no puede ser menor que el km inicial.';
            GOTO FIN_OK;
        END;

        IF @ControlKm = 'S' AND @FlgTrabajo = 'S' AND (@KmInicialFinal IS NULL OR @KmFinalFinal IS NULL)
        BEGIN
            SET @Mensaje = 'Con control de kilometraje activo, el dia trabajado requiere km inicial y final.';
            GOTO FIN_OK;
        END;

        IF @FechaHoraInicioFinal IS NOT NULL AND @FechaHoraFinFinal IS NOT NULL AND @FechaHoraFinFinal < @FechaHoraInicioFinal
        BEGIN
            SET @Mensaje = 'La hora final no puede ser menor que la hora inicial.';
            GOTO FIN_OK;
        END;

        SET @EsDomingo = CASE WHEN DATEDIFF(DAY,'19000107',@Fecha)%7 = 0 THEN 1 ELSE 0 END;
        SET @ImporteGeneradoNuevo =
            CASE
                WHEN @FlgCobrable = 'N' THEN 0
                WHEN @Modalidad = 'L' AND @EsDomingo = 1 AND @Domingo = 'N' THEN 0
                WHEN @Modalidad = 'D' AND @FlgTrabajo = 'N' THEN 0
                ELSE ISNULL(@TarifaDia,0)
            END;
        SET @CostoConsumoNuevo = ROUND(ISNULL(@KmFinalFinal - @KmInicialFinal,0) * ISNULL(@CostoKm,0),2);

        UPDATE o
           SET o.Flg_Trabajo = @FlgTrabajo,
               o.Cod_Motivo = @CodMotivo,
               o.Flg_Cobrable = CASE WHEN @ImporteGeneradoNuevo > 0 THEN 'S' ELSE 'N' END,
               o.Observacion = @ObservacionFinal,
               o.ImporteGenerado = @ImporteGeneradoNuevo,
               o.KmInicial = @KmInicialFinal,
               o.KmFinal = @KmFinalFinal,
               o.FechaHoraInicio = @FechaHoraInicioFinal,
               o.FechaHoraFin = @FechaHoraFinFinal,
               o.CostoConsumoEstimado = @CostoConsumoNuevo,
               o.Usu_Modif = @Usuario,
               o.Fec_Modif = GETUTCDATE()
        FROM flota.operacion_dia o
        WHERE o.Id_OperacionDia = @IdOperacionDia
          AND o.id_empresa = @id_empresa
          AND o.id_est = @id_est;

        UPDATE d
           SET d.ImporteDia = CASE WHEN @ImporteGeneradoNuevo > 0 THEN d.TarifaDia ELSE 0 END,
               d.Observacion = CASE WHEN @ObservacionFinal IS NULL THEN d.Observacion ELSE @ObservacionFinal END
        FROM flota.ReciboAlquilerDetalleDia d
        INNER JOIN flota.ReciboAlquiler r ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
        WHERE d.Id_OperacionDia = @IdOperacionDia
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND r.Estado <> 'X'
          AND ISNULL(d.FlgEstado,'A') = 'A';

        DECLARE @RecibosAfectados TABLE(IdReciboAlquiler INT NOT NULL PRIMARY KEY);

        INSERT INTO @RecibosAfectados(IdReciboAlquiler)
        SELECT DISTINCT d.Id_ReciboAlquiler
        FROM flota.ReciboAlquilerDetalleDia d
        INNER JOIN flota.ReciboAlquiler r ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
        WHERE d.Id_OperacionDia = @IdOperacionDia
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND r.Estado <> 'X'
          AND ISNULL(d.FlgEstado,'A') = 'A';

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT ra.IdReciboAlquiler FROM @RecibosAfectados ra;

        OPEN cur;
        FETCH NEXT FROM cur INTO @IdReciboLoop;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC flota.p_ReciboAlquiler_Recalcular
                @id_empresa = @id_empresa,
                @id_est = @id_est,
                @IdReciboAlquiler = @IdReciboLoop;

            FETCH NEXT FROM cur INTO @IdReciboLoop;
        END;

        CLOSE cur;
        DEALLOCATE cur;

        SET @DatosDespuesOperacion =
            'FlgTrabajo=' + @FlgTrabajo +
            ';CodMotivo=' + ISNULL(@CodMotivo,'') +
            ';FlgCobrable=' + CASE WHEN @ImporteGeneradoNuevo > 0 THEN 'S' ELSE 'N' END +
            ';KmInicial=' + ISNULL(CONVERT(VARCHAR(30),@KmInicialFinal),'') +
            ';KmFinal=' + ISNULL(CONVERT(VARCHAR(30),@KmFinalFinal),'') +
            ';FechaHoraInicio=' + ISNULL(CONVERT(VARCHAR(19),@FechaHoraInicioFinal,120),'') +
            ';FechaHoraFin=' + ISNULL(CONVERT(VARCHAR(19),@FechaHoraFinFinal,120),'') +
            ';ImporteGenerado=' + CONVERT(VARCHAR(30),@ImporteGeneradoNuevo) +
            ';Observacion=' + ISNULL(@ObservacionFinal,'');

        EXEC flota.p_AuditoriaFlota_Registrar
            @id_empresa = @id_empresa,
            @id_est = @id_est,
            @Entidad = 'OPERACION_DIA',
            @IdEntidad = @IdOperacionDia,
            @Accion = 'CORREGIR',
            @Motivo = @Motivo,
            @DatosAntes = @DatosAntesOperacion,
            @DatosDespues = @DatosDespuesOperacion,
            @Usuario = @Usuario,
            @Origen = 'ADMIN';

FIN_OK:
        IF @InicioTran = 1 AND XACT_STATE() = 1
            COMMIT TRANSACTION;

        IF @Mensaje = ''
            SET @Mensaje = 'Operacion del dia corregida correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SP_OperacionDiaCorregir;
        END;

        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

IF COL_LENGTH('flota.operacion_dia','FechaHoraInicio') IS NULL
    OR COL_LENGTH('flota.operacion_dia','FechaHoraFin') IS NULL
BEGIN
    RAISERROR('Postvalidacion: faltan columnas FechaHoraInicio/FechaHoraFin.',16,1);
    RETURN;
END;
GO

PRINT 'OK: flota.operacion_dia ahora soporta FechaHoraInicio/FechaHoraFin en desarrollo.';
GO
