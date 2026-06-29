/* =====================================================
   PAGO GLOBAL POR CLIENTE
   - Simula y aplica pagos a cuotas vencidas/antiguas.
   - Usa estados VARCHAR(1).
   - No modifica reglas de continuidad/refinanciacion.
===================================================== */

IF OBJECT_ID('prest.pago_global_detalle', 'U') IS NULL
BEGIN
    CREATE TABLE prest.pago_global_detalle
    (
        Id_PagoGlobalDetalle INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Id_PagoGlobal INT NOT NULL,
        Id_Prestamo INT NOT NULL,
        NroCobranza CHAR(8) NOT NULL,
        NumCuota INT NOT NULL,
        Cod_Almacen CHAR(2) NOT NULL,
        Fec_Venc DATETIME NULL,
        DeudaAntes DECIMAL(18,2) NOT NULL,
        ImporteAplicado DECIMAL(18,2) NOT NULL,
        SaldoDespues DECIMAL(18,2) NOT NULL,
        OrdenAplicacion INT NOT NULL,
        Fec_Creacion DATETIME NOT NULL CONSTRAINT DF_pago_global_detalle_fec DEFAULT (GETDATE())
    );
END
GO

IF OBJECT_ID('prest.pago_global', 'U') IS NULL
BEGIN
    CREATE TABLE prest.pago_global
    (
        Id_PagoGlobal INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Cod_TipAnex CHAR(1) NOT NULL,
        Cod_Anxo CHAR(6) NOT NULL,
        Fec_Pago DATETIME NOT NULL,
        ImportePago DECIMAL(18,2) NOT NULL,
        ImporteAplicado DECIMAL(18,2) NOT NULL CONSTRAINT DF_pago_global_aplicado DEFAULT (0),
        ImporteExcedente DECIMAL(18,2) NOT NULL CONSTRAINT DF_pago_global_excedente DEFAULT (0),
        IdFormaPago INT NOT NULL,
        Cod_CajaChica CHAR(2) NOT NULL,
        Num_Movstk INT NULL,
        Num_Transaccion INT NULL,
        Sec_Movimiento INT NULL,
        Glosa VARCHAR(250) NULL,
        Flg_Estado VARCHAR(1) NOT NULL CONSTRAINT DF_pago_global_estado DEFAULT ('A'),
        Usu_Creacion INT NULL,
        Cod_Estacion VARCHAR(150) NULL,
        Fec_Creacion DATETIME NOT NULL CONSTRAINT DF_pago_global_fec DEFAULT (GETDATE())
    );

    ALTER TABLE prest.pago_global_detalle
    ADD CONSTRAINT FK_pago_global_detalle_cab
        FOREIGN KEY (Id_PagoGlobal) REFERENCES prest.pago_global(Id_PagoGlobal);
END
GO

