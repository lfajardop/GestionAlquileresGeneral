/*
    Etapa 1.1 - Flota - Correccion administrativa
    Compatibilidad: SQL Server 2014 SP3
    Reglas:
    - No usar FOR JSON, JSON_VALUE ni funciones JSON.
    - Fechas/hora de sistema en UTC con GETUTCDATE().
    - Fechas de negocio se mantienen como las envia la aplicacion.
    - Filtros multitenant obligatorios por id_empresa e id_est.
    - No tocar caja general ni cobranza general.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

/* =========================================================
   1. TABLAS Y COLUMNAS DE SOPORTE
   ========================================================= */

IF OBJECT_ID('flota.AuditoriaFlota', 'U') IS NULL
BEGIN
    CREATE TABLE flota.AuditoriaFlota
    (
        IdAuditoriaFlota INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        id_empresa INT NOT NULL,
        id_est CHAR(2) NOT NULL,
        Entidad VARCHAR(30) NOT NULL,
        IdEntidad INT NOT NULL,
        Accion VARCHAR(30) NOT NULL,
        Motivo VARCHAR(300) NOT NULL,
        DatosAntes VARCHAR(MAX) NULL,
        DatosDespues VARCHAR(MAX) NULL,
        Usuario INT NOT NULL,
        Fecha DATETIME NOT NULL,
        Origen VARCHAR(20) NOT NULL CONSTRAINT DF_flota_AuditoriaFlota_Origen DEFAULT ('ADMIN')
    );
END;
GO

IF COL_LENGTH('flota.ReciboAlquiler', 'Usu_Anula') IS NULL
BEGIN
    ALTER TABLE flota.ReciboAlquiler
    ADD Usu_Anula INT NULL;
END;
GO

IF COL_LENGTH('flota.ReciboAlquiler', 'Fec_Anula') IS NULL
BEGIN
    ALTER TABLE flota.ReciboAlquiler
    ADD Fec_Anula DATETIME NULL;
END;
GO

IF COL_LENGTH('flota.ReciboAlquiler', 'MotivoAnula') IS NULL
BEGIN
    ALTER TABLE flota.ReciboAlquiler
    ADD MotivoAnula VARCHAR(250) NULL;
END;
GO

IF COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'FlgEstado') IS NULL
BEGIN
    ALTER TABLE flota.ReciboAlquilerDetalleDia
    ADD FlgEstado VARCHAR(1) NOT NULL CONSTRAINT DF_flota_ReciboDetalleDia_FlgEstado DEFAULT ('A');
END;
GO

IF COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'Usu_Anula') IS NULL
BEGIN
    ALTER TABLE flota.ReciboAlquilerDetalleDia
    ADD Usu_Anula INT NULL;
END;
GO

IF COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'Fec_Anula') IS NULL
BEGIN
    ALTER TABLE flota.ReciboAlquilerDetalleDia
    ADD Fec_Anula DATETIME NULL;
END;
GO

IF COL_LENGTH('flota.ReciboAlquilerDetalleDia', 'MotivoAnula') IS NULL
BEGIN
    ALTER TABLE flota.ReciboAlquilerDetalleDia
    ADD MotivoAnula VARCHAR(250) NULL;
END;
GO

IF COL_LENGTH('flota.PagoReciboAlquiler', 'Usu_Modif') IS NULL
BEGIN
    ALTER TABLE flota.PagoReciboAlquiler
    ADD Usu_Modif INT NULL;
END;
GO

IF COL_LENGTH('flota.PagoReciboAlquiler', 'Fec_Modif') IS NULL
BEGIN
    ALTER TABLE flota.PagoReciboAlquiler
    ADD Fec_Modif DATETIME NULL;
END;
GO

IF COL_LENGTH('flota.PagoReciboAlquiler', 'Usu_Anula') IS NULL
BEGIN
    ALTER TABLE flota.PagoReciboAlquiler
    ADD Usu_Anula INT NULL;
END;
GO

IF COL_LENGTH('flota.PagoReciboAlquiler', 'Fec_Anula') IS NULL
BEGIN
    ALTER TABLE flota.PagoReciboAlquiler
    ADD Fec_Anula DATETIME NULL;
END;
GO

IF COL_LENGTH('flota.PagoReciboAlquiler', 'MotivoAnula') IS NULL
BEGIN
    ALTER TABLE flota.PagoReciboAlquiler
    ADD MotivoAnula VARCHAR(250) NULL;
END;
GO

IF COL_LENGTH('flota.PagoReciboAlquiler', 'MotivoValidacion') IS NULL
BEGIN
    ALTER TABLE flota.PagoReciboAlquiler
    ADD MotivoValidacion VARCHAR(300) NULL;
END;
GO

IF COL_LENGTH('flota.PagoReciboAlquiler', 'Usu_Valida') IS NULL
BEGIN
    ALTER TABLE flota.PagoReciboAlquiler
    ADD Usu_Valida INT NULL;
END;
GO

IF COL_LENGTH('flota.PagoReciboAlquiler', 'Fec_Valida') IS NULL
BEGIN
    ALTER TABLE flota.PagoReciboAlquiler
    ADD Fec_Valida DATETIME NULL;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('flota.ReciboAlquilerDetalleDia')
      AND name = 'IX_flota_ReciboDetalleDia_ReciboEstadoFecha'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_flota_ReciboDetalleDia_ReciboEstadoFecha
        ON flota.ReciboAlquilerDetalleDia (Id_ReciboAlquiler, FlgEstado, Fecha);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('flota.PagoReciboAlquiler')
      AND name = 'IX_flota_PagoReciboAlquiler_ReciboEstadoFecha'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_flota_PagoReciboAlquiler_ReciboEstadoFecha
        ON flota.PagoReciboAlquiler (Id_ReciboAlquiler, FlgEstado, FechaPago);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('flota.ReciboAlquilerDetalleDia')
      AND name = 'UX_flota_ReciboDetalle_Operacion_Activa'
)
BEGIN
    UPDATE d
       SET d.FlgEstado = 'X',
           d.Fec_Anula = ISNULL(d.Fec_Anula, GETUTCDATE()),
           d.MotivoAnula = ISNULL(d.MotivoAnula, 'Regularizacion por recibo anulado')
    FROM flota.ReciboAlquilerDetalleDia d
    INNER JOIN flota.ReciboAlquiler r
        ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
    WHERE r.Estado = 'X'
      AND ISNULL(d.FlgEstado, 'A') = 'A';

    IF EXISTS
    (
        SELECT d.Id_OperacionDia
        FROM flota.ReciboAlquilerDetalleDia d
        WHERE d.Id_OperacionDia IS NOT NULL
          AND ISNULL(d.FlgEstado, 'A') = 'A'
        GROUP BY d.Id_OperacionDia
        HAVING COUNT(1) > 1
    )
    BEGIN
        RAISERROR('No se puede crear UX_flota_ReciboDetalle_Operacion_Activa porque existen Id_OperacionDia duplicados en detalles activos.', 16, 1);
    END
    ELSE
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX UX_flota_ReciboDetalle_Operacion_Activa
            ON flota.ReciboAlquilerDetalleDia (Id_OperacionDia)
            WHERE Id_OperacionDia IS NOT NULL
              AND FlgEstado = 'A';
    END;
