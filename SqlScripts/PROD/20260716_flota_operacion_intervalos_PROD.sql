SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
Etapa Flota - Operacion por intervalos

Produccion objetivo:
- DB_9FA64E_bdgas

Alcance:
- agrega flota.operacion_dia_intervalo como detalle 1:N de flota.operacion_dia
- permite cruces de medianoche
- permite multiples intervalos cerrados por dia operativo
- solo permite un intervalo abierto simultaneo por contrato/chofer/vehiculo
- no genera recibos automaticos
- no genera deuda automatica
- no toca caja/cobranza
*/
GO

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en DB_9FA64E_bdgas.',16,1);
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

IF OBJECT_ID('flota.contrato','U') IS NULL
BEGIN
    RAISERROR('No existe flota.contrato.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.chofer','U') IS NULL
BEGIN
    RAISERROR('No existe flota.chofer.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.vehiculo','U') IS NULL
BEGIN
    RAISERROR('No existe flota.vehiculo.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.operacion_dia','Id_OperacionDia') IS NULL
    OR COL_LENGTH('flota.operacion_dia','id_empresa') IS NULL
    OR COL_LENGTH('flota.operacion_dia','id_est') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Id_Contrato') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Fecha') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Flg_Trabajo') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Cod_Motivo') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Flg_Cobrable') IS NULL
    OR COL_LENGTH('flota.operacion_dia','ImporteGenerado') IS NULL
    OR COL_LENGTH('flota.operacion_dia','KmInicial') IS NULL
    OR COL_LENGTH('flota.operacion_dia','KmFinal') IS NULL
    OR COL_LENGTH('flota.operacion_dia','KmRecorrido') IS NULL
    OR COL_LENGTH('flota.operacion_dia','ImporteCombustible') IS NULL
    OR COL_LENGTH('flota.operacion_dia','GalonesCargados') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Flg_PagoCombustible') IS NULL
    OR COL_LENGTH('flota.operacion_dia','CostoConsumoEstimado') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Observacion') IS NULL
    OR COL_LENGTH('flota.operacion_dia','FechaHoraInicio') IS NULL
    OR COL_LENGTH('flota.operacion_dia','FechaHoraFin') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Usu_Creacion') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Fec_Creacion') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Usu_Modif') IS NULL
    OR COL_LENGTH('flota.operacion_dia','Fec_Modif') IS NULL
BEGIN
    RAISERROR('Precheck: flota.operacion_dia no tiene todas las columnas requeridas para intervalos.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.contrato','Id_Contrato') IS NULL
    OR COL_LENGTH('flota.contrato','id_empresa') IS NULL
    OR COL_LENGTH('flota.contrato','id_est') IS NULL
    OR COL_LENGTH('flota.contrato','Id_Chofer') IS NULL
    OR COL_LENGTH('flota.contrato','Id_Vehiculo') IS NULL
    OR COL_LENGTH('flota.contrato','Flg_Estado') IS NULL
BEGIN
    RAISERROR('Precheck: flota.contrato no tiene todas las columnas requeridas para intervalos.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.chofer','Id_Chofer') IS NULL