IF OBJECT_ID('prest.p_pago_global_cliente_simular', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_pago_global_cliente_simular;
GO

CREATE PROCEDURE prest.p_pago_global_cliente_simular
(
    @Cod_TipAnex CHAR(1),
    @Cod_Anxo CHAR(6),
    @ImportePago DECIMAL(18,2),
    @SoloVencidas VARCHAR(1) = 'N'
)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@ImportePago, 0) <= 0
    BEGIN
        SELECT CAST(0 AS BIT) Ok, 'El importe debe ser mayor a cero.' Mensaje;
        RETURN;
    END

    DECLARE @MontoRestante DECIMAL(18,2) = @ImportePago;

    IF OBJECT_ID('tempdb..#pendientes') IS NOT NULL DROP TABLE #pendientes;
    IF OBJECT_ID('tempdb..#aplicacion') IS NOT NULL DROP TABLE #aplicacion;

    SELECT
        ROW_NUMBER() OVER
        (
            ORDER BY
                CASE WHEN fc.Fec_vencDocum < CONVERT(date, GETDATE()) THEN 0 ELSE 1 END,
                fc.Fec_vencDocum,
                p.Id_Prestamo,
                fc.NumCuota
        ) AS Orden,
        p.Id_Prestamo,
        ISNULL(a.Des_Anexo, '') AS Cliente,
        fc.NroCobranza,
        fc.NumCuota,
        fc.Cod_Almacen,
        fc.Fec_vencDocum,
        CAST(ISNULL(fc.ImporteBase, 0) AS DECIMAL(18,2)) AS ImporteBase,
        CAST(ISNULL(fc.ImporteInteres, 0) AS DECIMAL(18,2)) AS ImporteInteres,
        CAST(ISNULL(fc.ImpCuota, 0) AS DECIMAL(18,2)) AS ImpCuota,
        CAST(ISNULL(fc.ImpCancelado, 0) AS DECIMAL(18,2)) AS ImpCancelado,
        CAST(ISNULL(fc.ImpCuota, 0) - ISNULL(fc.ImpCancelado, 0) AS DECIMAL(18,2)) AS SaldoCuota
    INTO #pendientes
    FROM prest.prestamo p
    INNER JOIN prest.cuota c
        ON c.Id_Prestamo = p.Id_Prestamo
    INNER JOIN dbo.FI_Cobranza_Cuota fc
        ON fc.NroCobranza = c.NroCobranza
       AND fc.NumCuota = c.Num_Secuencia
       AND fc.Cod_Almacen = p.Cod_Almacen
    LEFT JOIN dbo.CN_AnexosContables a
        ON a.Cod_TipAnex = p.Cod_TipAnex
       AND a.Cod_Anxo = p.Cod_Anxo
    WHERE p.Cod_TipAnex = @Cod_TipAnex
      AND p.Cod_Anxo = @Cod_Anxo
      AND ISNULL(p.Flg_Estado, 'A') <> 'X'
      AND ISNULL(fc.FlgStatusPago, 'P') <> 'C'
      AND CAST(ISNULL(fc.ImpCuota, 0) - ISNULL(fc.ImpCancelado, 0) AS DECIMAL(18,2)) > 0
      AND (@SoloVencidas <> 'S' OR fc.Fec_vencDocum < CONVERT(date, GETDATE()));

    CREATE TABLE #aplicacion
    (
        OrdenAplicacion INT NOT NULL,
        Id_Prestamo INT NOT NULL,
        Cliente VARCHAR(150) NOT NULL,
        NroCobranza CHAR(8) NOT NULL,
        NumCuota INT NOT NULL,
        Cod_Almacen CHAR(2) NOT NULL,
        Fec_Venc DATETIME NULL,
        DeudaAntes DECIMAL(18,2) NOT NULL,
        ImporteAplicado DECIMAL(18,2) NOT NULL,
        SaldoDespues DECIMAL(18,2) NOT NULL
    );

    DECLARE
        @Orden INT,
        @IdPrestamo INT,
        @Cliente VARCHAR(150),
        @NroCobranza CHAR(8),
        @NumCuota INT,
        @CodAlmacen CHAR(2),
        @FecVenc DATETIME,
        @SaldoCuota DECIMAL(18,2),
        @Aplicado DECIMAL(18,2);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Orden, Id_Prestamo, Cliente, NroCobranza, NumCuota, Cod_Almacen, Fec_vencDocum, SaldoCuota
        FROM #pendientes
        ORDER BY Orden;

    OPEN cur;
    FETCH NEXT FROM cur INTO @Orden, @IdPrestamo, @Cliente, @NroCobranza, @NumCuota, @CodAlmacen, @FecVenc, @SaldoCuota;

    WHILE @@FETCH_STATUS = 0 AND @MontoRestante > 0
    BEGIN
        SET @Aplicado = CASE WHEN @MontoRestante >= @SaldoCuota THEN @SaldoCuota ELSE @MontoRestante END;

        INSERT INTO #aplicacion
        (
            OrdenAplicacion, Id_Prestamo, Cliente, NroCobranza, NumCuota, Cod_Almacen,
            Fec_Venc, DeudaAntes, ImporteAplicado, SaldoDespues
        )
        VALUES
        (
            @Orden, @IdPrestamo, @Cliente, @NroCobranza, @NumCuota, @CodAlmacen,
            @FecVenc, @SaldoCuota, @Aplicado, @SaldoCuota - @Aplicado
        );

        SET @MontoRestante = @MontoRestante - @Aplicado;
        FETCH NEXT FROM cur INTO @Orden, @IdPrestamo, @Cliente, @NroCobranza, @NumCuota, @CodAlmacen, @FecVenc, @SaldoCuota;
    END

    CLOSE cur;
    DEALLOCATE cur;

    SELECT
        CAST(1 AS BIT) Ok,
        'Simulacion generada correctamente.' Mensaje,
        @ImportePago ImportePago,
        ISNULL(SUM(ImporteAplicado), 0) ImporteAplicado,
        @ImportePago - ISNULL(SUM(ImporteAplicado), 0) ImporteExcedente,
        COUNT(1) CuotasAplicadas,
        COUNT(DISTINCT Id_Prestamo) PrestamosAplicados
    FROM #aplicacion;

    SELECT
        OrdenAplicacion,
        Id_Prestamo,
        Cliente,
        NroCobranza,
        NumCuota,
        Cod_Almacen,
        Fec_Venc,
        DeudaAntes,
        ImporteAplicado,
        SaldoDespues
    FROM #aplicacion
    ORDER BY OrdenAplicacion;
