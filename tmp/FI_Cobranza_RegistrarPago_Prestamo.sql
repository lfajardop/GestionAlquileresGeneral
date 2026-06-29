CREATE PROCEDURE [dbo].[FI_Cobranza_RegistrarPago_Prestamo]
(
    @prest_id			INT,
    @Cod_Almacen        CHAR(2),
    @ImportePago        DECIMAL(18,2),
    @Fec_Pago           DATETIME,
    @IdFormaPago        INT,
    @Cod_CajaChica      CHAR(2),
    @BancoId            INT = NULL,
    @CuentaBancoId      INT = NULL,
    @Glosa              VARCHAR(250) = NULL,
    @CodUsuarioCreacion INT,
    @CodEstacion        VARCHAR(150) = NULL,
    @PermitirExcedente  BIT = 0,
    -- para CJ_MAN_MOVIMIENTO_DETALLE
   -- @Cod_TipAnex        CHAR(1),
   -- @Cod_Anxo           CHAR(6),
    @Cod_TipDoc         CHAR(2) = '20',
    @Ser_docum          CHAR(4) = '',
    @Num_Docum          VARCHAR(50) = '',

    @Ok                 BIT OUTPUT,
    @Mensaje            VARCHAR(500) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

	

        DECLARE @MontoRestante DECIMAL(18,2);
        DECLARE @MontoAplicadoTotal DECIMAL(18,2);

        DECLARE @NumCuota INT;
        DECLARE @DeudaCuota DECIMAL(18,2);
        DECLARE @ImporteAplicado DECIMAL(18,2);
        DECLARE @NuevoSaldo DECIMAL(18,2);
        DECLARE @Sec_Pago INT;

        DECLARE @Num_Movstk INT;
        DECLARE @Num_Transaccion INT;
        DECLARE @CodigoMoneda VARCHAR(10);
        DECLARE @Cod_Concepto_Caja CHAR(3) = '172';
		DECLARE @Cod_TipAnex CHAR(1);
		DECLARE @Cod_Anxo           CHAR(6)


        DECLARE @Sec_Movimiento_Generado INT;

        DECLARE @Aplicaciones TABLE
        (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            NumCuota INT NOT NULL,
            ImporteAplicado DECIMAL(18,2) NOT NULL
        );

		DECLARE @NumCuotaCaja INT;
		DECLARE @ListaCuotas VARCHAR(300);
		DECLARE @GlosaCaja VARCHAR(500);

		DECLARE @NroCobranza  CHAR(8);

        SET @Ok = 0;
        SET @Mensaje = '';
        SET @MontoRestante = ISNULL(@ImportePago,0);
        SET @MontoAplicadoTotal = 0;
        SET @Sec_Movimiento_Generado = 0;

			SELECT @NroCobranza= NroCobranza
			FROM dbo.FI_CobranzaPedido WHERE IdOrigen=@prest_id

			SELECT @NroCobranza

        IF ISNULL(@NroCobranza,'') = ''
            RAISERROR('NroCobranza es obligatorio.',16,1);

        IF ISNULL(@Cod_Almacen,'') = ''
            RAISERROR('Cod_Almacen es obligatorio.',16,1);

        IF ISNULL(@ImportePago,0) <= 0
            RAISERROR('El importe de pago debe ser mayor a cero.',16,1);

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.FI_Cobranza_Cuota
            WHERE NroCobranza = @NroCobranza
              AND Cod_Almacen = @Cod_Almacen
        )
            RAISERROR('No existe la cobranza/cuotas para el NroCobranza indicado.',16,1);

        SELECT
            @Num_Movstk = Num_Movstk,
            @Num_Transaccion = Num_Transaccion
        FROM dbo.CJ_Movimientos
        WHERE Cod_CajaChica = @Cod_CajaChica
          AND Flg_Status = 'P';

        IF ISNULL(@Num_Movstk,0) = 0 OR ISNULL(@Num_Transaccion,0) = 0
            RAISERROR('No existe una caja abierta/pendiente para la caja chica indicada.',16,1);

        --SELECT @CodigoMoneda = ISNULL(codigoMoneda,'SOL')
        --FROM dbo.Moneda WHERE codigoMoneda='PEN'

        --IF ISNULL(@CodigoMoneda,'') = ''
        --    SET @CodigoMoneda = 'SOL';



        DECLARE @CuotasPendientes TABLE
        (
            NumCuota INT PRIMARY KEY,
            DeudaCuota DECIMAL(18,2)
        );

		select @Cod_TipAnex=Cod_TipAnex ,@Cod_Anxo=Cod_Anxo
		 FROM dbo.FI_CobranzaPedido  
		WHERE NroCobranza=@NroCobranza AND Cod_Almacen=@Cod_Almacen;

        INSERT INTO @CuotasPendientes (NumCuota, DeudaCuota)
        SELECT
            c.NumCuota,
            CAST(ISNULL(c.ImpCuota,0) - ISNULL(c.ImpCancelado,0) AS DECIMAL(18,2))
        FROM dbo.FI_Cobranza_Cuota c
        WHERE c.NroCobranza = @NroCobranza
          AND c.Cod_Almacen = @Cod_Almacen
          AND CAST(ISNULL(c.ImpCuota,0) - ISNULL(c.ImpCancelado,0) AS DECIMAL(18,2)) > 0
        ORDER BY c.NumCuota;

        DECLARE cur_cuotas CURSOR LOCAL FAST_FORWARD FOR
            SELECT NumCuota, DeudaCuota
            FROM @CuotasPendientes
            ORDER BY NumCuota;

        OPEN cur_cuotas;
        FETCH NEXT FROM cur_cuotas INTO @NumCuota, @DeudaCuota;

	

	WHILE @@FETCH_STATUS = 0 AND @MontoRestante > 0
	BEGIN
		DECLARE @ImpCuotaActual       DECIMAL(18,2);
		DECLARE @ImpCanceladoActual   DECIMAL(18,2);
		DECLARE @DeudaCuotaActual     DECIMAL(18,2);
		DECLARE @NuevoImpCancelado    DECIMAL(18,2);

			SELECT
				@ImpCuotaActual = ISNULL(ImpCuota, 0),
				@ImpCanceladoActual = ISNULL(ImpCancelado, 0)
			FROM dbo.FI_Cobranza_Cuota
			WHERE NroCobranza = @NroCobranza
			  AND NumCuota = @NumCuota
			  AND Cod_Almacen = @Cod_Almacen;

			SET @DeudaCuotaActual = @ImpCuotaActual - @ImpCanceladoActual;

			IF @DeudaCuotaActual <= 0
			BEGIN
				FETCH NEXT FROM cur_cuotas INTO @NumCuota, @DeudaCuota;
				CONTINUE;
			END

			SET @ImporteAplicado =
				CASE
					WHEN @MontoRestante >= @DeudaCuotaActual THEN @DeudaCuotaActual
					ELSE @MontoRestante
				END;

			SET @NuevoImpCancelado = @ImpCanceladoActual + @ImporteAplicado;
			SET @NuevoSaldo = @ImpCuotaActual - @NuevoImpCancelado;

			SELECT @Sec_Pago = ISNULL(MAX(Sec_Pago), 0) + 1
			FROM dbo.FI_Cobranza_Pago
			WHERE NroCobranza = @NroCobranza
			  AND NumCuota = @NumCuota
			  AND Cod_Almacen = @Cod_Almacen;

			INSERT INTO dbo.FI_Cobranza_Pago
			(
				NroCobranza,
				NumCuota,
				Sec_Pago,
				Cod_Almacen,
				Fec_Pago,
				Fec_Creacion,
				Importe,
				Deuda,
				Saldo,
				Flg_Status_Pago,
				IdFormaPago,
				BancoId,
				CuentaBancoId,
				Glosa,
				CodUsuarioCreacion,
				FlgExcepcional,
				CodEstacion
			)
			VALUES
			(
				@NroCobranza,
				@NumCuota,
				@Sec_Pago,
				@Cod_Almacen,
				@Fec_Pago,
				GETDATE(),
				@ImporteAplicado,
				@DeudaCuotaActual,
				@NuevoSaldo,
				CASE
					WHEN @NuevoSaldo <= 0 THEN 'C'
					ELSE 'P'
				END,
				@IdFormaPago,
				@BancoId,
				@CuentaBancoId,
				@Glosa,
				@CodUsuarioCreacion,
				'N',
				@CodEstacion
			);

			UPDATE dbo.FI_Cobranza_Cuota
			SET
				ImpCancelado = @NuevoImpCancelado,
				FecCancelado = CASE
								   WHEN @NuevoSaldo <= 0 THEN @Fec_Pago
								   ELSE FecCancelado
							   END,
				FlgStatusPago = CASE
									WHEN @NuevoSaldo <= 0 THEN 'C'
									WHEN @NuevoImpCancelado > 0 THEN 'P'
									ELSE 'P'
								END
			WHERE NroCobranza = @NroCobranza
			  AND NumCuota = @NumCuota
			  AND Cod_Almacen = @Cod_Almacen;

			INSERT INTO @Aplicaciones (NumCuota, ImporteAplicado)
			VALUES (@NumCuota, @ImporteAplicado);

			SET @MontoRestante = @MontoRestante - @ImporteAplicado;
			SET @MontoAplicadoTotal = @MontoAplicadoTotal + @ImporteAplicado;

			FETCH NEXT FROM cur_cuotas INTO @NumCuota, @DeudaCuota;
		END

        CLOSE cur_cuotas;
        DEALLOCATE cur_cuotas;

				 DECLARE @MontoExcedente DECIMAL(18,2);
			SET @MontoExcedente = @MontoRestante;

			-- Si NO se permite excedente ? error
			IF @MontoRestante > 0 AND ISNULL(@PermitirExcedente,0) = 0
			BEGIN
				RAISERROR('El pago excede la deuda pendiente.',16,1);
			END

			-- Si se permite ? solo ignorar el excedente (NO insertar)
			IF @MontoRestante > 0 AND ISNULL(@PermitirExcedente,0) = 1
			BEGIN
				-- NO se inserta en FI_Cobranza_Pago
				-- NO se suma a caja
				SET @MontoRestante = 0;
			END

  --      IF @MontoRestante > 0 AND ISNULL(@PermitirExcedente,0) = 1
		--BEGIN
		--	SELECT @Sec_Pago = ISNULL(MAX(Sec_Pago),0) + 1
		--	FROM dbo.FI_Cobranza_Pago
		--	WHERE NroCobranza = @NroCobranza
		--	  AND NumCuota = 0
		--	  AND Cod_Almacen = @Cod_Almacen;

		--	INSERT INTO dbo.FI_Cobranza_Pago
		--	(
		--		NroCobranza,
		--		NumCuota,
		--		Sec_Pago,
		--		Cod_Almacen,
		--		Fec_Pago,
		--		Fec_Creacion,
		--		Importe,
		--		Deuda,
		--		Saldo,
		--		Flg_Status_Pago,
		--		IdFormaPago,
		--		BancoId,
		--		CuentaBancoId,
		--		Glosa,
		--		CodUsuarioCreacion,
		--		FlgExcepcional,
		--		CodEstacion
		--	)
		--	VALUES
		--	(
		--		@NroCobranza,
		--		0,
		--		@Sec_Pago,
		--		@Cod_Almacen,
		--		@Fec_Pago,
		--		GETDATE(),
		--		@MontoRestante,
		--		0,
		--		0,
		--		'EX',
		--		@IdFormaPago,
		--		@BancoId,
		--		@CuentaBancoId,
		--		ISNULL(@Glosa,'') + ' - EXCEDENTE',
		--		@CodUsuarioCreacion,
		--		'S',
		--		@CodEstacion
		--	);

			-- OJO:
			-- NO SUMAR EL EXCEDENTE AL MONTO APLICADO TOTAL
			-- porque caja debe reflejar solo lo aplicado a la deuda

			--SET @MontoRestante = 0;
	--	END
		DECLARE @MontoCaja DECIMAL(18,2);
			SET @MontoCaja = ISNULL(@MontoAplicadoTotal, 0);
		
			IF @MontoCaja <= 0
				RAISERROR('No existe monto aplicado válido para registrar en caja.',16,1) ;

				SELECT @NumCuotaCaja = MIN(NumCuota)
					FROM @Aplicaciones;

					IF ISNULL(@NumCuotaCaja, 0) = 0
						RAISERROR('No se encontró una cuota aplicada válida para asociar el movimiento de caja.',16,1) ;

						/*Nuevo 080426 */

						SET @MontoCaja = ISNULL(@MontoAplicadoTotal, 0);
						
						IF @MontoCaja <= 0
							RAISERROR('No existe monto aplicado válido para registrar en caja.',16,1) ;

						SELECT @NumCuotaCaja = MIN(NumCuota)
						FROM @Aplicaciones;

						IF ISNULL(@NumCuotaCaja, 0) = 0
							RAISERROR('No se encontró una cuota aplicada válida para asociar el movimiento de caja.',16,1) ;

						SELECT @ListaCuotas = STUFF(
						(
							SELECT ', ' + CAST(t.NumCuota AS VARCHAR(10))
							FROM
							(
								SELECT DISTINCT NumCuota
								FROM @Aplicaciones
							) t
							ORDER BY t.NumCuota
							FOR XML PATH(''), TYPE
						).value('.', 'VARCHAR(MAX)')
						,1,2,'');

						SET @GlosaCaja =
							LEFT(
								ISNULL(@Glosa, 'PAGO PRÉSTAMO')
								+ ' | Cobranza: ' + @NroCobranza
								+ ' | Cuotas: ' + ISNULL(@ListaCuotas, ''),
								500
							);

						--	PRINT @NumCuotaCaja

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
				 @Imp_Movimiento_MonedaDocum = @MontoCaja,
				 @Imp_Movimiento = @MontoCaja,
				 @Tipo_Cambio = 1,
				 @Tipo_Cambio_Otros = 0,
				 @Cod_TipDoc = @Cod_TipDoc,
				 @Ser_docum = @Ser_docum,
				 @Num_Docum = @Num_Docum,
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
				 @Num_Cobranza = @NroCobranza,
				 @NumCuota = @NumCuotaCaja,
				 @Cod_Almacen = @Cod_Almacen;

        IF @@ERROR <> 0
            RAISERROR('ERROR SP CJ_MAN_MOVIMIENTO_DETALLE',16,1);

        SELECT @Sec_Movimiento_Generado = MAX(d.Sec_Movimiento)
        FROM dbo.CJ_Movimientos_Detalle d
        WHERE d.Cod_CajaChica = @Cod_CajaChica
          AND d.Num_Movstk = @Num_Movstk
          AND d.NroCobranza = @NroCobranza
          AND d.Cod_Almacen = @Cod_Almacen;

        IF ISNULL(@Sec_Movimiento_Generado,0) = 0
            RAISERROR('No se pudo recuperar el Sec_Movimiento generado en CJ_Movimientos_Detalle.',16,1);

        DECLARE @IdAplicacion INT = 1;
        DECLARE @MaxAplicacion INT;
        DECLARE @NumCuota_Aplic INT;
        DECLARE @ImporteAplicado_Aplic DECIMAL(18,2);

        SELECT @MaxAplicacion = MAX(Id) FROM @Aplicaciones;

        WHILE @IdAplicacion <= ISNULL(@MaxAplicacion,0)
        BEGIN
            SELECT
                @NumCuota_Aplic = NumCuota,
                @ImporteAplicado_Aplic = ImporteAplicado
            FROM @Aplicaciones
            WHERE Id = @IdAplicacion;

            IF @NumCuota_Aplic IS NOT NULL AND ISNULL(@ImporteAplicado_Aplic,0) > 0
            BEGIN
                EXEC dbo.FI_REGISTRAR_PAGO_COBRANZA_APLICACION
                     @Cod_CajaChica      = @Cod_CajaChica,
                     @Num_Movstk         = @Num_Movstk,
                     @Sec_Movimiento     = @Sec_Movimiento_Generado,
                     @NroCobranza        = @NroCobranza,
                     @NumCuota           = @NumCuota_Aplic,
                     @Cod_Almacen        = @Cod_Almacen,
                     @ImporteAplicado    = @ImporteAplicado_Aplic,
                     @Glosa              = @Glosa,
                     @CodUsuarioCreacion = @CodUsuarioCreacion;
            END

            SET @IdAplicacion = @IdAplicacion + 1;
        END

        COMMIT;

        SET @Ok = 1;
        --SET @Mensaje = 'Pago registrado correctamente.' +'N° Movim:' +CONVERT(VARCHAR(100),@Sec_Movimiento_Generado) ;

		SET @Mensaje =
    'Pago registrado correctamente. N° Movim: '
    + CONVERT(VARCHAR(100), @Sec_Movimiento_Generado)
    + CASE
        WHEN ISNULL(@MontoExcedente,0) > 0
            THEN ' | Excedente no registrado: S/ ' + CONVERT(VARCHAR(350), @MontoExcedente)
        ELSE ''
      END;

    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local','cur_cuotas') >= -1
        BEGIN
            CLOSE cur_cuotas;
            DEALLOCATE cur_cuotas;
        END

        IF @@TRANCOUNT > 0
            ROLLBACK;

        SET @Ok = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