BEGIN
    RAISERROR('Precheck: flota.chofer no tiene Id_Chofer.',16,1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('flota.vehiculo','Id_Vehiculo') IS NULL
BEGIN
    RAISERROR('Precheck: flota.vehiculo no tiene Id_Vehiculo.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.operacion_dia_intervalo','U') IS NULL
BEGIN
    CREATE TABLE flota.operacion_dia_intervalo
    (
        IdIntervalo INT IDENTITY(1,1) NOT NULL,
        id_empresa INT NOT NULL,
        id_est CHAR(2) NOT NULL,
        IdOperacionDia INT NOT NULL,
        IdContrato INT NOT NULL,
        IdChofer INT NOT NULL,
        IdVehiculo INT NOT NULL,
        FechaOperativa DATE NOT NULL,
        FechaHoraInicio DATETIME NOT NULL,
        FechaHoraFin DATETIME NULL,
        KmInicio DECIMAL(12,2) NULL,
        KmFin DECIMAL(12,2) NULL,
        Observacion VARCHAR(300) NULL,
        FlgEstado CHAR(1) NOT NULL CONSTRAINT DF_flota_operacion_dia_intervalo_FlgEstado DEFAULT('A'),
        Usu_Creacion INT NOT NULL,
        Fec_Creacion DATETIME NOT NULL CONSTRAINT DF_flota_operacion_dia_intervalo_FecCreacion DEFAULT(GETUTCDATE()),
        Usu_Modif INT NULL,
        Fec_Modif DATETIME NULL,
        Usu_Anula INT NULL,
        Fec_Anula DATETIME NULL,
        MotivoAnula VARCHAR(250) NULL,
        CONSTRAINT PK_flota_operacion_dia_intervalo PRIMARY KEY CLUSTERED (IdIntervalo)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_flota_operacion_dia_intervalo_operacion_dia')
BEGIN
    ALTER TABLE flota.operacion_dia_intervalo WITH CHECK
    ADD CONSTRAINT FK_flota_operacion_dia_intervalo_operacion_dia
        FOREIGN KEY (IdOperacionDia) REFERENCES flota.operacion_dia(Id_OperacionDia);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_flota_operacion_dia_intervalo_contrato')
BEGIN
    ALTER TABLE flota.operacion_dia_intervalo WITH CHECK
    ADD CONSTRAINT FK_flota_operacion_dia_intervalo_contrato
        FOREIGN KEY (IdContrato) REFERENCES flota.contrato(Id_Contrato);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_flota_operacion_dia_intervalo_chofer')
BEGIN
    ALTER TABLE flota.operacion_dia_intervalo WITH CHECK
    ADD CONSTRAINT FK_flota_operacion_dia_intervalo_chofer
        FOREIGN KEY (IdChofer) REFERENCES flota.chofer(Id_Chofer);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_flota_operacion_dia_intervalo_vehiculo')
BEGIN
    ALTER TABLE flota.operacion_dia_intervalo WITH CHECK
    ADD CONSTRAINT FK_flota_operacion_dia_intervalo_vehiculo
        FOREIGN KEY (IdVehiculo) REFERENCES flota.vehiculo(Id_Vehiculo);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_flota_operacion_dia_intervalo_OperacionDia' AND object_id = OBJECT_ID('flota.operacion_dia_intervalo'))
BEGIN
    CREATE INDEX IX_flota_operacion_dia_intervalo_OperacionDia
        ON flota.operacion_dia_intervalo(IdOperacionDia, FlgEstado, FechaHoraInicio);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_flota_operacion_dia_intervalo_ContratoFecha' AND object_id = OBJECT_ID('flota.operacion_dia_intervalo'))
BEGIN
    CREATE INDEX IX_flota_operacion_dia_intervalo_ContratoFecha
        ON flota.operacion_dia_intervalo(id_empresa, id_est, IdContrato, IdChofer, IdVehiculo, FechaOperativa, FechaHoraInicio);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_flota_operacion_dia_intervalo_abierto' AND object_id = OBJECT_ID('flota.operacion_dia_intervalo'))
BEGIN
    CREATE UNIQUE INDEX UX_flota_operacion_dia_intervalo_abierto
        ON flota.operacion_dia_intervalo(id_empresa, id_est, IdContrato, IdChofer, IdVehiculo)
        WHERE FlgEstado = 'A' AND FechaHoraFin IS NULL;
END;
GO

IF OBJECT_ID('flota.p_OperacionDiaIntervalo_RecalcularCabecera','P') IS NOT NULL
    DROP PROCEDURE flota.p_OperacionDiaIntervalo_RecalcularCabecera;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE flota.p_OperacionDiaIntervalo_RecalcularCabecera
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdOperacionDia INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaHoraInicio DATETIME;
    DECLARE @FechaHoraFin DATETIME;
    DECLARE @KmInicial DECIMAL(12,2);
    DECLARE @KmFinal DECIMAL(12,2);

    SELECT TOP 1
        @FechaHoraInicio = i.FechaHoraInicio,
        @KmInicial = i.KmInicio
    FROM flota.operacion_dia_intervalo i
    WHERE i.id_empresa = @IdEmpresa
      AND i.id_est = @IdEst
      AND i.IdOperacionDia = @IdOperacionDia
      AND i.FlgEstado = 'A'
    ORDER BY i.FechaHoraInicio ASC, i.IdIntervalo ASC;

    SELECT TOP 1
        @FechaHoraFin = i.FechaHoraFin,
        @KmFinal = i.KmFin
    FROM flota.operacion_dia_intervalo i
    WHERE i.id_empresa = @IdEmpresa
      AND i.id_est = @IdEst
      AND i.IdOperacionDia = @IdOperacionDia
      AND i.FlgEstado = 'A'
      AND i.FechaHoraFin IS NOT NULL
    ORDER BY i.FechaHoraFin DESC, i.IdIntervalo DESC;

    UPDATE flota.operacion_dia
    SET FechaHoraInicio = @FechaHoraInicio,
        FechaHoraFin = @FechaHoraFin,
        KmInicial = @KmInicial,
        KmFinal = @KmFinal,
        KmRecorrido = CASE
            WHEN @KmInicial IS NOT NULL AND @KmFinal IS NOT NULL AND @KmFinal >= @KmInicial
                THEN @KmFinal - @KmInicial
            ELSE 0
        END,
        Usu_Modif = CASE WHEN @FechaHoraInicio IS NOT NULL OR @FechaHoraFin IS NOT NULL OR @KmInicial IS NOT NULL OR @KmFinal IS NOT NULL THEN ISNULL(Usu_Modif,Usu_Creacion) ELSE Usu_Modif END,
        Fec_Modif = CASE WHEN @FechaHoraInicio IS NOT NULL OR @FechaHoraFin IS NOT NULL OR @KmInicial IS NOT NULL OR @KmFinal IS NOT NULL THEN GETUTCDATE() ELSE Fec_Modif END
    WHERE Id_OperacionDia = @IdOperacionDia
      AND id_empresa = @IdEmpresa
      AND id_est = @IdEst;
END;
GO

IF OBJECT_ID('flota.p_OperacionDiaIntervalo_Abrir','P') IS NOT NULL
    DROP PROCEDURE flota.p_OperacionDiaIntervalo_Abrir;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE flota.p_OperacionDiaIntervalo_Abrir
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @IdChofer INT,
    @IdVehiculo INT,
    @FechaHoraInicio DATETIME,
    @KmInicio DECIMAL(12,2) = NULL,
    @Observacion VARCHAR(300) = NULL,
    @Usuario INT,
    @IdIntervalo INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaOperativa DATE;
    DECLARE @IdOperacionDia INT;

    SET @IdIntervalo = 0;
    SET @Mensaje = '';
    SET @FechaOperativa = CAST(@FechaHoraInicio AS DATE);

    IF @IdContrato <= 0 OR @IdChofer <= 0 OR @IdVehiculo <= 0
    BEGIN
        SET @Mensaje = 'Completa contrato, chofer y vehiculo.';
        RETURN;
    END;

    IF @FechaHoraInicio IS NULL
    BEGIN
        SET @Mensaje = 'Selecciona la fecha y hora de inicio.';
        RETURN;
    END;

    IF @KmInicio IS NOT NULL AND @KmInicio < 0
    BEGIN
        SET @Mensaje = 'Km inicial invalido.';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM flota.operacion_dia_intervalo i
        WHERE i.id_empresa = @IdEmpresa
          AND i.id_est = @IdEst
          AND i.IdContrato = @IdContrato
          AND i.IdChofer = @IdChofer
          AND i.IdVehiculo = @IdVehiculo
          AND i.FlgEstado = 'A'
          AND i.FechaHoraFin IS NULL
    )
    BEGIN
        SET @Mensaje = 'Ya existe un intervalo abierto. Primero debe cerrar el uso actual.';
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM flota.contrato c
        WHERE c.id_empresa = @IdEmpresa
          AND c.id_est = @IdEst
          AND c.Id_Contrato = @IdContrato
          AND c.Id_Chofer = @IdChofer
          AND c.Id_Vehiculo = @IdVehiculo
          AND ISNULL(c.Flg_Estado,'A') = 'A'
    )
    BEGIN
        SET @Mensaje = 'Contrato no encontrado o inactivo para el chofer y vehiculo indicados.';
        RETURN;
    END;

    SELECT @IdOperacionDia = o.Id_OperacionDia
    FROM flota.operacion_dia o
    WHERE o.id_empresa = @IdEmpresa
      AND o.id_est = @IdEst
      AND o.Id_Contrato = @IdContrato
      AND o.Fecha = @FechaOperativa;

    IF @IdOperacionDia IS NULL
    BEGIN
        INSERT INTO flota.operacion_dia
        (
            id_empresa,id_est,Id_Contrato,Fecha,Flg_Trabajo,Cod_Motivo,Flg_Cobrable,
            ImporteGenerado,KmInicial,KmFinal,KmRecorrido,ImporteCombustible,GalonesCargados,
            Flg_PagoCombustible,CostoConsumoEstimado,Observacion,FechaHoraInicio,FechaHoraFin,
            Usu_Creacion,Fec_Creacion
        )
        VALUES
        (
            @IdEmpresa,@IdEst,@IdContrato,@FechaOperativa,'S','TRA','S',
            0,@KmInicio,NULL,0,0,0,NULL,0,@Observacion,@FechaHoraInicio,NULL,
            @Usuario,GETUTCDATE()
        );

        SET @IdOperacionDia = SCOPE_IDENTITY();
    END;

    INSERT INTO flota.operacion_dia_intervalo
    (
        id_empresa,id_est,IdOperacionDia,IdContrato,IdChofer,IdVehiculo,FechaOperativa,
        FechaHoraInicio,KmInicio,Observacion,FlgEstado,Usu_Creacion,Fec_Creacion
    )
    VALUES
    (
        @IdEmpresa,@IdEst,@IdOperacionDia,@IdContrato,@IdChofer,@IdVehiculo,@FechaOperativa,
        @FechaHoraInicio,@KmInicio,@Observacion,'A',@Usuario,GETUTCDATE()
    );

    SET @IdIntervalo = SCOPE_IDENTITY();

    EXEC flota.p_OperacionDiaIntervalo_RecalcularCabecera
        @IdEmpresa = @IdEmpresa,
        @IdEst = @IdEst,
        @IdOperacionDia = @IdOperacionDia;

    SET @Mensaje = 'Intervalo iniciado correctamente.';
END;
GO

IF OBJECT_ID('flota.p_OperacionDiaIntervalo_Cerrar','P') IS NOT NULL
    DROP PROCEDURE flota.p_OperacionDiaIntervalo_Cerrar;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE flota.p_OperacionDiaIntervalo_Cerrar
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @IdChofer INT,
    @IdVehiculo INT,
    @FechaHoraFin DATETIME,
    @KmFin DECIMAL(12,2) = NULL,
    @Observacion VARCHAR(300) = NULL,
    @Usuario INT,
    @IdIntervalo INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaHoraInicio DATETIME;
    DECLARE @KmInicio DECIMAL(12,2);
    DECLARE @IdOperacionDia INT;
    DECLARE @FechaOperativa DATE;
    DECLARE @TotalHoras DECIMAL(10,2);
    DECLARE @Alerta CHAR(1);
    DECLARE @MensajeHoras VARCHAR(300);

    SET @IdIntervalo = 0;
    SET @Mensaje = '';

    SELECT TOP 1
        @IdIntervalo = i.IdIntervalo,
        @IdOperacionDia = i.IdOperacionDia,
        @FechaHoraInicio = i.FechaHoraInicio,
        @KmInicio = i.KmInicio,
        @FechaOperativa = i.FechaOperativa
    FROM flota.operacion_dia_intervalo i
    WHERE i.id_empresa = @IdEmpresa
      AND i.id_est = @IdEst
      AND i.IdContrato = @IdContrato
      AND i.IdChofer = @IdChofer
      AND i.IdVehiculo = @IdVehiculo
      AND i.FlgEstado = 'A'
      AND i.FechaHoraFin IS NULL
    ORDER BY i.FechaHoraInicio DESC, i.IdIntervalo DESC;

    IF @IdIntervalo IS NULL OR @IdIntervalo = 0
    BEGIN
        SET @Mensaje = 'No existe un intervalo abierto para cerrar.';
        RETURN;
    END;

    IF @FechaHoraFin IS NULL OR @FechaHoraFin <= @FechaHoraInicio
    BEGIN
        SET @Mensaje = 'La fecha/hora fin debe ser mayor que la fecha/hora inicio.';
        RETURN;
    END;

    IF @KmInicio IS NOT NULL AND @KmFin IS NOT NULL AND @KmFin < @KmInicio
    BEGIN
        SET @Mensaje = 'El km final no puede ser menor que el km inicial.';
        RETURN;
    END;

    UPDATE flota.operacion_dia_intervalo
    SET FechaHoraFin = @FechaHoraFin,
        KmFin = @KmFin,
        Observacion = COALESCE(@Observacion, Observacion),
        Usu_Modif = @Usuario,
        Fec_Modif = GETUTCDATE()
    WHERE IdIntervalo = @IdIntervalo
      AND id_empresa = @IdEmpresa
      AND id_est = @IdEst;

    EXEC flota.p_OperacionDiaIntervalo_RecalcularCabecera
        @IdEmpresa = @IdEmpresa,
        @IdEst = @IdEst,
        @IdOperacionDia = @IdOperacionDia;

    EXEC flota.p_OperacionDiaIntervalo_ResumenHoras
        @IdEmpresa = @IdEmpresa,
        @IdEst = @IdEst,
        @IdContrato = @IdContrato,
        @IdChofer = @IdChofer,
        @IdVehiculo = @IdVehiculo,
        @FechaOperativa = @FechaOperativa;

    SET @Mensaje = 'Intervalo cerrado correctamente.';
END;
GO

IF OBJECT_ID('flota.p_OperacionDiaIntervalo_ListarPorDia','P') IS NOT NULL
    DROP PROCEDURE flota.p_OperacionDiaIntervalo_ListarPorDia;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE flota.p_OperacionDiaIntervalo_ListarPorDia
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @IdChofer INT,
    @IdVehiculo INT,
    @FechaOperativa DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.IdIntervalo,
        i.IdOperacionDia,
        i.IdContrato,
        i.IdChofer,
        i.IdVehiculo,
        i.FechaOperativa,
        i.FechaHoraInicio,
        i.FechaHoraFin,
        i.KmInicio,
        i.KmFin,
        CASE
            WHEN i.FechaHoraFin IS NULL THEN NULL
            ELSE CAST(DATEDIFF(MINUTE, i.FechaHoraInicio, i.FechaHoraFin) AS DECIMAL(10,2)) / 60.0
        END AS HorasCalculadas,
        ISNULL(i.Observacion,'') AS Observacion,
        i.FlgEstado,
        i.Fec_Creacion,
        i.Fec_Modif
    FROM flota.operacion_dia_intervalo i
    WHERE i.id_empresa = @IdEmpresa
      AND i.id_est = @IdEst
      AND i.IdContrato = @IdContrato
      AND i.IdChofer = @IdChofer
      AND i.IdVehiculo = @IdVehiculo
      AND i.FechaOperativa = @FechaOperativa
      AND i.FlgEstado = 'A'
    ORDER BY i.FechaHoraInicio ASC, i.IdIntervalo ASC;
END;
GO

IF OBJECT_ID('flota.p_OperacionDiaIntervalo_ResumenHoras','P') IS NOT NULL
    DROP PROCEDURE flota.p_OperacionDiaIntervalo_ResumenHoras;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE flota.p_OperacionDiaIntervalo_ResumenHoras
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @IdChofer INT,
    @IdVehiculo INT,
    @FechaOperativa DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ISNULL(MAX(i.IdOperacionDia),0) AS IdOperacionDia,
        @IdContrato AS IdContrato,
        @IdChofer AS IdChofer,
        @IdVehiculo AS IdVehiculo,
        @FechaOperativa AS FechaOperativa,
        ISNULL(SUM(CASE WHEN i.FechaHoraFin IS NULL THEN 0 ELSE CAST(DATEDIFF(MINUTE, i.FechaHoraInicio, i.FechaHoraFin) AS DECIMAL(10,2)) / 60.0 END),0) AS TotalHorasDia,
        CASE WHEN SUM(CASE WHEN i.FechaHoraFin IS NULL THEN 1 ELSE 0 END) > 0 THEN 'S' ELSE 'N' END AS TieneIntervaloAbierto,
        CASE WHEN ISNULL(SUM(CASE WHEN i.FechaHoraFin IS NULL THEN 0 ELSE CAST(DATEDIFF(MINUTE, i.FechaHoraInicio, i.FechaHoraFin) AS DECIMAL(10,2)) / 60.0 END),0) > 12 THEN 'S' ELSE 'N' END AS AlertaExcesoHoras,
        CASE WHEN ISNULL(SUM(CASE WHEN i.FechaHoraFin IS NULL THEN 0 ELSE CAST(DATEDIFF(MINUTE, i.FechaHoraInicio, i.FechaHoraFin) AS DECIMAL(10,2)) / 60.0 END),0) > 12
            THEN 'Supera 12 horas acumuladas. Posible dia adicional cobrable.'
            ELSE ''
        END AS Mensaje,
        COUNT(1) AS CantidadIntervalos
    FROM flota.operacion_dia_intervalo i
    WHERE i.id_empresa = @IdEmpresa
      AND i.id_est = @IdEst
      AND i.IdContrato = @IdContrato
      AND i.IdChofer = @IdChofer
      AND i.IdVehiculo = @IdVehiculo
      AND i.FechaOperativa = @FechaOperativa
      AND i.FlgEstado = 'A';
END;
GO

IF OBJECT_ID('flota.p_OperacionDiaIntervalo_Anular','P') IS NOT NULL
    DROP PROCEDURE flota.p_OperacionDiaIntervalo_Anular;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE flota.p_OperacionDiaIntervalo_Anular
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdIntervalo INT,
    @IdContrato INT,
    @Motivo VARCHAR(250),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdOperacionDia INT;

    SET @Mensaje = '';

    IF @IdIntervalo <= 0
    BEGIN
        SET @Mensaje = 'Selecciona un intervalo valido.';
        RETURN;
    END;

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Motivo,''))),'') IS NULL
    BEGIN
        SET @Mensaje = 'Ingresa el motivo de anulacion.';
        RETURN;
    END;

    SELECT @IdOperacionDia = i.IdOperacionDia
    FROM flota.operacion_dia_intervalo i
    WHERE i.id_empresa = @IdEmpresa
      AND i.id_est = @IdEst
      AND i.IdIntervalo = @IdIntervalo
      AND i.IdContrato = @IdContrato
      AND i.FlgEstado = 'A';

    IF @IdOperacionDia IS NULL
    BEGIN
        SET @Mensaje = 'Intervalo no encontrado o ya inactivo.';
        RETURN;
    END;

    UPDATE flota.operacion_dia_intervalo
    SET FlgEstado = 'X',
        Usu_Anula = @Usuario,
        Fec_Anula = GETUTCDATE(),
        MotivoAnula = @Motivo,
        Usu_Modif = @Usuario,
        Fec_Modif = GETUTCDATE()
    WHERE IdIntervalo = @IdIntervalo
      AND id_empresa = @IdEmpresa
      AND id_est = @IdEst;

    EXEC flota.p_OperacionDiaIntervalo_RecalcularCabecera
        @IdEmpresa = @IdEmpresa,
        @IdEst = @IdEst,
        @IdOperacionDia = @IdOperacionDia;

    SET @Mensaje = 'Intervalo anulado correctamente.';
END;
GO

PRINT 'OK: flota.operacion_dia_intervalo y SPs de intervalos creados.';
GO