END
GO

IF OBJECT_ID('prest.p_pago_global_cliente_aplicar', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_pago_global_cliente_aplicar;
GO

CREATE PROCEDURE prest.p_pago_global_cliente_aplicar
(
    @Cod_TipAnex CHAR(1),
    @Cod_Anxo CHAR(6),
    @ImportePago DECIMAL(18,2),
    @Fec_Pago DATETIME,
    @IdFormaPago INT,
    @Cod_CajaChica CHAR(2),
    @Glosa VARCHAR(250) = NULL,
    @CodUsuarioCreacion INT,
    @CodEstacion VARCHAR(150) = NULL,
    @PermitirExcedente BIT = 0,
    @Ok BIT OUTPUT,
    @Mensaje VARCHAR(500) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @IdPagoGlobal INT,
        @MontoRestante DECIMAL(18,2),
        @MontoAplicadoTotal DECIMAL(18,2) = 0,
        @MontoExcedente DECIMAL(18,2) = 0,
        @Num_Movstk INT,
        @Num_Transaccion INT,
        @Sec_Movimiento INT,
        @Cod_Concepto_Caja CHAR(3) = '172',
        @GlosaCaja VARCHAR(500);

    BEGIN TRY
        BEGIN TRAN;

        SET @Ok = 0;
        SET @Mensaje = '';
        SET @MontoRestante = ISNULL(@ImportePago, 0);

        IF @MontoRestante <= 0
            RAISERROR('El importe de pago debe ser mayor a cero.', 16, 1);

        IF ISNULL(@Cod_CajaChica, '') = ''
            RAISERROR('La caja es obligatoria.', 16, 1);

        SELECT
            @Num_Movstk = Num_Movstk,
            @Num_Transaccion = Num_Transaccion
        FROM dbo.CJ_Movimientos
        WHERE Cod_CajaChica = @Cod_CajaChica
          AND Flg_Status = 'P';

        IF ISNULL(@Num_Movstk, 0) = 0 OR ISNULL(@Num_Transaccion, 0) = 0
            RAISERROR('No existe una caja abierta/pendiente para la caja chica indicada.', 16, 1);

        INSERT INTO prest.pago_global
        (
            Cod_TipAnex, Cod_Anxo, Fec_Pago, ImportePago, ImporteAplicado, ImporteExcedente,
            IdFormaPago, Cod_CajaChica, Num_Movstk, Num_Transaccion, Glosa, Flg_Estado,
            Usu_Creacion, Cod_Estacion
        )
        VALUES
        (
            @Cod_TipAnex, @Cod_Anxo, @Fec_Pago, @ImportePago, 0, 0,
            @IdFormaPago, @Cod_CajaChica, @Num_Movstk, @Num_Transaccion, @Glosa, 'A',
            @CodUsuarioCreacion, @CodEstacion
        );

        SET @IdPagoGlobal = SCOPE_IDENTITY();

        IF OBJECT_ID('tempdb..#pendientes_apply') IS NOT NULL DROP TABLE #pendientes_apply;

        SELECT
            ROW_NUMBER() OVER
            (
                ORDER BY
                    CASE WHEN fc.Fec_vencDocum < CONVERT(date, GETDATE()) THEN 0 ELSE 1 END,
                    fc.Fec_vencDocum,
                    p.Id_Prestamo,
                    fc.NumCuota
            ) AS Orden,
            p.Id_Prestamo,
            fc.NroCobranza,
            fc.NumCuota,
            fc.Cod_Almacen,
            fc.Fec_vencDocum,
            CAST(ISNULL(fc.ImpCuota, 0) AS DECIMAL(18,2)) AS ImpCuota,
            CAST(ISNULL(fc.ImpCancelado, 0) AS DECIMAL(18,2)) AS ImpCancelado,
            CAST(ISNULL(fc.ImpCuota, 0) - ISNULL(fc.ImpCancelado, 0) AS DECIMAL(18,2)) AS SaldoCuota
        INTO #pendientes_apply
        FROM prest.prestamo p
        INNER JOIN prest.cuota c
            ON c.Id_Prestamo = p.Id_Prestamo
        INNER JOIN dbo.FI_Cobranza_Cuota fc
            ON fc.NroCobranza = c.NroCobranza
           AND fc.NumCuota = c.Num_Secuencia
           AND fc.Cod_Almacen = p.Cod_Almacen
        WHERE p.Cod_TipAnex = @Cod_TipAnex
          AND p.Cod_Anxo = @Cod_Anxo
          AND ISNULL(p.Flg_Estado, 'A') <> 'X'
          AND ISNULL(fc.FlgStatusPago, 'P') <> 'C'
          AND CAST(ISNULL(fc.ImpCuota, 0) - ISNULL(fc.ImpCancelado, 0) AS DECIMAL(18,2)) > 0;

        DECLARE
            @Orden INT,
            @IdPrestamo INT,
            @NroCobranza CHAR(8),
            @NumCuota INT,
            @CodAlmacen CHAR(2),
            @FecVenc DATETIME,
            @ImpCuota DECIMAL(18,2),
            @ImpCancelado DECIMAL(18,2),
            @SaldoCuota DECIMAL(18,2),
            @Aplicado DECIMAL(18,2),
            @NuevoCancelado DECIMAL(18,2),
            @NuevoSaldo DECIMAL(18,2),
            @SecPago INT;

        DECLARE cur_apply CURSOR LOCAL FAST_FORWARD FOR
            SELECT Orden, Id_Prestamo, NroCobranza, NumCuota, Cod_Almacen, Fec_vencDocum, ImpCuota, ImpCancelado, SaldoCuota
            FROM #pendientes_apply
            ORDER BY Orden;

        OPEN cur_apply;
        FETCH NEXT FROM cur_apply INTO @Orden, @IdPrestamo, @NroCobranza, @NumCuota, @CodAlmacen, @FecVenc, @ImpCuota, @ImpCancelado, @SaldoCuota;

        WHILE @@FETCH_STATUS = 0 AND @MontoRestante > 0
        BEGIN
            SET @Aplicado = CASE WHEN @MontoRestante >= @SaldoCuota THEN @SaldoCuota ELSE @MontoRestante END;
            SET @NuevoCancelado = @ImpCancelado + @Aplicado;
            SET @NuevoSaldo = @ImpCuota - @NuevoCancelado;

            SELECT @SecPago = ISNULL(MAX(Sec_Pago), 0) + 1
            FROM dbo.FI_Cobranza_Pago
            WHERE NroCobranza = @NroCobranza
              AND NumCuota = @NumCuota
              AND Cod_Almacen = @CodAlmacen;

            INSERT INTO dbo.FI_Cobranza_Pago
            (
                NroCobranza, NumCuota, Sec_Pago, Cod_Almacen, Fec_Pago, Fec_Creacion,
                Importe, Deuda, Saldo, Flg_Status_Pago, IdFormaPago, BancoId, CuentaBancoId,
                Glosa, CodUsuarioCreacion, FlgExcepcional, CodEstacion
            )
            VALUES
            (
                @NroCobranza, @NumCuota, @SecPago, @CodAlmacen, @Fec_Pago, GETDATE(),
                @Aplicado, @SaldoCuota, @NuevoSaldo,
                CASE WHEN @NuevoSaldo <= 0 THEN 'C' ELSE 'P' END,
                @IdFormaPago, NULL, NULL, @Glosa, @CodUsuarioCreacion, 'N', @CodEstacion
            );

            UPDATE dbo.FI_Cobranza_Cuota
            SET
                ImpCancelado = @NuevoCancelado,
                FecCancelado = CASE WHEN @NuevoSaldo <= 0 THEN @Fec_Pago ELSE FecCancelado END,
                FlgStatusPago = CASE WHEN @NuevoSaldo <= 0 THEN 'C' ELSE 'P' END
            WHERE NroCobranza = @NroCobranza
              AND NumCuota = @NumCuota
              AND Cod_Almacen = @CodAlmacen;

            INSERT INTO prest.pago_global_detalle
            (
                Id_PagoGlobal, Id_Prestamo, NroCobranza, NumCuota, Cod_Almacen,
                Fec_Venc, DeudaAntes, ImporteAplicado, SaldoDespues, OrdenAplicacion
            )
            VALUES
            (
                @IdPagoGlobal, @IdPrestamo, @NroCobranza, @NumCuota, @CodAlmacen,
                @FecVenc, @SaldoCuota, @Aplicado, @NuevoSaldo, @Orden
            );

            SET @MontoAplicadoTotal = @MontoAplicadoTotal + @Aplicado;
            SET @MontoRestante = @MontoRestante - @Aplicado;

            FETCH NEXT FROM cur_apply INTO @Orden, @IdPrestamo, @NroCobranza, @NumCuota, @CodAlmacen, @FecVenc, @ImpCuota, @ImpCancelado, @SaldoCuota;
        END

        CLOSE cur_apply;
        DEALLOCATE cur_apply;

        SET @MontoExcedente = @MontoRestante;

        IF @MontoExcedente > 0 AND ISNULL(@PermitirExcedente, 0) = 0
            RAISERROR('El pago excede la deuda pendiente del cliente.', 16, 1);

        IF ISNULL(@MontoAplicadoTotal, 0) <= 0
            RAISERROR('No existe monto aplicado valido para registrar.', 16, 1);

        SET @GlosaCaja = LEFT(
            ISNULL(@Glosa, 'PAGO GLOBAL CLIENTE')
            + ' | Cliente: ' + @Cod_TipAnex + '-' + @Cod_Anxo
            + ' | PagoGlobal: ' + CONVERT(VARCHAR(20), @IdPagoGlobal),
            500
        );

        DECLARE @PrimerNroCobranza CHAR(8), @PrimerNumCuota INT, @PrimerCodAlmacen CHAR(2);
        SELECT TOP 1
            @PrimerNroCobranza = NroCobranza,
            @PrimerNumCuota = NumCuota,
            @PrimerCodAlmacen = Cod_Almacen
        FROM prest.pago_global_detalle
        WHERE Id_PagoGlobal = @IdPagoGlobal
        ORDER BY OrdenAplicacion;

        EXEC dbo.CJ_MAN_MOVIMIENTO_DETALLE
             @ACCION = 'I',
             @Cod_CajaChica = @Cod_CajaChica,
             @Num_Movstk = @Num_Movstk,
             @Sec_Movimiento = 0,
             @Num_Transaccion = @Num_Transaccion,
             @Fec_Movimiento = @Fec_Pago,
             @Cod_Concepto_Caja = @Cod_Concepto_Caja,
             @Cod_TipAnex = @Cod_TipAnex,
             @Cod_Anxo = @Cod_Anxo,
             @Cod_Moneda_Docum = 'SOL',
             @Imp_Movimiento_MonedaDocum = @MontoAplicadoTotal,
             @Imp_Movimiento = @MontoAplicadoTotal,
             @Tipo_Cambio = 1,
             @Tipo_Cambio_Otros = 0,
             @Cod_TipDoc = '20',
             @Ser_docum = '',
             @Num_Docum = '',
             @Glosa = @GlosaCaja,
             @Beneficiario = '',
             @Cod_Area = '02',
             @Cod_Usuario = @CodUsuarioCreacion,
             @Cod_Estacion = @CodEstacion,
             @FLG_TRANSACCION = 'N',
             @Num_Corre_Compras = '',
             @Sec_Pago_Compras = '',
             @Flg_Ingresado_Caja_Usuario = 'N',
             @cod_Fabrica = '',
             @Tip_Trabajador = '',
             @Cod_Trabajador = '',
             @nro_docide_beneficiario = '',
             @Motivo = '',
             @De = '',
             @A = '',
             @Cod_ClaBie = '',
             @Num_corre_doc_diversos = '',
             @Num_Cobranza = @PrimerNroCobranza,
             @NumCuota = @PrimerNumCuota,
             @Cod_Almacen = @PrimerCodAlmacen;

        SELECT @Sec_Movimiento = MAX(d.Sec_Movimiento)
        FROM dbo.CJ_Movimientos_Detalle d
        WHERE d.Cod_CajaChica = @Cod_CajaChica
          AND d.Num_Movstk = @Num_Movstk
          AND d.NroCobranza = @PrimerNroCobranza
          AND d.Cod_Almacen = @PrimerCodAlmacen;

        IF ISNULL(@Sec_Movimiento, 0) = 0
            RAISERROR('No se pudo recuperar el movimiento de caja generado.', 16, 1);

        DECLARE cur_app CURSOR LOCAL FAST_FORWARD FOR
            SELECT NroCobranza, NumCuota, Cod_Almacen, ImporteAplicado
            FROM prest.pago_global_detalle
            WHERE Id_PagoGlobal = @IdPagoGlobal
            ORDER BY OrdenAplicacion;

        DECLARE @ImporteAplicado DECIMAL(18,2);
        OPEN cur_app;
        FETCH NEXT FROM cur_app INTO @NroCobranza, @NumCuota, @CodAlmacen, @ImporteAplicado;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.FI_REGISTRAR_PAGO_COBRANZA_APLICACION
                 @Cod_CajaChica = @Cod_CajaChica,
                 @Num_Movstk = @Num_Movstk,
                 @Sec_Movimiento = @Sec_Movimiento,
                 @NroCobranza = @NroCobranza,
                 @NumCuota = @NumCuota,
                 @Cod_Almacen = @CodAlmacen,
                 @ImporteAplicado = @ImporteAplicado,
                 @Glosa = @Glosa,
                 @CodUsuarioCreacion = @CodUsuarioCreacion;

            FETCH NEXT FROM cur_app INTO @NroCobranza, @NumCuota, @CodAlmacen, @ImporteAplicado;
        END

        CLOSE cur_app;
        DEALLOCATE cur_app;

        UPDATE prest.pago_global
        SET
            ImporteAplicado = @MontoAplicadoTotal,
            ImporteExcedente = @MontoExcedente,
            Sec_Movimiento = @Sec_Movimiento
        WHERE Id_PagoGlobal = @IdPagoGlobal;

        COMMIT;

        SET @Ok = 1;
        SET @Mensaje =
            'Pago global registrado correctamente. Id: '
            + CONVERT(VARCHAR(20), @IdPagoGlobal)
            + ' | Aplicado: S/ ' + CONVERT(VARCHAR(30), @MontoAplicadoTotal)
            + CASE WHEN @MontoExcedente > 0 THEN ' | Excedente no aplicado: S/ ' + CONVERT(VARCHAR(30), @MontoExcedente) ELSE '' END;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local','cur_apply') >= 0
        BEGIN
            CLOSE cur_apply;
        END

        IF CURSOR_STATUS('local','cur_apply') >= -1
        BEGIN
            DEALLOCATE cur_apply;
        END

        IF CURSOR_STATUS('local','cur_app') >= 0
        BEGIN
            CLOSE cur_app;
        END

        IF CURSOR_STATUS('local','cur_app') >= -1
        BEGIN
            DEALLOCATE cur_app;
        END

        IF @@TRANCOUNT > 0
            ROLLBACK;

        SET @Ok = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO
