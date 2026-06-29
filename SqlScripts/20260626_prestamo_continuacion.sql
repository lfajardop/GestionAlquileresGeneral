/* =====================================================
   CONTINUACION / AMPLIACION DE PRESTAMO VENCIDO
   - Genera cuotas nuevas posteriores a la ultima cuota.
   - Por seguridad, las cuotas nuevas son solo interes:
     Imp_Base = 0, Imp_Interes = interes de continuidad.
   - No refinancia ni capitaliza saldo. Eso queda para el modulo formal.
===================================================== */

IF OBJECT_ID('prest.prestamo_continuacion', 'U') IS NULL
BEGIN
    CREATE TABLE prest.prestamo_continuacion
    (
        Id_Continuacion INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Id_Prestamo INT NOT NULL,
        FechaDesde DATE NOT NULL,
        FechaHasta DATE NOT NULL,
        FrecuenciaPago CHAR(1) NOT NULL,
        PorcInteresMensual DECIMAL(18,4) NOT NULL,
        CapitalBase DECIMAL(18,2) NOT NULL,
        NroCuotasGeneradas INT NOT NULL,
        ImporteInteresTotal DECIMAL(18,2) NOT NULL,
        NumSecuenciaDesde INT NULL,
        NumSecuenciaHasta INT NULL,
        Observacion VARCHAR(250) NULL,
        Flg_Estado VARCHAR(1) NOT NULL CONSTRAINT DF_prestamo_continuacion_estado DEFAULT ('A'),
        Usu_Creacion INT NULL,
        Fec_Creacion DATETIME NOT NULL CONSTRAINT DF_prestamo_continuacion_fec DEFAULT (GETDATE()),
        CONSTRAINT FK_prestamo_continuacion_prestamo
            FOREIGN KEY (Id_Prestamo) REFERENCES prest.prestamo(Id_Prestamo)
    );
END
GO

IF COL_LENGTH('prest.prestamo_continuacion', 'NumSecuenciaDesde') IS NULL
    ALTER TABLE prest.prestamo_continuacion ADD NumSecuenciaDesde INT NULL;
IF COL_LENGTH('prest.prestamo_continuacion', 'NumSecuenciaHasta') IS NULL
    ALTER TABLE prest.prestamo_continuacion ADD NumSecuenciaHasta INT NULL;
GO