END;
GO

IF TYPE_ID('flota.FechaSeleccionadaType') IS NULL
BEGIN
    EXEC ('CREATE TYPE flota.FechaSeleccionadaType AS TABLE(Fecha DATE NOT NULL PRIMARY KEY)');
END;
GO

/* =========================================================
   2. HELPER DE AUDITORIA
   ========================================================= */

IF OBJECT_ID('flota.p_AuditoriaFlota_Registrar', 'P') IS NULL
EXEC ('CREATE PROCEDURE flota.p_AuditoriaFlota_Registrar AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_AuditoriaFlota_Registrar
    @id_empresa INT,
    @id_est CHAR(2),
    @Entidad VARCHAR(30),
    @IdEntidad INT,
    @Accion VARCHAR(30),
    @Motivo VARCHAR(300),
    @DatosAntes VARCHAR(MAX) = NULL,
    @DatosDespues VARCHAR(MAX) = NULL,
    @Usuario INT,
    @Origen VARCHAR(20) = 'ADMIN'
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO flota.AuditoriaFlota
    (
        id_empresa,
        id_est,
        Entidad,
        IdEntidad,
        Accion,
        Motivo,
        DatosAntes,
        DatosDespues,
        Usuario,
        Fecha,
        Origen
    )
    VALUES
    (
        @id_empresa,
        @id_est,
        @Entidad,
        @IdEntidad,
        @Accion,
        @Motivo,
        @DatosAntes,
        @DatosDespues,
        @Usuario,
        GETUTCDATE(),
        @Origen
    );
END;
GO

/* =========================================================
   3. RECALCULO DE RECIBO
   ========================================================= */

IF OBJECT_ID('flota.p_ReciboAlquiler_Recalcular', 'P') IS NULL
EXEC ('CREATE PROCEDURE flota.p_ReciboAlquiler_Recalcular AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_ReciboAlquiler_Recalcular
    @id_empresa INT,
    @id_est CHAR(2),
    @IdReciboAlquiler INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Existe INT;
    DECLARE @EstadoActual VARCHAR(1);
    DECLARE @CantidadDias INT;
    DECLARE @FechaInicio DATE;
    DECLARE @FechaFin DATE;
    DECLARE @ImporteTotal DECIMAL(18,2);
    DECLARE @ImportePagado DECIMAL(18,2);
    DECLARE @Saldo DECIMAL(18,2);
    DECLARE @EstadoNuevo VARCHAR(1);

    SELECT
        @Existe = COUNT(1),
        @EstadoActual = MAX(r.Estado)
    FROM flota.ReciboAlquiler r
    WHERE r.Id_ReciboAlquiler = @IdReciboAlquiler
      AND r.id_empresa = @id_empresa
      AND r.id_est = @id_est;

    IF ISNULL(@Existe, 0) = 0
    BEGIN
        RAISERROR('Recibo no encontrado para la empresa y estacion indicadas.', 16, 1);
        RETURN;
    END;

    IF @EstadoActual = 'X'
    BEGIN
        RETURN;
    END;

    SELECT
        @CantidadDias = COUNT(1),
        @FechaInicio = MIN(d.Fecha),
        @FechaFin = MAX(d.Fecha),
        @ImporteTotal = ISNULL(SUM(d.ImporteDia), 0)
    FROM flota.ReciboAlquilerDetalleDia d
    INNER JOIN flota.ReciboAlquiler r
        ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
    WHERE d.Id_ReciboAlquiler = @IdReciboAlquiler
      AND r.id_empresa = @id_empresa
      AND r.id_est = @id_est
      AND ISNULL(d.FlgEstado, 'A') = 'A';

    SELECT
        @ImportePagado = ISNULL(SUM(p.Importe), 0)
    FROM flota.PagoReciboAlquiler p
    INNER JOIN flota.ReciboAlquiler r
        ON r.Id_ReciboAlquiler = p.Id_ReciboAlquiler
    WHERE p.Id_ReciboAlquiler = @IdReciboAlquiler
      AND r.id_empresa = @id_empresa
      AND r.id_est = @id_est
      AND ISNULL(p.FlgEstado, 'A') = 'A';

    IF ISNULL(@CantidadDias, 0) = 0
    BEGIN
        RAISERROR('El recibo no puede quedar sin dias activos.', 16, 1);
        RETURN;
    END;

    IF ISNULL(@ImporteTotal, 0) < ISNULL(@ImportePagado, 0)
    BEGIN
        RAISERROR('El total del recibo no puede quedar menor que el importe pagado.', 16, 1);
        RETURN;
    END;

    SET @Saldo = ISNULL(@ImporteTotal, 0) - ISNULL(@ImportePagado, 0);

    IF @Saldo < 0
    BEGIN
        RAISERROR('No se permite saldo negativo en el recibo.', 16, 1);
        RETURN;
    END;

    SET @EstadoNuevo =
        CASE
            WHEN ISNULL(@ImportePagado, 0) = 0 THEN 'P'
            WHEN @Saldo = 0 THEN 'C'
            ELSE 'A'
        END;

    UPDATE r
       SET r.CantidadDias = @CantidadDias,
           r.FechaInicio = @FechaInicio,
           r.FechaFin = @FechaFin,
           r.ImporteTotal = @ImporteTotal,
           r.ImportePagado = @ImportePagado,
           r.Saldo = @Saldo,
           r.Estado = @EstadoNuevo
    FROM flota.ReciboAlquiler r
    WHERE r.Id_ReciboAlquiler = @IdReciboAlquiler
      AND r.id_empresa = @id_empresa
      AND r.id_est = @id_est;
END;
GO

/* =========================================================
   4. GENERACION DE RECIBOS
   ========================================================= */

IF OBJECT_ID('flota.p_ReciboAlquiler_Generar', 'P') IS NULL
EXEC ('CREATE PROCEDURE flota.p_ReciboAlquiler_Generar AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_ReciboAlquiler_Generar
    @id_empresa INT,
    @id_est CHAR(2),
    @IdContrato INT,
    @FechaInicio DATE,
    @FechaFin DATE,
    @Observacion VARCHAR(300) = NULL,
    @Usuario INT,
    @IdRecibo INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @IdRecibo = 0;
    SET @Mensaje = '';

    DECLARE @InicioTran BIT;
    SET @InicioTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @InicioTran = 1;
        END;
        ELSE
        BEGIN
            SAVE TRANSACTION SP_ReciboGenerar;
        END;

        DECLARE @Tarifa DECIMAL(18,2);
        DECLARE @Origen VARCHAR(1);

        SET @Origen = 'O';

        SELECT @Tarifa = c.TarifaDia
        FROM flota.contrato c WITH (UPDLOCK, HOLDLOCK)
        WHERE c.Id_Contrato = @IdContrato
          AND c.id_empresa = @id_empresa
          AND c.id_est = @id_est
          AND c.Flg_Estado = 'A';

        IF @Tarifa IS NULL
        BEGIN
            SET @Mensaje = 'Contrato activo no encontrado.';
            GOTO FIN_OK_p_ReciboAlquiler_Generar;
        END;

        IF @FechaFin < @FechaInicio
        BEGIN
            SET @Mensaje = 'El rango de fechas no es valido.';
            GOTO FIN_OK_p_ReciboAlquiler_Generar;
        END;

        DECLARE @Dias TABLE
        (
            IdOperacion INT NOT NULL PRIMARY KEY,
            Fecha DATE NOT NULL,
            Importe DECIMAL(18,2) NOT NULL,
            Origen VARCHAR(1) NOT NULL
        );

        INSERT INTO @Dias (IdOperacion, Fecha, Importe, Origen)
        SELECT
            o.Id_OperacionDia,
            o.Fecha,
            o.ImporteGenerado,
            o.FlgOrigen
        FROM flota.operacion_dia o
        WHERE o.Id_Contrato = @IdContrato
          AND o.id_empresa = @id_empresa
          AND o.id_est = @id_est
          AND o.Fecha BETWEEN @FechaInicio AND @FechaFin
          AND o.Flg_Cobrable = 'S'
          AND o.ImporteGenerado > 0
          AND NOT EXISTS
          (
              SELECT 1
              FROM flota.ReciboAlquilerDetalleDia d
              INNER JOIN flota.ReciboAlquiler r
                  ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
              WHERE d.Id_OperacionDia = o.Id_OperacionDia
                AND r.id_empresa = @id_empresa
                AND r.id_est = @id_est
                AND r.Estado <> 'X'
                AND ISNULL(d.FlgEstado, 'A') = 'A'
          );

        IF NOT EXISTS (SELECT 1 FROM @Dias)
        BEGIN
            SET @Mensaje = 'No hay dias cobrables disponibles en el periodo.';
            GOTO FIN_OK_p_ReciboAlquiler_Generar;
        END;

        INSERT INTO flota.ReciboAlquiler
        (
            Numero,
            id_empresa,
            id_est,
            Id_Contrato,
            FechaEmision,
            FechaInicio,
            FechaFin,
            CantidadDias,
            TarifaDia,
            ImporteTotal,
            ImportePagado,
            Saldo,
            Estado,
            FlgOrigen,
            Observacion,
            Usu_Creacion,
            Fec_Creacion
        )
        SELECT
            'RA-00000000',
            @id_empresa,
            @id_est,
            @IdContrato,
            CAST(GETUTCDATE() AS DATE),
            MIN(d.Fecha),
            MAX(d.Fecha),
            COUNT(1),
            @Tarifa,
            SUM(d.Importe),
            0,
            SUM(d.Importe),
            'P',
            @Origen,
            @Observacion,
            @Usuario,
            GETUTCDATE()
        FROM @Dias d;

        SET @IdRecibo = SCOPE_IDENTITY();

        UPDATE flota.ReciboAlquiler
           SET Numero = 'RA-' + RIGHT('00000000' + CONVERT(VARCHAR(8), @IdRecibo), 8)
        WHERE Id_ReciboAlquiler = @IdRecibo
          AND id_empresa = @id_empresa
          AND id_est = @id_est;

        INSERT INTO flota.ReciboAlquilerDetalleDia
        (
            Id_ReciboAlquiler,
            Id_OperacionDia,
            Fecha,
            TarifaDia,
            ImporteDia,
            FlgOrigen,
            Observacion,
            FlgEstado
        )
        SELECT
            @IdRecibo,
            d.IdOperacion,
            d.Fecha,
            @Tarifa,
            d.Importe,
            d.Origen,
            @Observacion,
            'A'
        FROM @Dias d;

        EXEC flota.p_ReciboAlquiler_Recalcular
            @id_empresa = @id_empresa,
            @id_est = @id_est,
            @IdReciboAlquiler = @IdRecibo;

FIN_OK_p_ReciboAlquiler_Generar:
        IF @InicioTran = 1 AND XACT_STATE() = 1
            COMMIT TRANSACTION;

        IF @Mensaje = ''
            SET @Mensaje = 'Recibo generado correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SP_ReciboGenerar;
        END;

        SET @Mensaje = ERROR_MESSAGE();
        SET @IdRecibo = 0;
    END CATCH;
END;
GO

IF OBJECT_ID('flota.p_ReciboAlquiler_GenerarManual', 'P') IS NULL
EXEC ('CREATE PROCEDURE flota.p_ReciboAlquiler_GenerarManual AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_ReciboAlquiler_GenerarManual
    @id_empresa INT,
    @id_est CHAR(2),
    @IdContrato INT,
    @Fechas flota.FechaSeleccionadaType READONLY,
    @TarifaDia DECIMAL(18,2),
    @ModoAgrupacion VARCHAR(1),
    @Observacion VARCHAR(300) = NULL,
    @Usuario INT,
    @CantidadRecibos INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @CantidadRecibos = 0;
    SET @Mensaje = '';

    DECLARE @InicioTran BIT;
    SET @InicioTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @InicioTran = 1;
        END;
        ELSE
        BEGIN
            SAVE TRANSACTION SP_ReciboGenerarManual;
        END;

        IF @TarifaDia <= 0
        BEGIN
            SET @Mensaje = 'La tarifa debe ser mayor a cero.';
            GOTO FIN_OK_p_ReciboAlquiler_GenerarManual;
        END;

        IF @ModoAgrupacion NOT IN ('U', 'R')
        BEGIN
            SET @Mensaje = 'Modo de agrupacion invalido. Valores permitidos: U o R.';
            GOTO FIN_OK_p_ReciboAlquiler_GenerarManual;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM flota.contrato c
            WHERE c.Id_Contrato = @IdContrato
              AND c.id_empresa = @id_empresa
              AND c.id_est = @id_est
              AND c.Flg_Estado = 'A'
        )
        BEGIN
            SET @Mensaje = 'Contrato activo no encontrado.';
            GOTO FIN_OK_p_ReciboAlquiler_GenerarManual;
        END;

        IF NOT EXISTS (SELECT 1 FROM @Fechas)
        BEGIN
            SET @Mensaje = 'Selecciona al menos un dia.';
            GOTO FIN_OK_p_ReciboAlquiler_GenerarManual;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM @Fechas f
            INNER JOIN flota.ReciboAlquilerDetalleDia d
                ON d.Fecha = f.Fecha
            INNER JOIN flota.ReciboAlquiler r
                ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
            WHERE r.Id_Contrato = @IdContrato
              AND r.id_empresa = @id_empresa
              AND r.id_est = @id_est
              AND r.Estado <> 'X'
              AND ISNULL(d.FlgEstado, 'A') = 'A'
        )
        BEGIN
            SET @Mensaje = 'Uno o mas dias ya pertenecen a un recibo activo del mismo contrato.';
            GOTO FIN_OK_p_ReciboAlquiler_GenerarManual;
        END;

        DECLARE @Ops TABLE
        (
            Fecha DATE NOT NULL PRIMARY KEY,
            IdOperacion INT NOT NULL
        );

        UPDATE o
           SET o.Flg_Trabajo = 'S',
               o.Cod_Motivo = 'TRA',
               o.Flg_Cobrable = 'S',
               o.ImporteGenerado = @TarifaDia,
               o.FlgOrigen = 'M',
               o.Observacion = CASE WHEN @Observacion IS NULL THEN o.Observacion ELSE @Observacion END,
               o.Usu_Modif = @Usuario,
               o.Fec_Modif = GETUTCDATE()
        FROM flota.operacion_dia o
        INNER JOIN @Fechas f
            ON f.Fecha = o.Fecha
        WHERE o.Id_Contrato = @IdContrato
          AND o.id_empresa = @id_empresa
          AND o.id_est = @id_est;

        INSERT INTO flota.operacion_dia
        (
            id_empresa,
            id_est,
            Id_Contrato,
            Fecha,
            Flg_Trabajo,
            Cod_Motivo,
            Flg_Cobrable,
            ImporteGenerado,
            Observacion,
            Usu_Creacion,
            Fec_Creacion,
            FlgOrigen
        )
        SELECT
            @id_empresa,
            @id_est,
            @IdContrato,
            f.Fecha,
            'S',
            'TRA',
            'S',
            @TarifaDia,
            @Observacion,
            @Usuario,
            GETUTCDATE(),
            'M'
        FROM @Fechas f
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM flota.operacion_dia o
            WHERE o.Id_Contrato = @IdContrato
              AND o.id_empresa = @id_empresa
              AND o.id_est = @id_est
              AND o.Fecha = f.Fecha
        );

        INSERT INTO @Ops (Fecha, IdOperacion)
        SELECT
            o.Fecha,
            o.Id_OperacionDia
        FROM flota.operacion_dia o
        INNER JOIN @Fechas f
            ON f.Fecha = o.Fecha
        WHERE o.Id_Contrato = @IdContrato
          AND o.id_empresa = @id_empresa
          AND o.id_est = @id_est;

        DECLARE @Grupos TABLE
        (
            Grupo INT NOT NULL PRIMARY KEY,
            FechaInicio DATE NOT NULL,
            FechaFin DATE NOT NULL,
            Cantidad INT NOT NULL
        );

        IF @ModoAgrupacion = 'U'
        BEGIN
            INSERT INTO @Grupos (Grupo, FechaInicio, FechaFin, Cantidad)
            SELECT 1, MIN(f.Fecha), MAX(f.Fecha), COUNT(1)
            FROM @Fechas f;
        END;
        ELSE
        BEGIN
            DECLARE @f DATE;
            DECLARE @prev DATE;
            DECLARE @g INT;

            SET @prev = NULL;
            SET @g = 0;

            DECLARE c CURSOR LOCAL FAST_FORWARD FOR
                SELECT f.Fecha
                FROM @Fechas f
                ORDER BY f.Fecha;

            OPEN c;
            FETCH NEXT FROM c INTO @f;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                IF @prev IS NULL OR DATEDIFF(DAY, @prev, @f) > 1
                    SET @g = @g + 1;

                IF EXISTS (SELECT 1 FROM @Grupos WHERE Grupo = @g)
                BEGIN
                    UPDATE @Grupos
                       SET FechaFin = @f,
                           Cantidad = Cantidad + 1
                    WHERE Grupo = @g;
                END;
                ELSE
                BEGIN
                    INSERT INTO @Grupos (Grupo, FechaInicio, FechaFin, Cantidad)
                    VALUES (@g, @f, @f, 1);
                END;

                SET @prev = @f;
                FETCH NEXT FROM c INTO @f;
            END;

            CLOSE c;
            DEALLOCATE c;
        END;

        DECLARE @Grupo INT;
        DECLARE @Ini DATE;
        DECLARE @Fin DATE;
        DECLARE @Cant INT;
        DECLARE @IdReciboGrupo INT;

        DECLARE g CURSOR LOCAL FAST_FORWARD FOR
            SELECT Grupo, FechaInicio, FechaFin, Cantidad
            FROM @Grupos
            ORDER BY Grupo;

        OPEN g;
        FETCH NEXT FROM g INTO @Grupo, @Ini, @Fin, @Cant;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO flota.ReciboAlquiler
            (
                Numero,
                id_empresa,
                id_est,
                Id_Contrato,
                FechaEmision,
                FechaInicio,
                FechaFin,
                CantidadDias,
                TarifaDia,
                ImporteTotal,
                ImportePagado,
                Saldo,
                Estado,
                FlgOrigen,
                Observacion,
                Usu_Creacion,
                Fec_Creacion
            )
            VALUES
            (
                'RA-00000000',
                @id_empresa,
                @id_est,
                @IdContrato,
                CAST(GETUTCDATE() AS DATE),
                @Ini,
                @Fin,
                @Cant,
                @TarifaDia,
                @Cant * @TarifaDia,
                0,
                @Cant * @TarifaDia,
                'P',
                'M',
                @Observacion,
                @Usuario,
                GETUTCDATE()
            );

            SET @IdReciboGrupo = SCOPE_IDENTITY();

            UPDATE flota.ReciboAlquiler
               SET Numero = 'RA-' + RIGHT('00000000' + CONVERT(VARCHAR(8), @IdReciboGrupo), 8)
            WHERE Id_ReciboAlquiler = @IdReciboGrupo
              AND id_empresa = @id_empresa
              AND id_est = @id_est;

            INSERT INTO flota.ReciboAlquilerDetalleDia
            (
                Id_ReciboAlquiler,
                Id_OperacionDia,
                Fecha,
                TarifaDia,
                ImporteDia,
                FlgOrigen,
                Observacion,
                FlgEstado
            )
            SELECT
                @IdReciboGrupo,
                o.IdOperacion,
                o.Fecha,
                @TarifaDia,
                @TarifaDia,
                'M',
                @Observacion,
                'A'
            FROM @Ops o
            WHERE @ModoAgrupacion = 'U'
               OR o.Fecha BETWEEN @Ini AND @Fin;

            EXEC flota.p_ReciboAlquiler_Recalcular
                @id_empresa = @id_empresa,
                @id_est = @id_est,
                @IdReciboAlquiler = @IdReciboGrupo;

            SET @CantidadRecibos = @CantidadRecibos + 1;

            FETCH NEXT FROM g INTO @Grupo, @Ini, @Fin, @Cant;
        END;

        CLOSE g;
        DEALLOCATE g;

FIN_OK_p_ReciboAlquiler_GenerarManual:
        IF @InicioTran = 1 AND XACT_STATE() = 1
            COMMIT TRANSACTION;

        IF @Mensaje = ''
            SET @Mensaje = CONVERT(VARCHAR(10), @CantidadRecibos) + ' recibo(s) generado(s).';

        IF @CantidadRecibos > 0
        BEGIN
            SELECT
                r.Id_ReciboAlquiler,
                r.Numero,
                r.FechaInicio,
                r.FechaFin,
                r.ImporteTotal
            FROM flota.ReciboAlquiler r
            WHERE r.Id_Contrato = @IdContrato
              AND r.id_empresa = @id_empresa
              AND r.id_est = @id_est
              AND r.Usu_Creacion = @Usuario
              AND r.Fec_Creacion >= DATEADD(MINUTE, -1, GETUTCDATE())
            ORDER BY r.Id_ReciboAlquiler DESC;
        END;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SP_ReciboGenerarManual;
        END;

        SET @Mensaje = ERROR_MESSAGE();
        SET @CantidadRecibos = 0;
    END CATCH;
END;
GO

/* =========================================================
   5. ANULAR RECIBO
   ========================================================= */

IF OBJECT_ID('flota.p_ReciboAlquiler_Anular', 'P') IS NULL
EXEC ('CREATE PROCEDURE flota.p_ReciboAlquiler_Anular AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_ReciboAlquiler_Anular
    @id_empresa INT,
    @id_est CHAR(2),
    @IdReciboAlquiler INT,
    @Motivo VARCHAR(250),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Mensaje = '';

    DECLARE @InicioTran BIT;
    SET @InicioTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @InicioTran = 1;
        END;
        ELSE
        BEGIN
            SAVE TRANSACTION SP_ReciboAnular;
        END;

        DECLARE @PagosActivos INT;
        DECLARE @DatosAntes VARCHAR(MAX);

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Motivo, ''))), '') IS NULL
        BEGIN
            SET @Mensaje = 'El motivo de anulacion es obligatorio.';
            GOTO FIN_OK_p_ReciboAlquiler_Anular;
        END;

        SELECT @PagosActivos = COUNT(1)
        FROM flota.PagoReciboAlquiler p
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = p.Id_ReciboAlquiler
        WHERE p.Id_ReciboAlquiler = @IdReciboAlquiler
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND ISNULL(p.FlgEstado, 'A') = 'A';

        IF ISNULL(@PagosActivos, 0) > 0
        BEGIN
            SET @Mensaje = 'No se puede anular el recibo porque tiene pagos activos. Primero anule los pagos uno por uno.';
            GOTO FIN_OK_p_ReciboAlquiler_Anular;
        END;

        SELECT @DatosAntes =
            'Numero=' + ISNULL(r.Numero, '') +
            ';Estado=' + ISNULL(r.Estado, '') +
            ';CantidadDias=' + CONVERT(VARCHAR(20), ISNULL(r.CantidadDias, 0)) +
            ';FechaInicio=' + ISNULL(CONVERT(VARCHAR(10), r.FechaInicio, 120), '') +
            ';FechaFin=' + ISNULL(CONVERT(VARCHAR(10), r.FechaFin, 120), '') +
            ';ImporteTotal=' + CONVERT(VARCHAR(30), ISNULL(r.ImporteTotal, 0)) +
            ';ImportePagado=' + CONVERT(VARCHAR(30), ISNULL(r.ImportePagado, 0)) +
            ';Saldo=' + CONVERT(VARCHAR(30), ISNULL(r.Saldo, 0))
        FROM flota.ReciboAlquiler r
        WHERE r.Id_ReciboAlquiler = @IdReciboAlquiler
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND r.Estado IN ('P', 'A', 'C');

        IF @DatosAntes IS NULL
        BEGIN
            SET @Mensaje = 'Recibo no encontrado o no disponible para anulacion.';
            GOTO FIN_OK_p_ReciboAlquiler_Anular;
        END;

        UPDATE d
           SET d.FlgEstado = 'X',
               d.Usu_Anula = @Usuario,
               d.Fec_Anula = GETUTCDATE(),
               d.MotivoAnula = @Motivo
        FROM flota.ReciboAlquilerDetalleDia d
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
        WHERE d.Id_ReciboAlquiler = @IdReciboAlquiler
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND ISNULL(d.FlgEstado, 'A') = 'A';

        UPDATE r
           SET r.Estado = 'X',
               r.Saldo = 0,
               r.Usu_Anula = @Usuario,
               r.Fec_Anula = GETUTCDATE(),
               r.MotivoAnula = @Motivo
        FROM flota.ReciboAlquiler r
        WHERE r.Id_ReciboAlquiler = @IdReciboAlquiler
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est;

        EXEC flota.p_AuditoriaFlota_Registrar
            @id_empresa = @id_empresa,
            @id_est = @id_est,
            @Entidad = 'RECIBO',
            @IdEntidad = @IdReciboAlquiler,
            @Accion = 'ANULAR',
            @Motivo = @Motivo,
            @DatosAntes = @DatosAntes,
            @DatosDespues = 'Estado=X;Saldo=0;Recibo excluido de saldos y reportes.',
            @Usuario = @Usuario,
            @Origen = 'ADMIN';

FIN_OK_p_ReciboAlquiler_Anular:
        IF @InicioTran = 1 AND XACT_STATE() = 1
            COMMIT TRANSACTION;

        IF @Mensaje = ''
            SET @Mensaje = 'Recibo anulado correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SP_ReciboAnular;
        END;

        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

/* =========================================================
   6. QUITAR DIA DE RECIBO
   ========================================================= */

IF OBJECT_ID('flota.p_ReciboAlquiler_QuitarDia', 'P') IS NULL
EXEC ('CREATE PROCEDURE flota.p_ReciboAlquiler_QuitarDia AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_ReciboAlquiler_QuitarDia
    @id_empresa INT,
    @id_est CHAR(2),
    @IdReciboDetalle INT,
    @Motivo VARCHAR(250),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Mensaje = '';

    DECLARE @InicioTran BIT;
    SET @InicioTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @InicioTran = 1;
        END;
        ELSE
        BEGIN
            SAVE TRANSACTION SP_ReciboQuitarDia;
        END;

        DECLARE @IdReciboAlquiler INT;
        DECLARE @ImporteDia DECIMAL(18,2);
        DECLARE @ImportePagado DECIMAL(18,2);
        DECLARE @ImporteTotalActual DECIMAL(18,2);
        DECLARE @NuevoTotal DECIMAL(18,2);
        DECLARE @DatosAntes VARCHAR(MAX);
        DECLARE @DatosDespues VARCHAR(MAX);

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Motivo, ''))), '') IS NULL
        BEGIN
            SET @Mensaje = 'El motivo es obligatorio para quitar el dia del recibo.';
            GOTO FIN_OK_p_ReciboAlquiler_QuitarDia;
        END;

        SELECT
            @IdReciboAlquiler = d.Id_ReciboAlquiler,
            @ImporteDia = d.ImporteDia,
            @DatosAntes =
                'IdReciboAlquiler=' + CONVERT(VARCHAR(20), d.Id_ReciboAlquiler) +
                ';IdOperacionDia=' + CONVERT(VARCHAR(20), ISNULL(d.Id_OperacionDia, 0)) +
                ';Fecha=' + ISNULL(CONVERT(VARCHAR(10), d.Fecha, 120), '') +
                ';ImporteDia=' + CONVERT(VARCHAR(30), ISNULL(d.ImporteDia, 0)) +
                ';FlgEstado=' + ISNULL(d.FlgEstado, 'A')
        FROM flota.ReciboAlquilerDetalleDia d
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
        WHERE d.Id_ReciboDetalle = @IdReciboDetalle
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND r.Estado <> 'X'
          AND ISNULL(d.FlgEstado, 'A') = 'A';

        IF @IdReciboAlquiler IS NULL
        BEGIN
            SET @Mensaje = 'Detalle de recibo no encontrado o ya inactivo.';
            GOTO FIN_OK_p_ReciboAlquiler_QuitarDia;
        END;

        SELECT
            @ImportePagado = r.ImportePagado,
            @ImporteTotalActual = r.ImporteTotal
        FROM flota.ReciboAlquiler r
        WHERE r.Id_ReciboAlquiler = @IdReciboAlquiler
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est;

        SET @NuevoTotal = ISNULL(@ImporteTotalActual, 0) - ISNULL(@ImporteDia, 0);

        IF @NuevoTotal < ISNULL(@ImportePagado, 0)
        BEGIN
            SET @Mensaje = 'No se puede quitar el dia porque el nuevo total quedaria menor que el importe ya pagado.';
            GOTO FIN_OK_p_ReciboAlquiler_QuitarDia;
        END;

        UPDATE d
           SET d.FlgEstado = 'X',
               d.Usu_Anula = @Usuario,
               d.Fec_Anula = GETUTCDATE(),
               d.MotivoAnula = @Motivo
        FROM flota.ReciboAlquilerDetalleDia d
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
        WHERE d.Id_ReciboDetalle = @IdReciboDetalle
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND ISNULL(d.FlgEstado, 'A') = 'A';

        EXEC flota.p_ReciboAlquiler_Recalcular
            @id_empresa = @id_empresa,
            @id_est = @id_est,
            @IdReciboAlquiler = @IdReciboAlquiler;

        SET @DatosDespues = 'FlgEstado=X;IdReciboAlquiler=' + CONVERT(VARCHAR(20), @IdReciboAlquiler);

        EXEC flota.p_AuditoriaFlota_Registrar
            @id_empresa = @id_empresa,
            @id_est = @id_est,
            @Entidad = 'RECIBO_DIA',
            @IdEntidad = @IdReciboDetalle,
            @Accion = 'ANULAR',
            @Motivo = @Motivo,
            @DatosAntes = @DatosAntes,
            @DatosDespues = @DatosDespues,
            @Usuario = @Usuario,
            @Origen = 'ADMIN';

FIN_OK_p_ReciboAlquiler_QuitarDia:
        IF @InicioTran = 1 AND XACT_STATE() = 1
            COMMIT TRANSACTION;

        IF @Mensaje = ''
            SET @Mensaje = 'Dia retirado del recibo correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SP_ReciboQuitarDia;
        END;

        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

/* =========================================================
   7. PAGOS - EDITAR, ANULAR, VALIDAR
   ========================================================= */

IF OBJECT_ID('flota.p_PagoReciboAlquiler_Editar', 'P') IS NULL
EXEC ('CREATE PROCEDURE flota.p_PagoReciboAlquiler_Editar AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_PagoReciboAlquiler_Editar
    @id_empresa INT,
    @id_est CHAR(2),
    @IdPagoRecibo INT,
    @FechaPago DATETIME,
    @Importe DECIMAL(18,2),
    @MedioPago VARCHAR(2),
    @FotoVoucher VARCHAR(300) = NULL,
    @Observacion VARCHAR(300) = NULL,
    @Motivo VARCHAR(300),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Mensaje = '';

    DECLARE @InicioTran BIT;
    SET @InicioTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @InicioTran = 1;
        END;
        ELSE
        BEGIN
            SAVE TRANSACTION SP_PagoEditar;
        END;

        DECLARE @IdReciboAlquiler INT;
        DECLARE @DatosAntes VARCHAR(MAX);
        DECLARE @DatosDespues VARCHAR(MAX);

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Motivo, ''))), '') IS NULL
        BEGIN
            SET @Mensaje = 'El motivo es obligatorio para editar el pago.';
            GOTO FIN_OK_p_PagoReciboAlquiler_Editar;
        END;

        IF ISNULL(@Importe, 0) <= 0
        BEGIN
            SET @Mensaje = 'El importe del pago debe ser mayor a cero.';
            GOTO FIN_OK_p_PagoReciboAlquiler_Editar;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM flota.medio_pago_alquiler m
            WHERE m.Cod_MedioPago = @MedioPago
              AND m.Flg_Activo = 'S'
        )
        BEGIN
            SET @Mensaje = 'Medio de pago no valido.';
            GOTO FIN_OK_p_PagoReciboAlquiler_Editar;
        END;

        SELECT
            @IdReciboAlquiler = p.Id_ReciboAlquiler,
            @DatosAntes =
                'IdReciboAlquiler=' + CONVERT(VARCHAR(20), p.Id_ReciboAlquiler) +
                ';FechaPago=' + ISNULL(CONVERT(VARCHAR(19), p.FechaPago, 120), '') +
                ';Importe=' + CONVERT(VARCHAR(30), ISNULL(p.Importe, 0)) +
                ';MedioPago=' + ISNULL(p.MedioPago, '') +
                ';FotoVoucher=' + ISNULL(p.FotoVoucher, '') +
                ';Observacion=' + ISNULL(p.Observacion, '') +
                ';FlgValidado=' + ISNULL(p.FlgValidado, 'N') +
                ';FlgEstado=' + ISNULL(p.FlgEstado, 'A')
        FROM flota.PagoReciboAlquiler p
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = p.Id_ReciboAlquiler
        WHERE p.Id_PagoRecibo = @IdPagoRecibo
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND r.Estado <> 'X'
          AND ISNULL(p.FlgEstado, 'A') = 'A';

        IF @IdReciboAlquiler IS NULL
        BEGIN
            SET @Mensaje = 'Pago no encontrado o no editable.';
            GOTO FIN_OK_p_PagoReciboAlquiler_Editar;
        END;

        UPDATE p
           SET p.FechaPago = @FechaPago,
               p.Importe = @Importe,
               p.MedioPago = @MedioPago,
               p.Observacion = @Observacion,
               p.FotoVoucher = CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(@FotoVoucher, ''))), '') IS NULL THEN p.FotoVoucher ELSE @FotoVoucher END,
               p.Usu_Modif = @Usuario,
               p.Fec_Modif = GETUTCDATE()
        FROM flota.PagoReciboAlquiler p
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = p.Id_ReciboAlquiler
        WHERE p.Id_PagoRecibo = @IdPagoRecibo
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND ISNULL(p.FlgEstado, 'A') = 'A';

        EXEC flota.p_ReciboAlquiler_Recalcular
            @id_empresa = @id_empresa,
            @id_est = @id_est,
            @IdReciboAlquiler = @IdReciboAlquiler;

        SET @DatosDespues =
            'FechaPago=' + CONVERT(VARCHAR(19), @FechaPago, 120) +
            ';Importe=' + CONVERT(VARCHAR(30), @Importe) +
            ';MedioPago=' + ISNULL(@MedioPago, '') +
            ';FotoVoucher=' + ISNULL(@FotoVoucher, '') +
            ';Observacion=' + ISNULL(@Observacion, '');

        EXEC flota.p_AuditoriaFlota_Registrar
            @id_empresa = @id_empresa,
            @id_est = @id_est,
            @Entidad = 'PAGO',
            @IdEntidad = @IdPagoRecibo,
            @Accion = 'EDITAR',
            @Motivo = @Motivo,
            @DatosAntes = @DatosAntes,
            @DatosDespues = @DatosDespues,
            @Usuario = @Usuario,
            @Origen = 'ADMIN';

FIN_OK_p_PagoReciboAlquiler_Editar:
        IF @InicioTran = 1 AND XACT_STATE() = 1
            COMMIT TRANSACTION;

        IF @Mensaje = ''
            SET @Mensaje = 'Pago editado correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SP_PagoEditar;
        END;

        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

IF OBJECT_ID('flota.p_PagoReciboAlquiler_Anular', 'P') IS NULL
EXEC ('CREATE PROCEDURE flota.p_PagoReciboAlquiler_Anular AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_PagoReciboAlquiler_Anular
    @id_empresa INT,
    @id_est CHAR(2),
    @IdPagoRecibo INT,
    @Motivo VARCHAR(250),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Mensaje = '';

    DECLARE @InicioTran BIT;
    SET @InicioTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @InicioTran = 1;
        END;
        ELSE
        BEGIN
            SAVE TRANSACTION SP_PagoAnular;
        END;

        DECLARE @IdReciboAlquilerPago INT;
        DECLARE @DatosAntesPago VARCHAR(MAX);
        DECLARE @DatosDespuesPago VARCHAR(MAX);

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Motivo, ''))), '') IS NULL
        BEGIN
            SET @Mensaje = 'El motivo es obligatorio para anular el pago.';
            GOTO FIN_OK_p_PagoReciboAlquiler_Anular;
        END;

        SELECT
            @IdReciboAlquilerPago = p.Id_ReciboAlquiler,
            @DatosAntesPago =
                'IdReciboAlquiler=' + CONVERT(VARCHAR(20), p.Id_ReciboAlquiler) +
                ';FechaPago=' + ISNULL(CONVERT(VARCHAR(19), p.FechaPago, 120), '') +
                ';Importe=' + CONVERT(VARCHAR(30), ISNULL(p.Importe, 0)) +
                ';MedioPago=' + ISNULL(p.MedioPago, '') +
                ';FlgValidado=' + ISNULL(p.FlgValidado, 'N') +
                ';FlgEstado=' + ISNULL(p.FlgEstado, 'A')
        FROM flota.PagoReciboAlquiler p
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = p.Id_ReciboAlquiler
        WHERE p.Id_PagoRecibo = @IdPagoRecibo
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND r.Estado <> 'X'
          AND ISNULL(p.FlgEstado, 'A') = 'A';

        IF @IdReciboAlquilerPago IS NULL
        BEGIN
            SET @Mensaje = 'Pago no encontrado o ya anulado.';
            GOTO FIN_OK_p_PagoReciboAlquiler_Anular;
        END;

        UPDATE p
           SET p.FlgEstado = 'X',
               p.Usu_Anula = @Usuario,
               p.Fec_Anula = GETUTCDATE(),
               p.MotivoAnula = @Motivo
        FROM flota.PagoReciboAlquiler p
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = p.Id_ReciboAlquiler
        WHERE p.Id_PagoRecibo = @IdPagoRecibo
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND ISNULL(p.FlgEstado, 'A') = 'A';

        EXEC flota.p_ReciboAlquiler_Recalcular
            @id_empresa = @id_empresa,
            @id_est = @id_est,
            @IdReciboAlquiler = @IdReciboAlquilerPago;

        SET @DatosDespuesPago = 'FlgEstado=X;IdReciboAlquiler=' + CONVERT(VARCHAR(20), @IdReciboAlquilerPago);

        EXEC flota.p_AuditoriaFlota_Registrar
            @id_empresa = @id_empresa,
            @id_est = @id_est,
            @Entidad = 'PAGO',
            @IdEntidad = @IdPagoRecibo,
            @Accion = 'ANULAR',
            @Motivo = @Motivo,
            @DatosAntes = @DatosAntesPago,
            @DatosDespues = @DatosDespuesPago,
            @Usuario = @Usuario,
            @Origen = 'ADMIN';

