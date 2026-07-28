/* =============================================================
   PRESTAMOS / COMPENSACIONES - FIX SPS PRODUCCION
   Base objetivo: DB_9FA64E_bdgas
   SQL Server 2014 compatible
   Solo corrige / completa procedimientos almacenados comp
   No recrea tablas
   No borra catalogos
   No inserta datos de prueba
============================================================= */
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Base incorrecta. Este script solo debe ejecutarse en DB_9FA64E_bdgas.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'comp')
BEGIN
    RAISERROR('Falta el schema comp. Ejecutar primero el script base de compensaciones.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('comp.concepto_obligacion', 'U') IS NULL
    OR OBJECT_ID('comp.obligacion', 'U') IS NULL
    OR OBJECT_ID('comp.compensacion', 'U') IS NULL
    OR OBJECT_ID('comp.compensacion_detalle', 'U') IS NULL
    OR OBJECT_ID('comp.compensacion_historial', 'U') IS NULL
BEGIN
    RAISERROR('Faltan tablas comp base. No se pueden reparar los SPs.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('prest.prestamo', 'U') IS NULL
BEGIN
    RAISERROR('Falta prest.prestamo. No se pueden reparar los SPs.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('prest.cuota', 'U') IS NULL
BEGIN
    RAISERROR('Falta prest.cuota. No se pueden reparar los SPs.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('dbo.FI_Cobranza_Cuota', 'U') IS NULL
BEGIN
    RAISERROR('Falta dbo.FI_Cobranza_Cuota. No se pueden reparar los SPs.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('prest.prestamo', 'Id_Prestamo') IS NULL
    OR COL_LENGTH('prest.prestamo', 'Cod_TipAnex') IS NULL
    OR COL_LENGTH('prest.prestamo', 'Cod_Anxo') IS NULL
    OR COL_LENGTH('prest.prestamo', 'Cod_Almacen') IS NULL
    OR COL_LENGTH('prest.prestamo', 'Flg_Estado') IS NULL
BEGIN
    RAISERROR('prest.prestamo no tiene las columnas minimas esperadas.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('prest.cuota', 'Id_Prestamo') IS NULL
    OR COL_LENGTH('prest.cuota', 'NroCobranza') IS NULL
    OR COL_LENGTH('prest.cuota', 'Num_Secuencia') IS NULL
BEGIN
    RAISERROR('prest.cuota no tiene las columnas minimas esperadas.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF COL_LENGTH('dbo.FI_Cobranza_Cuota', 'NroCobranza') IS NULL
    OR COL_LENGTH('dbo.FI_Cobranza_Cuota', 'NumCuota') IS NULL
    OR COL_LENGTH('dbo.FI_Cobranza_Cuota', 'Cod_Almacen') IS NULL
    OR COL_LENGTH('dbo.FI_Cobranza_Cuota', 'ImpCuota') IS NULL
    OR COL_LENGTH('dbo.FI_Cobranza_Cuota', 'ImpCancelado') IS NULL
BEGIN
    RAISERROR('dbo.FI_Cobranza_Cuota no tiene las columnas minimas esperadas.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('comp.p_simular', 'P') IS NULL
    EXEC('CREATE PROCEDURE comp.p_simular AS BEGIN SET NOCOUNT ON; END');
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE comp.p_simular
    @id_empresa INT,
    @id_est CHAR(2),
    @Cod_TipAnex CHAR(1),
    @Cod_Anxo CHAR(6),
    @Id_Obligacion INT,
    @IdsPrestamo VARCHAR(MAX),
    @FechaCorte DATE,
    @Importe DECIMAL(18,2),
    @SoloVencidas BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SaldoObligacion DECIMAL(18,2);

    SELECT @SaldoObligacion = Importe - ImporteAplicado
    FROM comp.obligacion
    WHERE Id_Obligacion = @Id_Obligacion
      AND id_empresa = @id_empresa
      AND id_est = @id_est
      AND Cod_TipAnex = @Cod_TipAnex
      AND Cod_Anxo = @Cod_Anxo
      AND Flg_Estado = 'A';

    IF @SaldoObligacion IS NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Ok, 'Saldo a favor no disponible.' AS Mensaje;
        RETURN;
    END;

    IF @Importe <= 0 OR @Importe > @SaldoObligacion
    BEGIN
        SELECT CAST(0 AS BIT) AS Ok, 'El importe excede el saldo a favor.' AS Mensaje;
        RETURN;
    END;

    DECLARE @Ids TABLE (Id INT PRIMARY KEY);
    DECLARE @xml XML;

    BEGIN TRY
        SET @xml = CAST('<i>' + REPLACE(REPLACE(@IdsPrestamo, ' ', ''), ',', '</i><i>') + '</i>' AS XML);
        INSERT INTO @Ids (Id)
        SELECT DISTINCT T.N.value('.', 'INT')
        FROM @xml.nodes('/i') T(N);
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Ok, 'Prestamos seleccionados invalidos.' AS Mensaje;
        RETURN;
    END CATCH;

    DECLARE @P TABLE
    (
        Orden INT,
        Id_Prestamo INT,
        NroCobranza CHAR(8),
        NumCuota INT,
        Cod_Almacen CHAR(2),
        FecVenc DATE,
        SaldoAntes DECIMAL(18,2),
        InteresPendiente DECIMAL(18,2)
    );

    INSERT INTO @P
    SELECT
        ROW_NUMBER() OVER (ORDER BY fc.Fec_vencDocum, p.Id_Prestamo, fc.NumCuota),
        p.Id_Prestamo,
        fc.NroCobranza,
        fc.NumCuota,
        fc.Cod_Almacen,
        fc.Fec_vencDocum,
        fc.ImpCuota - fc.ImpCancelado,
        CASE
            WHEN fc.ImporteInteres > fc.ImpCancelado THEN fc.ImporteInteres - fc.ImpCancelado
            ELSE 0
        END
    FROM @Ids i
    JOIN prest.prestamo p
        ON p.Id_Prestamo = i.Id
       AND p.Cod_TipAnex = @Cod_TipAnex
       AND p.Cod_Anxo = @Cod_Anxo
    JOIN prest.cuota c
        ON c.Id_Prestamo = p.Id_Prestamo
    JOIN dbo.FI_Cobranza_Cuota fc
        ON fc.NroCobranza = c.NroCobranza
       AND fc.NumCuota = c.Num_Secuencia
       AND fc.Cod_Almacen = p.Cod_Almacen
    WHERE ISNULL(p.Flg_Estado, 'A') NOT IN ('X', 'R')
      AND fc.ImpCuota > fc.ImpCancelado
      AND (@SoloVencidas = 0 OR fc.Fec_vencDocum <= @FechaCorte);

    DECLARE @R TABLE
    (
        Orden INT,
        Id_Prestamo INT,
        NroCobranza CHAR(8),
        NumCuota INT,
        Cod_Almacen CHAR(2),
        FecVenc DATE,
        SaldoAntes DECIMAL(18,2),
        InteresAplicado DECIMAL(18,2),
        CapitalAplicado DECIMAL(18,2),
        ImporteAplicado DECIMAL(18,2),
        SaldoDespues DECIMAL(18,2)
    );

    DECLARE
        @Restante DECIMAL(18,2) = @Importe,
        @o INT,
        @pr INT,
        @nc CHAR(8),
        @cu INT,
        @al CHAR(2),
        @fv DATE,
        @sa DECIMAL(18,2),
        @ip DECIMAL(18,2),
        @ap DECIMAL(18,2),
        @ia DECIMAL(18,2);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Orden, Id_Prestamo, NroCobranza, NumCuota, Cod_Almacen, FecVenc, SaldoAntes, InteresPendiente
        FROM @P
        ORDER BY Orden;

    OPEN cur;
    FETCH NEXT FROM cur INTO @o, @pr, @nc, @cu, @al, @fv, @sa, @ip;

    WHILE @@FETCH_STATUS = 0 AND @Restante > 0
    BEGIN
        SET @ap = CASE WHEN @Restante > @sa THEN @sa ELSE @Restante END;
        SET @ia = CASE WHEN @ap > @ip THEN @ip ELSE @ap END;

        INSERT INTO @R
        VALUES (@o, @pr, @nc, @cu, @al, @fv, @sa, @ia, @ap - @ia, @ap, @sa - @ap);

        SET @Restante -= @ap;
        FETCH NEXT FROM cur INTO @o, @pr, @nc, @cu, @al, @fv, @sa, @ip;
    END;

    CLOSE cur;
    DEALLOCATE cur;

    IF NOT EXISTS (SELECT 1 FROM @R)
    BEGIN
        SELECT CAST(0 AS BIT) AS Ok, 'No hay cuotas elegibles para compensar.' AS Mensaje;
        RETURN;
    END;

    SELECT
        CAST(1 AS BIT) AS Ok,
        'Simulacion correcta.' AS Mensaje,
        @SaldoObligacion AS SaldoFavorAntes,
        @Importe AS ImporteSolicitado,
        @Importe - @Restante AS ImporteAplicado,
        @SaldoObligacion - (@Importe - @Restante) AS SaldoFavorDespues,
        SUM(InteresAplicado) AS InteresAplicado,
        SUM(CapitalAplicado) AS CapitalAplicado,
        COUNT(*) AS CuotasAfectadas
    FROM @R;

    SELECT *
    FROM @R
    ORDER BY Orden;
END;
GO

IF OBJECT_ID('comp.p_aplicar', 'P') IS NULL
    EXEC('CREATE PROCEDURE comp.p_aplicar AS BEGIN SET NOCOUNT ON; END');
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE comp.p_aplicar
    @id_empresa INT,
    @id_est CHAR(2),
    @Cod_TipAnex CHAR(1),
    @Cod_Anxo CHAR(6),
    @Id_Obligacion INT,
    @IdsPrestamo VARCHAR(MAX),
    @Fecha DATE,
    @Importe DECIMAL(18,2),
    @SoloVencidas BIT,
    @Motivo VARCHAR(3),
    @Observacion VARCHAR(300),
    @Usuario INT,
    @Ok BIT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT,
    @IdCompensacion INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Ok = 0;
    SET @IdCompensacion = NULL;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @SaldoFavor DECIMAL(18,2);

        SELECT @SaldoFavor = Importe - ImporteAplicado
        FROM comp.obligacion WITH (UPDLOCK, HOLDLOCK)
        WHERE Id_Obligacion = @Id_Obligacion
          AND id_empresa = @id_empresa
          AND id_est = @id_est
          AND Cod_TipAnex = @Cod_TipAnex
          AND Cod_Anxo = @Cod_Anxo
          AND Flg_Estado = 'A';

        IF @SaldoFavor IS NULL OR @Importe <= 0 OR @Importe > @SaldoFavor
            RAISERROR('Saldo a favor insuficiente o no disponible.', 16, 1);

        DECLARE @Ids TABLE (Id INT PRIMARY KEY);
        DECLARE @xml XML;

        SET @xml = CAST('<i>' + REPLACE(REPLACE(@IdsPrestamo, ' ', ''), ',', '</i><i>') + '</i>' AS XML);
        INSERT INTO @Ids (Id)
        SELECT DISTINCT T.N.value('.', 'INT')
        FROM @xml.nodes('/i') T(N);

        DECLARE @P TABLE
        (
            Orden INT,
            Id_Prestamo INT,
            NroCobranza CHAR(8),
            NumCuota INT,
            Cod_Almacen CHAR(2),
            FecVenc DATE,
            SaldoAntes DECIMAL(18,2),
            InteresPendiente DECIMAL(18,2)
        );

        INSERT INTO @P
        SELECT
            ROW_NUMBER() OVER (ORDER BY fc.Fec_vencDocum, p.Id_Prestamo, fc.NumCuota),
            p.Id_Prestamo,
            fc.NroCobranza,
            fc.NumCuota,
            fc.Cod_Almacen,
            fc.Fec_vencDocum,
            fc.ImpCuota - fc.ImpCancelado,
            CASE
                WHEN fc.ImporteInteres > fc.ImpCancelado THEN fc.ImporteInteres - fc.ImpCancelado
                ELSE 0
            END
        FROM @Ids i
        JOIN prest.prestamo p
            ON p.Id_Prestamo = i.Id
           AND p.Cod_TipAnex = @Cod_TipAnex
           AND p.Cod_Anxo = @Cod_Anxo
        JOIN prest.cuota c
            ON c.Id_Prestamo = p.Id_Prestamo
        JOIN dbo.FI_Cobranza_Cuota fc WITH (UPDLOCK, HOLDLOCK)
            ON fc.NroCobranza = c.NroCobranza
           AND fc.NumCuota = c.Num_Secuencia
           AND fc.Cod_Almacen = p.Cod_Almacen
        WHERE ISNULL(p.Flg_Estado, 'A') NOT IN ('X', 'R')
          AND fc.ImpCuota > fc.ImpCancelado
          AND (@SoloVencidas = 0 OR fc.Fec_vencDocum <= @Fecha);

        INSERT INTO comp.compensacion
        (
            id_empresa, id_est, Cod_TipAnex, Cod_Anxo, Id_Obligacion, Fecha,
            ImporteSolicitado, ImporteAplicado, Flg_SoloVencidas, Motivo,
            Observacion, Usu_Creacion
        )
        VALUES
        (
            @id_empresa, @id_est, @Cod_TipAnex, @Cod_Anxo, @Id_Obligacion, @Fecha,
            @Importe, 0, CASE WHEN @SoloVencidas = 1 THEN 'S' ELSE 'N' END, @Motivo,
            @Observacion, @Usuario
        );

        SET @IdCompensacion = SCOPE_IDENTITY();

        UPDATE comp.compensacion
        SET Numero = 'CMP-' + RIGHT('00000000' + CONVERT(VARCHAR(8), @IdCompensacion), 8)
        WHERE Id_Compensacion = @IdCompensacion;

        DECLARE
            @Restante DECIMAL(18,2) = @Importe,
            @AplicadoTotal DECIMAL(18,2) = 0,
            @o INT,
            @pr INT,
            @nc CHAR(8),
            @cu INT,
            @al CHAR(2),
            @fv DATE,
            @sa DECIMAL(18,2),
            @ip DECIMAL(18,2),
            @ap DECIMAL(18,2),
            @ia DECIMAL(18,2);

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT Orden, Id_Prestamo, NroCobranza, NumCuota, Cod_Almacen, FecVenc, SaldoAntes, InteresPendiente
            FROM @P
            ORDER BY Orden;

        OPEN cur;
        FETCH NEXT FROM cur INTO @o, @pr, @nc, @cu, @al, @fv, @sa, @ip;

        WHILE @@FETCH_STATUS = 0 AND @Restante > 0
        BEGIN
            SET @ap = CASE WHEN @Restante > @sa THEN @sa ELSE @Restante END;
            SET @ia = CASE WHEN @ap > @ip THEN @ip ELSE @ap END;

            UPDATE dbo.FI_Cobranza_Cuota
            SET ImpCancelado = ImpCancelado + @ap,
                FecCancelado = CASE WHEN ImpCuota <= ImpCancelado + @ap THEN @Fecha ELSE FecCancelado END,
                FlgStatusPago = CASE WHEN ImpCuota <= ImpCancelado + @ap THEN 'C' ELSE 'P' END
            WHERE NroCobranza = @nc
              AND NumCuota = @cu
              AND Cod_Almacen = @al;

            INSERT INTO comp.compensacion_detalle
            (
                Id_Compensacion, OrdenAplicacion, Id_Prestamo, NroCobranza, NumCuota,
                Cod_Almacen, Fec_Venc, SaldoAntes, InteresAplicado, CapitalAplicado,
                ImporteAplicado, SaldoDespues
            )
            VALUES
            (
                @IdCompensacion, @o, @pr, @nc, @cu,
                @al, @fv, @sa, @ia, @ap - @ia,
                @ap, @sa - @ap
            );

            SET @Restante -= @ap;
            SET @AplicadoTotal += @ap;
            FETCH NEXT FROM cur INTO @o, @pr, @nc, @cu, @al, @fv, @sa, @ip;
        END;

        CLOSE cur;
        DEALLOCATE cur;

        IF @AplicadoTotal <= 0
            RAISERROR('No hay deuda elegible para aplicar.', 16, 1);

        IF @Restante > 0
            RAISERROR('El importe supera la deuda elegible seleccionada.', 16, 1);

        UPDATE comp.compensacion
        SET ImporteAplicado = @AplicadoTotal
        WHERE Id_Compensacion = @IdCompensacion;

        UPDATE comp.obligacion
        SET ImporteAplicado = ImporteAplicado + @AplicadoTotal,
            Flg_Estado = CASE WHEN ImporteAplicado + @AplicadoTotal >= Importe THEN 'C' ELSE 'A' END,
            Usu_Modif = @Usuario,
            Fec_Modif = GETDATE()
        WHERE Id_Obligacion = @Id_Obligacion;

        INSERT INTO comp.compensacion_historial
        (
            Id_Compensacion, EstadoNuevo, Motivo, Usuario
        )
        VALUES
        (
            @IdCompensacion, 'A', 'COMPENSACION APLICADA', @Usuario
        );

        COMMIT;
        SET @Ok = 1;
        SET @Mensaje = 'Compensacion aplicada sin movimiento de caja.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        SET @Mensaje = ERROR_MESSAGE();
        SET @IdCompensacion = NULL;
    END CATCH;
END;
GO

IF OBJECT_ID('comp.p_revertir', 'P') IS NULL
    EXEC('CREATE PROCEDURE comp.p_revertir AS BEGIN SET NOCOUNT ON; END');
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE comp.p_revertir
    @id_empresa INT,
    @id_est CHAR(2),
    @IdCompensacion INT,
    @Usuario INT,
    @Ok BIT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Ok = 0;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE
            @IdObligacion INT,
            @ImporteAplicado DECIMAL(18,2),
            @EstadoActual CHAR(1);

        SELECT
            @IdObligacion = Id_Obligacion,
            @ImporteAplicado = ImporteAplicado,
            @EstadoActual = Flg_Estado
        FROM comp.compensacion WITH (UPDLOCK, HOLDLOCK)
        WHERE Id_Compensacion = @IdCompensacion
          AND id_empresa = @id_empresa
          AND id_est = @id_est;

        IF @IdObligacion IS NULL
            RAISERROR('Compensacion no encontrada.', 16, 1);

        IF @EstadoActual <> 'A'
            RAISERROR('Solo se pueden revertir compensaciones aplicadas.', 16, 1);

        UPDATE fc
        SET ImpCancelado = CASE WHEN fc.ImpCancelado >= d.ImporteAplicado THEN fc.ImpCancelado - d.ImporteAplicado ELSE 0 END,
            FecCancelado = CASE WHEN fc.ImpCancelado - d.ImporteAplicado <= 0 THEN NULL ELSE fc.FecCancelado END,
            FlgStatusPago = CASE WHEN fc.ImpCancelado - d.ImporteAplicado <= 0 THEN 'P' ELSE 'P' END
        FROM dbo.FI_Cobranza_Cuota fc
        JOIN comp.compensacion_detalle d
            ON d.NroCobranza = fc.NroCobranza
           AND d.NumCuota = fc.NumCuota
           AND d.Cod_Almacen = fc.Cod_Almacen
        WHERE d.Id_Compensacion = @IdCompensacion;

        UPDATE comp.compensacion
        SET Flg_Estado = 'R',
            Usu_Modif = @Usuario,
            Fec_Modif = GETDATE()
        WHERE Id_Compensacion = @IdCompensacion;

        UPDATE comp.obligacion
        SET ImporteAplicado = CASE WHEN ImporteAplicado >= @ImporteAplicado THEN ImporteAplicado - @ImporteAplicado ELSE 0 END,
            Flg_Estado = 'A',
            Usu_Modif = @Usuario,
            Fec_Modif = GETDATE()
        WHERE Id_Obligacion = @IdObligacion;

        INSERT INTO comp.compensacion_historial
        (
            Id_Compensacion, EstadoNuevo, Motivo, Usuario
        )
        VALUES
        (
            @IdCompensacion, 'R', 'COMPENSACION REVERTIDA', @Usuario
        );

        COMMIT;
        SET @Ok = 1;
        SET @Mensaje = 'Compensacion revertida correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

IF OBJECT_ID('comp.p_listar', 'P') IS NULL
    EXEC('CREATE PROCEDURE comp.p_listar AS BEGIN SET NOCOUNT ON; END');
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE comp.p_listar
    @id_empresa INT,
    @id_est CHAR(2)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Id_Compensacion,
        c.Numero,
        c.Fecha,
        ISNULL(a.Des_Anexo, '') AS Persona,
        o.Cod_Concepto,
        co.Nombre AS Concepto,
        c.ImporteAplicado,
        c.Flg_Estado,
        CASE c.Flg_Estado WHEN 'A' THEN 'Aplicada' WHEN 'R' THEN 'Revertida' ELSE 'Anulada' END AS Estado,
        c.Id_Obligacion,
        c.Fec_Creacion,
        (SELECT COUNT(*) FROM comp.compensacion_detalle d WHERE d.Id_Compensacion = c.Id_Compensacion) AS CuotasAfectadas
    FROM comp.compensacion c
    JOIN comp.obligacion o
        ON o.Id_Obligacion = c.Id_Obligacion
    JOIN comp.concepto_obligacion co
        ON co.Cod_Concepto = o.Cod_Concepto
    LEFT JOIN dbo.CN_AnexosContables a
        ON a.Cod_TipAnex = c.Cod_TipAnex
       AND a.Cod_Anxo = c.Cod_Anxo
    WHERE c.id_empresa = @id_empresa
      AND c.id_est = @id_est
    ORDER BY c.Id_Compensacion DESC;
END;
GO

IF OBJECT_ID('comp.p_obtener', 'P') IS NULL
    EXEC('CREATE PROCEDURE comp.p_obtener AS BEGIN SET NOCOUNT ON; END');
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE comp.p_obtener
    @id_empresa INT,
    @id_est CHAR(2),
    @IdCompensacion INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.*,
        ISNULL(a.Des_Anexo, '') AS Persona,
        ISNULL(a.Num_Ruc, '') AS Documento,
        co.Nombre AS Concepto,
        o.Importe AS ImporteObligacion,
        o.ImporteAplicado AS ImporteObligacionAplicado,
        o.Importe - o.ImporteAplicado AS SaldoFavorActual
    FROM comp.compensacion c
    JOIN comp.obligacion o
        ON o.Id_Obligacion = c.Id_Obligacion
    JOIN comp.concepto_obligacion co
        ON co.Cod_Concepto = o.Cod_Concepto
    LEFT JOIN dbo.CN_AnexosContables a
        ON a.Cod_TipAnex = c.Cod_TipAnex
       AND a.Cod_Anxo = c.Cod_Anxo
    WHERE c.Id_Compensacion = @IdCompensacion
      AND c.id_empresa = @id_empresa
      AND c.id_est = @id_est;

    SELECT *
    FROM comp.compensacion_detalle
    WHERE Id_Compensacion = @IdCompensacion
    ORDER BY OrdenAplicacion;

    SELECT *
    FROM comp.compensacion_historial
    WHERE Id_Compensacion = @IdCompensacion
    ORDER BY Id_Historial;
END;
GO

IF OBJECT_ID('comp.p_prestamos_cliente', 'P') IS NULL
    EXEC('CREATE PROCEDURE comp.p_prestamos_cliente AS BEGIN SET NOCOUNT ON; END');
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE comp.p_prestamos_cliente
    @id_empresa INT,
    @Cod_TipAnex CHAR(1),
    @Cod_Anxo CHAR(6),
    @FechaCorte DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.Id_Prestamo,
        p.Fecha,
        p.FechaFinCobro,
        ISNULL(cp.Nombre, '') AS Concepto,
        CAST(SUM(CASE WHEN fc.ImpCuota > fc.ImpCancelado THEN fc.ImpCuota - fc.ImpCancelado ELSE 0 END) AS DECIMAL(18,2)) AS SaldoPendiente,
        CAST(SUM(CASE WHEN fc.Fec_vencDocum <= @FechaCorte AND fc.ImpCuota > fc.ImpCancelado THEN fc.ImpCuota - fc.ImpCancelado ELSE 0 END) AS DECIMAL(18,2)) AS SaldoVencido,
        SUM(CASE WHEN fc.Fec_vencDocum <= @FechaCorte AND fc.ImpCuota > fc.ImpCancelado THEN 1 ELSE 0 END) AS CuotasVencidas
    FROM prest.prestamo p
    JOIN prest.cuota c
        ON c.Id_Prestamo = p.Id_Prestamo
    JOIN dbo.FI_Cobranza_Cuota fc
        ON fc.NroCobranza = c.NroCobranza
       AND fc.NumCuota = c.Num_Secuencia
       AND fc.Cod_Almacen = p.Cod_Almacen
    LEFT JOIN prest.concepto cp
        ON cp.Cod_Concepto = p.Cod_Concepto
    WHERE p.Cod_TipAnex = @Cod_TipAnex
      AND p.Cod_Anxo = @Cod_Anxo
      AND ISNULL(p.Flg_Estado, 'A') NOT IN ('X', 'R')
    GROUP BY p.Id_Prestamo, p.Fecha, p.FechaFinCobro, cp.Nombre
    HAVING SUM(CASE WHEN fc.ImpCuota > fc.ImpCancelado THEN fc.ImpCuota - fc.ImpCancelado ELSE 0 END) > 0
    ORDER BY p.Fecha, p.Id_Prestamo;
END;
GO

PRINT 'Fix de SPs comp listo para DB_9FA64E_bdgas.';