IF OBJECT_ID('prest.p_prestamo_continuacion_simular', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_prestamo_continuacion_simular;
GO

CREATE PROCEDURE prest.p_prestamo_continuacion_simular
(
    @Id_Prestamo INT,
    @FechaHasta DATE,
    @PorcInteresMensual DECIMAL(18,4) = NULL,
    @FrecuenciaPago CHAR(1) = NULL,
    @CapitalBase DECIMAL(18,2) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @FechaDesde DATE,
        @UltimoVenc DATE,
        @Capital DECIMAL(18,2),
        @Tasa DECIMAL(18,4),
        @Frecuencia CHAR(1),
        @TipoInteres CHAR(1),
        @NroCobranza CHAR(8),
        @CodAlmacen CHAR(2),
        @Cliente VARCHAR(150),
        @Mensaje VARCHAR(500);

    SELECT
        @Capital = ISNULL(@CapitalBase, p.Capital),
        @Tasa = ISNULL(@PorcInteresMensual, p.PorcInteresMensual),
        @Frecuencia = ISNULL(@FrecuenciaPago, p.FrecuenciaPago),
        @TipoInteres = p.TipoInteres,
        @CodAlmacen = p.Cod_Almacen,
        @Cliente = ISNULL(a.Des_Anexo, '')
    FROM prest.prestamo p
    LEFT JOIN dbo.CN_AnexosContables a
        ON a.Cod_TipAnex = p.Cod_TipAnex
       AND a.Cod_Anxo = p.Cod_Anxo
    WHERE p.Id_Prestamo = @Id_Prestamo
      AND ISNULL(p.Flg_Estado, 'A') <> 'X';

    IF @Capital IS NULL
    BEGIN
        SELECT CAST(0 AS BIT) Ok, 'No existe el prestamo o esta anulado.' Mensaje;
        RETURN;
    END

    SELECT
        @UltimoVenc = MAX(c.Fec_Venc),
        @NroCobranza = MAX(c.NroCobranza)
    FROM prest.cuota c
    WHERE c.Id_Prestamo = @Id_Prestamo;

    SET @FechaDesde = DATEADD(DAY, 1, @UltimoVenc);

    IF @FechaHasta < @FechaDesde
    BEGIN
        SET @Mensaje = 'La fecha hasta debe ser mayor o igual al dia siguiente de la ultima cuota: '
            + CONVERT(VARCHAR(10), @FechaDesde, 103) + '.';
        SELECT CAST(0 AS BIT) Ok, @Mensaje Mensaje;
        RETURN;
    END

    IF ISNULL(@Frecuencia, '') NOT IN ('D', 'S', 'M')
    BEGIN
        SELECT CAST(0 AS BIT) Ok, 'Frecuencia invalida. Use D, S o M.' Mensaje;
        RETURN;
    END

    IF ISNULL(@Tasa, 0) <= 0
    BEGIN
        SELECT CAST(0 AS BIT) Ok, 'El porcentaje de interes mensual debe ser mayor a cero.' Mensaje;
        RETURN;
    END

    IF ISNULL(@Capital, 0) <= 0
    BEGIN
        SELECT CAST(0 AS BIT) Ok, 'El capital base debe ser mayor a cero.' Mensaje;
        RETURN;
    END

    IF OBJECT_ID('tempdb..#cronograma_cont') IS NOT NULL DROP TABLE #cronograma_cont;

    CREATE TABLE #cronograma_cont
    (
        Num_Secuencia INT IDENTITY(1,1) NOT NULL,
        Fecha_Desde DATE NOT NULL,
        Fecha_Hasta DATE NOT NULL,
        Fec_Venc DATE NOT NULL,
        Imp_Base DECIMAL(18,2) NOT NULL DEFAULT (0),
        Imp_Interes DECIMAL(18,2) NOT NULL DEFAULT (0),
        Imp_Cuota DECIMAL(18,2) NOT NULL DEFAULT (0)
    );

    DECLARE
        @FecDesde DATE = @FechaDesde,
        @FecSig DATE,
        @FecHasta DATE,
        @FechaFinCalculo DATE = DATEADD(DAY, 1, @FechaHasta);

    WHILE @FecDesde < @FechaFinCalculo
    BEGIN
        IF @Frecuencia = 'D'
            SET @FecSig = DATEADD(DAY, 1, @FecDesde);
        ELSE IF @Frecuencia = 'S'
            SET @FecSig = DATEADD(DAY, 7, @FecDesde);
        ELSE
            SET @FecSig = DATEADD(MONTH, 1, @FecDesde);

        IF @FecSig < @FechaFinCalculo
            SET @FecHasta = DATEADD(DAY, -1, @FecSig);
        ELSE
            SET @FecHasta = @FechaHasta;

        INSERT INTO #cronograma_cont (Fecha_Desde, Fecha_Hasta, Fec_Venc)
        VALUES (@FecDesde, @FecHasta, @FecHasta);

        SET @FecDesde = @FecSig;
    END

    DECLARE
        @N INT = 1,
        @MaxN INT,
        @RangoDesde DATE,
        @RangoHasta DATE,
        @CursorTramo DATE,
        @FechaInicioCicloReal DATE,
        @FechaFinCicloRealExclusiva DATE,
        @FechaCorteTramo DATE,
        @DiasCicloReal INT,
        @DiasTramo INT,
        @InteresMensual DECIMAL(18,10),
        @InteresDiarioReal DECIMAL(18,10),
        @InteresPeriodo DECIMAL(18,10);

    SELECT @MaxN = COUNT(1) FROM #cronograma_cont;
    SET @InteresMensual = @Capital * (@Tasa / 100.0);

    WHILE @N <= @MaxN
    BEGIN
        SELECT @RangoDesde = Fecha_Desde, @RangoHasta = Fecha_Hasta
        FROM #cronograma_cont
        WHERE Num_Secuencia = @N;

        SET @InteresPeriodo = 0;
        SET @CursorTramo = @RangoDesde;

        WHILE @CursorTramo <= @RangoHasta
        BEGIN
            SET @FechaInicioCicloReal = @FechaDesde;

            WHILE DATEADD(MONTH, 1, @FechaInicioCicloReal) <= @CursorTramo
                SET @FechaInicioCicloReal = DATEADD(MONTH, 1, @FechaInicioCicloReal);

            SET @FechaFinCicloRealExclusiva = DATEADD(MONTH, 1, @FechaInicioCicloReal);
            SET @DiasCicloReal = DATEDIFF(DAY, @FechaInicioCicloReal, @FechaFinCicloRealExclusiva);
            SET @InteresDiarioReal = CASE WHEN @DiasCicloReal > 0 THEN @InteresMensual / @DiasCicloReal ELSE 0 END;

            IF DATEADD(DAY, -1, @FechaFinCicloRealExclusiva) < @RangoHasta
                SET @FechaCorteTramo = DATEADD(DAY, -1, @FechaFinCicloRealExclusiva);
            ELSE
                SET @FechaCorteTramo = @RangoHasta;

            SET @DiasTramo = DATEDIFF(DAY, @CursorTramo, DATEADD(DAY, 1, @FechaCorteTramo));
            SET @InteresPeriodo = @InteresPeriodo + (@InteresDiarioReal * @DiasTramo);
            SET @CursorTramo = DATEADD(DAY, 1, @FechaCorteTramo);
        END

        UPDATE #cronograma_cont
        SET Imp_Base = 0,
            Imp_Interes = ROUND(@InteresPeriodo, 2),
            Imp_Cuota = ROUND(@InteresPeriodo, 2)
        WHERE Num_Secuencia = @N;

        SET @N = @N + 1;
    END

    SELECT
        CAST(1 AS BIT) Ok,
        'Simulacion de continuidad generada correctamente.' Mensaje,
        @Id_Prestamo Id_Prestamo,
        @Cliente Cliente,
        @NroCobranza NroCobranza,
        @CodAlmacen Cod_Almacen,
        @FechaDesde FechaDesde,
        @FechaHasta FechaHasta,
        @Capital CapitalBase,
        @Tasa PorcInteresMensual,
        @Frecuencia FrecuenciaPago,
        COUNT(1) NroCuotas,
        CAST(ISNULL(SUM(Imp_Interes), 0) AS DECIMAL(18,2)) InteresTotal,
        CAST(ISNULL(SUM(Imp_Cuota), 0) AS DECIMAL(18,2)) TotalGenerado
    FROM #cronograma_cont;

    SELECT
        Num_Secuencia,
        Fecha_Desde,
        Fecha_Hasta,
        Fec_Venc,
        Imp_Base,
        Imp_Interes,
        Imp_Cuota
    FROM #cronograma_cont
    ORDER BY Num_Secuencia;
END
GO

IF OBJECT_ID('prest.p_prestamo_continuacion_aplicar', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_prestamo_continuacion_aplicar;
GO

CREATE PROCEDURE prest.p_prestamo_continuacion_aplicar
(
    @Id_Prestamo INT,
    @FechaHasta DATE,
    @PorcInteresMensual DECIMAL(18,4) = NULL,
    @FrecuenciaPago CHAR(1) = NULL,
    @CapitalBase DECIMAL(18,2) = NULL,
    @Observacion VARCHAR(250) = NULL,
    @CodUsuarioCreacion INT = NULL,
    @Ok BIT OUTPUT,
    @Mensaje VARCHAR(500) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @FechaDesde DATE,
        @UltimoVenc DATE,
        @Capital DECIMAL(18,2),
        @Tasa DECIMAL(18,4),
        @Frecuencia CHAR(1),
        @NroCobranza CHAR(8),
        @CodAlmacen CHAR(2),
        @MaxSecuencia INT,
        @NroNuevas INT,
        @InteresTotal DECIMAL(18,2),
        @IdContinuacion INT;

    BEGIN TRY
        SELECT
            @Capital = ISNULL(@CapitalBase, p.Capital),
            @Tasa = ISNULL(@PorcInteresMensual, p.PorcInteresMensual),
            @Frecuencia = ISNULL(@FrecuenciaPago, p.FrecuenciaPago),
            @CodAlmacen = p.Cod_Almacen
        FROM prest.prestamo p
        WHERE p.Id_Prestamo = @Id_Prestamo
          AND ISNULL(p.Flg_Estado, 'A') <> 'X';

        IF @Capital IS NULL
            RAISERROR('No existe el prestamo o esta anulado.', 16, 1);

        SELECT
            @UltimoVenc = MAX(c.Fec_Venc),
            @MaxSecuencia = MAX(c.Num_Secuencia),
            @NroCobranza = MAX(c.NroCobranza)
        FROM prest.cuota c
        WHERE c.Id_Prestamo = @Id_Prestamo;

        SET @FechaDesde = DATEADD(DAY, 1, @UltimoVenc);

        IF @FechaHasta < @FechaDesde
            RAISERROR('La fecha hasta debe ser mayor o igual al dia siguiente de la ultima cuota.', 16, 1);

        IF ISNULL(@Frecuencia, '') NOT IN ('D', 'S', 'M')
            RAISERROR('Frecuencia invalida. Use D, S o M.', 16, 1);

        IF ISNULL(@Tasa, 0) <= 0
            RAISERROR('El porcentaje de interes mensual debe ser mayor a cero.', 16, 1);

        IF ISNULL(@Capital, 0) <= 0
            RAISERROR('El capital base debe ser mayor a cero.', 16, 1);

        IF ISNULL(@NroCobranza, '') = ''
            RAISERROR('El prestamo no tiene cobranza asociada.', 16, 1);

        IF OBJECT_ID('tempdb..#cronograma_apply') IS NOT NULL DROP TABLE #cronograma_apply;

        CREATE TABLE #cronograma_apply
        (
            Num_Secuencia INT IDENTITY(1,1) NOT NULL,
            Fecha_Desde DATE NOT NULL,
            Fecha_Hasta DATE NOT NULL,
            Fec_Venc DATE NOT NULL,
            Imp_Base DECIMAL(18,2) NOT NULL DEFAULT (0),
            Imp_Interes DECIMAL(18,2) NOT NULL DEFAULT (0),
            Imp_Cuota DECIMAL(18,2) NOT NULL DEFAULT (0)
        );

        DECLARE
            @FecDesde DATE = @FechaDesde,
            @FecSig DATE,
            @FecHasta DATE,
            @FechaFinCalculo DATE = DATEADD(DAY, 1, @FechaHasta);

        WHILE @FecDesde < @FechaFinCalculo
        BEGIN
            IF @Frecuencia = 'D'
                SET @FecSig = DATEADD(DAY, 1, @FecDesde);
            ELSE IF @Frecuencia = 'S'
                SET @FecSig = DATEADD(DAY, 7, @FecDesde);
            ELSE
                SET @FecSig = DATEADD(MONTH, 1, @FecDesde);

            IF @FecSig < @FechaFinCalculo
                SET @FecHasta = DATEADD(DAY, -1, @FecSig);
            ELSE
                SET @FecHasta = @FechaHasta;

            INSERT INTO #cronograma_apply (Fecha_Desde, Fecha_Hasta, Fec_Venc)
            VALUES (@FecDesde, @FecHasta, @FecHasta);

            SET @FecDesde = @FecSig;
        END

        DECLARE
            @N INT = 1,
            @MaxN INT,
            @RangoDesde DATE,
            @RangoHasta DATE,
            @CursorTramo DATE,
            @FechaInicioCicloReal DATE,
            @FechaFinCicloRealExclusiva DATE,
            @FechaCorteTramo DATE,
            @DiasCicloReal INT,
            @DiasTramo INT,
            @InteresMensual DECIMAL(18,10),
            @InteresDiarioReal DECIMAL(18,10),
            @InteresPeriodo DECIMAL(18,10);

        SELECT @MaxN = COUNT(1) FROM #cronograma_apply;
        SET @InteresMensual = @Capital * (@Tasa / 100.0);

        WHILE @N <= @MaxN
        BEGIN
            SELECT @RangoDesde = Fecha_Desde, @RangoHasta = Fecha_Hasta
            FROM #cronograma_apply
            WHERE Num_Secuencia = @N;

            SET @InteresPeriodo = 0;
            SET @CursorTramo = @RangoDesde;

            WHILE @CursorTramo <= @RangoHasta
            BEGIN
                SET @FechaInicioCicloReal = @FechaDesde;

                WHILE DATEADD(MONTH, 1, @FechaInicioCicloReal) <= @CursorTramo
                    SET @FechaInicioCicloReal = DATEADD(MONTH, 1, @FechaInicioCicloReal);

                SET @FechaFinCicloRealExclusiva = DATEADD(MONTH, 1, @FechaInicioCicloReal);
                SET @DiasCicloReal = DATEDIFF(DAY, @FechaInicioCicloReal, @FechaFinCicloRealExclusiva);
                SET @InteresDiarioReal = CASE WHEN @DiasCicloReal > 0 THEN @InteresMensual / @DiasCicloReal ELSE 0 END;

                IF DATEADD(DAY, -1, @FechaFinCicloRealExclusiva) < @RangoHasta
                    SET @FechaCorteTramo = DATEADD(DAY, -1, @FechaFinCicloRealExclusiva);
                ELSE
                    SET @FechaCorteTramo = @RangoHasta;

                SET @DiasTramo = DATEDIFF(DAY, @CursorTramo, DATEADD(DAY, 1, @FechaCorteTramo));
                SET @InteresPeriodo = @InteresPeriodo + (@InteresDiarioReal * @DiasTramo);
                SET @CursorTramo = DATEADD(DAY, 1, @FechaCorteTramo);
            END

            UPDATE #cronograma_apply
            SET Imp_Base = 0,
                Imp_Interes = ROUND(@InteresPeriodo, 2),
                Imp_Cuota = ROUND(@InteresPeriodo, 2)
            WHERE Num_Secuencia = @N;

            SET @N = @N + 1;
        END

        SELECT
            @NroNuevas = COUNT(1),
            @InteresTotal = CAST(ISNULL(SUM(Imp_Interes), 0) AS DECIMAL(18,2))
        FROM #cronograma_apply;

        IF ISNULL(@NroNuevas, 0) <= 0
            RAISERROR('No se generaron cuotas de continuidad.', 16, 1);

        IF ISNULL(@InteresTotal, 0) <= 0
            RAISERROR('La continuidad genera interes cero. Revise tasa, capital o fechas.', 16, 1);

        BEGIN TRAN;

        INSERT INTO prest.prestamo_continuacion
        (
            Id_Prestamo, FechaDesde, FechaHasta, FrecuenciaPago, PorcInteresMensual,
            CapitalBase, NroCuotasGeneradas, ImporteInteresTotal, NumSecuenciaDesde, NumSecuenciaHasta, Observacion,
            Flg_Estado, Usu_Creacion
        )
        VALUES
        (
            @Id_Prestamo, @FechaDesde, @FechaHasta, @Frecuencia, @Tasa,
            @Capital, @NroNuevas, @InteresTotal, @MaxSecuencia + 1, @MaxSecuencia + @NroNuevas, @Observacion,
            'A', @CodUsuarioCreacion
        );

        SET @IdContinuacion = SCOPE_IDENTITY();

        INSERT INTO prest.cuota
        (
            Id_Prestamo, Num_Secuencia, Fec_Venc, Imp_Base, Imp_Interes,
            Imp_Cuota, Estado, NroCobranza
        )
        SELECT
            @Id_Prestamo,
            @MaxSecuencia + Num_Secuencia,
            Fec_Venc,
            Imp_Base,
            Imp_Interes,
            Imp_Cuota,
            'P',
            @NroCobranza
        FROM #cronograma_apply
        ORDER BY Num_Secuencia;

        INSERT INTO dbo.FI_Cobranza_Cuota
        (
            NroCobranza, NumCuota, Cod_Almacen, Fec_vencDocum,
            ImporteBase, ImporteInteres, ImpComision, ImpCuota,
            ImpCancelado, FecCancelado, FlgStatusPago, Fec_Creacion
        )
        SELECT
            @NroCobranza,
            @MaxSecuencia + Num_Secuencia,
            @CodAlmacen,
            Fec_Venc,
            Imp_Base,
            Imp_Interes,
            0,
            Imp_Cuota,
            0,
            NULL,
            'P',
            GETDATE()
        FROM #cronograma_apply
        ORDER BY Num_Secuencia;

        UPDATE prest.prestamo
        SET
            Nro_Cuotas = @MaxSecuencia + @NroNuevas,
            FechaFinCobro = @FechaHasta,
            InteresTotal = ISNULL(InteresTotal, 0) + @InteresTotal,
            TotalCobrar = ISNULL(TotalCobrar, 0) + @InteresTotal,
            Flg_Ampliado = 'S',
            Fec_Modif = GETDATE(),
            Usu_Modif = @CodUsuarioCreacion
        WHERE Id_Prestamo = @Id_Prestamo;

        UPDATE dbo.FI_CobranzaPedido
        SET
            NroCuotas = @MaxSecuencia + @NroNuevas,
            ImporteTotal = ISNULL(ImporteTotal, 0) + @InteresTotal,
            ImporteSumaCuotas = ISNULL(ImporteSumaCuotas, 0) + @InteresTotal,
            ImporteInteres = ISNULL(ImporteInteres, 0) + @InteresTotal
        WHERE NroCobranza = @NroCobranza
          AND Cod_Almacen = @CodAlmacen
          AND OrigenTipo = 'PR'
          AND IdOrigen = CONVERT(VARCHAR(30), @Id_Prestamo);

        COMMIT;

        SET @Ok = 1;
        SET @Mensaje = 'Continuidad registrada correctamente. Id: '
            + CONVERT(VARCHAR(20), @IdContinuacion)
            + ' | Cuotas: ' + CONVERT(VARCHAR(20), @NroNuevas)
            + ' | Interes: S/ ' + CONVERT(VARCHAR(30), @InteresTotal);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        SET @Ok = 0;
        SET @Mensaje = ERROR_MESSAGE();
        RETURN;
    END CATCH
END
GO