FIN_OK_p_PagoReciboAlquiler_Anular:
        IF @InicioTran = 1 AND XACT_STATE() = 1
            COMMIT TRANSACTION;

        IF @Mensaje = ''
            SET @Mensaje = 'Pago anulado correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SP_PagoAnular;
        END;

        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

IF OBJECT_ID('flota.p_PagoReciboAlquiler_Validar', 'P') IS NULL
EXEC ('CREATE PROCEDURE flota.p_PagoReciboAlquiler_Validar AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_PagoReciboAlquiler_Validar
    @id_empresa INT,
    @id_est CHAR(2),
    @IdPagoRecibo INT,
    @FlgValidado VARCHAR(1),
    @Motivo VARCHAR(300),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Mensaje = '';

    DECLARE @InicioTran BIT;
    SET @InicioTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @InicioTran = 1;
        END;
        ELSE
        BEGIN
            SAVE TRANSACTION SP_PagoValidar;
        END;

        DECLARE @FlgValidadoAnterior VARCHAR(1);
        DECLARE @DatosAntesValidacion VARCHAR(MAX);
        DECLARE @DatosDespuesValidacion VARCHAR(MAX);

        IF @FlgValidado NOT IN ('S', 'N')
        BEGIN
            SET @Mensaje = 'FlgValidado invalido. Valores permitidos: S o N.';
            GOTO FIN_OK_p_PagoReciboAlquiler_Validar;
        END;

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Motivo, ''))), '') IS NULL
        BEGIN
            SET @Mensaje = 'El motivo es obligatorio para validar o desvalidar el pago.';
            GOTO FIN_OK_p_PagoReciboAlquiler_Validar;
        END;

        SELECT
            @FlgValidadoAnterior = ISNULL(p.FlgValidado, 'N'),
            @DatosAntesValidacion =
                'FlgValidado=' + ISNULL(p.FlgValidado, 'N') +
                ';FechaPago=' + ISNULL(CONVERT(VARCHAR(19), p.FechaPago, 120), '') +
                ';Importe=' + CONVERT(VARCHAR(30), ISNULL(p.Importe, 0)) +
                ';FlgEstado=' + ISNULL(p.FlgEstado, 'A')
        FROM flota.PagoReciboAlquiler p
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = p.Id_ReciboAlquiler
        WHERE p.Id_PagoRecibo = @IdPagoRecibo
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND r.Estado <> 'X'
          AND ISNULL(p.FlgEstado, 'A') = 'A';

        IF @DatosAntesValidacion IS NULL
        BEGIN
            SET @Mensaje = 'Pago no encontrado o inactivo para la empresa y estacion indicadas.';
            GOTO FIN_OK_p_PagoReciboAlquiler_Validar;
        END;

        UPDATE p
           SET p.FlgValidado = @FlgValidado,
               p.MotivoValidacion = @Motivo,
               p.Usu_Valida = @Usuario,
               p.Fec_Valida = GETUTCDATE(),
               p.Usu_Modif = @Usuario,
               p.Fec_Modif = GETUTCDATE()
        FROM flota.PagoReciboAlquiler p
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = p.Id_ReciboAlquiler
        WHERE p.Id_PagoRecibo = @IdPagoRecibo
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND ISNULL(p.FlgEstado, 'A') = 'A';

        SET @DatosDespuesValidacion = 'FlgValidadoAnterior=' + ISNULL(@FlgValidadoAnterior, 'N') + ';FlgValidadoNuevo=' + @FlgValidado;

        EXEC flota.p_AuditoriaFlota_Registrar
            @id_empresa = @id_empresa,
            @id_est = @id_est,
            @Entidad = 'PAGO',
            @IdEntidad = @IdPagoRecibo,
            @Accion = 'VALIDAR',
            @Motivo = @Motivo,
            @DatosAntes = @DatosAntesValidacion,
            @DatosDespues = @DatosDespuesValidacion,
            @Usuario = @Usuario,
            @Origen = 'ADMIN';

FIN_OK_p_PagoReciboAlquiler_Validar:
        IF @InicioTran = 1 AND XACT_STATE() = 1
            COMMIT TRANSACTION;

        IF @Mensaje = ''
            SET @Mensaje = 'Validacion de pago actualizada correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @InicioTran = 1
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SP_PagoValidar;
        END;

        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

/* =========================================================
   8. CORREGIR OPERACION DIA
   ========================================================= */

IF OBJECT_ID('flota.p_OperacionDia_Corregir', 'P') IS NULL
EXEC ('CREATE PROCEDURE flota.p_OperacionDia_Corregir AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_OperacionDia_Corregir
    @id_empresa INT,
    @id_est CHAR(2),
    @IdOperacionDia INT,
    @FlgTrabajo VARCHAR(1),
    @CodMotivo VARCHAR(3),
    @FlgCobrable VARCHAR(1),
    @Observacion VARCHAR(300) = NULL,
    @Motivo VARCHAR(300),
    @Usuario INT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Mensaje = '';

    DECLARE @InicioTran BIT;
    SET @InicioTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @InicioTran = 1;
        END;
        ELSE
        BEGIN
            SAVE TRANSACTION SP_OperacionDiaCorregir;
        END;

        DECLARE @IdContrato INT;
        DECLARE @TarifaDia DECIMAL(18,2);
        DECLARE @ImporteGeneradoNuevo DECIMAL(18,2);
        DECLARE @DatosAntesOperacion VARCHAR(MAX);
        DECLARE @DatosDespuesOperacion VARCHAR(MAX);
        DECLARE @IdReciboLoop INT;

        IF @FlgTrabajo NOT IN ('S', 'N')
        BEGIN
            SET @Mensaje = 'FlgTrabajo invalido. Valores permitidos: S o N.';
            GOTO FIN_OK_p_OperacionDia_Corregir;
        END;

        IF @FlgCobrable NOT IN ('S', 'N')
        BEGIN
            SET @Mensaje = 'FlgCobrable invalido. Valores permitidos: S o N.';
            GOTO FIN_OK_p_OperacionDia_Corregir;
        END;

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Motivo, ''))), '') IS NULL
        BEGIN
            SET @Mensaje = 'El motivo es obligatorio para corregir el dia.';
            GOTO FIN_OK_p_OperacionDia_Corregir;
        END;

        SELECT
            @IdContrato = o.Id_Contrato,
            @DatosAntesOperacion =
                'FlgTrabajo=' + ISNULL(o.Flg_Trabajo, '') +
                ';CodMotivo=' + ISNULL(o.Cod_Motivo, '') +
                ';FlgCobrable=' + ISNULL(o.Flg_Cobrable, '') +
                ';ImporteGenerado=' + CONVERT(VARCHAR(30), ISNULL(o.ImporteGenerado, 0)) +
                ';Observacion=' + ISNULL(o.Observacion, '')
        FROM flota.operacion_dia o
        WHERE o.Id_OperacionDia = @IdOperacionDia
          AND o.id_empresa = @id_empresa
          AND o.id_est = @id_est;

        IF @IdContrato IS NULL
        BEGIN
            SET @Mensaje = 'Operacion de dia no encontrada para la empresa y estacion indicadas.';
            GOTO FIN_OK_p_OperacionDia_Corregir;
        END;

        SELECT @TarifaDia = c.TarifaDia
        FROM flota.contrato c
        WHERE c.Id_Contrato = @IdContrato
          AND c.id_empresa = @id_empresa
          AND c.id_est = @id_est;

        SET @ImporteGeneradoNuevo =
            CASE
                WHEN @FlgTrabajo = 'S' AND @FlgCobrable = 'S' THEN ISNULL(@TarifaDia, 0)
                ELSE 0
            END;

        UPDATE o
           SET o.Flg_Trabajo = @FlgTrabajo,
               o.Cod_Motivo = @CodMotivo,
               o.Flg_Cobrable = @FlgCobrable,
               o.Observacion = @Observacion,
               o.ImporteGenerado = @ImporteGeneradoNuevo,
               o.Usu_Modif = @Usuario,
               o.Fec_Modif = GETUTCDATE()
        FROM flota.operacion_dia o
        WHERE o.Id_OperacionDia = @IdOperacionDia
          AND o.id_empresa = @id_empresa
          AND o.id_est = @id_est;

        UPDATE d
           SET d.ImporteDia =
               CASE
                   WHEN @FlgTrabajo = 'S' AND @FlgCobrable = 'S' THEN d.TarifaDia
                   ELSE 0
               END,
               d.Observacion = CASE WHEN @Observacion IS NULL THEN d.Observacion ELSE @Observacion END
        FROM flota.ReciboAlquilerDetalleDia d
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
        WHERE d.Id_OperacionDia = @IdOperacionDia
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND r.Estado <> 'X'
          AND ISNULL(d.FlgEstado, 'A') = 'A';

        DECLARE @RecibosAfectados TABLE
        (
            IdReciboAlquiler INT NOT NULL PRIMARY KEY
        );

        INSERT INTO @RecibosAfectados (IdReciboAlquiler)
        SELECT DISTINCT d.Id_ReciboAlquiler
        FROM flota.ReciboAlquilerDetalleDia d
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_ReciboAlquiler = d.Id_ReciboAlquiler
        WHERE d.Id_OperacionDia = @IdOperacionDia
          AND r.id_empresa = @id_empresa
          AND r.id_est = @id_est
          AND r.Estado <> 'X'
          AND ISNULL(d.FlgEstado, 'A') = 'A';

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT ra.IdReciboAlquiler
            FROM @RecibosAfectados ra;

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
            ';CodMotivo=' + ISNULL(@CodMotivo, '') +
            ';FlgCobrable=' + @FlgCobrable +
            ';ImporteGenerado=' + CONVERT(VARCHAR(30), @ImporteGeneradoNuevo) +
            ';Observacion=' + ISNULL(@Observacion, '');

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

FIN_OK_p_OperacionDia_Corregir:
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
