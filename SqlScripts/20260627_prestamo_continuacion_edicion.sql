/* =====================================================
   EDICION CONTROLADA DE CONTINUACIONES
   Reglas:
   - Solo se edita la ultima continuacion activa.
   - No se edita si alguna cuota del rango tiene pagos.
   - Conserva el inicio original y reemplaza solo sus cuotas.
===================================================== */
SET XACT_ABORT ON;
GO

IF COL_LENGTH('prest.prestamo_continuacion', 'NumSecuenciaDesde') IS NULL
    ALTER TABLE prest.prestamo_continuacion ADD NumSecuenciaDesde INT NULL;
IF COL_LENGTH('prest.prestamo_continuacion', 'NumSecuenciaHasta') IS NULL
    ALTER TABLE prest.prestamo_continuacion ADD NumSecuenciaHasta INT NULL;
IF COL_LENGTH('prest.prestamo_continuacion', 'Usu_Modif') IS NULL
    ALTER TABLE prest.prestamo_continuacion ADD Usu_Modif INT NULL;
IF COL_LENGTH('prest.prestamo_continuacion', 'Fec_Modif') IS NULL
    ALTER TABLE prest.prestamo_continuacion ADD Fec_Modif DATETIME NULL;
GO

/* Backfill: las continuaciones se agregaron siempre al final del cronograma. */
UPDATE pc
SET NumSecuenciaHasta = x.MaxSecuencia
    - ISNULL((SELECT SUM(pc2.NroCuotasGeneradas)
              FROM prest.prestamo_continuacion pc2
              WHERE pc2.Id_Prestamo = pc.Id_Prestamo
                AND pc2.Id_Continuacion > pc.Id_Continuacion
                AND pc2.Flg_Estado = 'A'), 0),
    NumSecuenciaDesde = x.MaxSecuencia
    - ISNULL((SELECT SUM(pc2.NroCuotasGeneradas)
              FROM prest.prestamo_continuacion pc2
              WHERE pc2.Id_Prestamo = pc.Id_Prestamo
                AND pc2.Id_Continuacion > pc.Id_Continuacion
                AND pc2.Flg_Estado = 'A'), 0)
    - pc.NroCuotasGeneradas + 1
FROM prest.prestamo_continuacion pc
CROSS APPLY
(
    SELECT MAX(c.Num_Secuencia) MaxSecuencia
    FROM prest.cuota c
    WHERE c.Id_Prestamo = pc.Id_Prestamo
) x
WHERE pc.Flg_Estado = 'A'
  AND (pc.NumSecuenciaDesde IS NULL OR pc.NumSecuenciaHasta IS NULL);
GO

IF OBJECT_ID('prest.fn_continuacion_cronograma') IS NOT NULL
    DROP FUNCTION prest.fn_continuacion_cronograma;
GO
CREATE FUNCTION prest.fn_continuacion_cronograma
(
    @FechaDesde DATE,
    @FechaHasta DATE,
    @Frecuencia CHAR(1),
    @Capital DECIMAL(18,2),
    @Tasa DECIMAL(18,4)
)
RETURNS @Cronograma TABLE
(
    Num_Secuencia INT IDENTITY(1,1),
    Fecha_Desde DATE,
    Fecha_Hasta DATE,
    Fec_Venc DATE,
    Imp_Base DECIMAL(18,2),
    Imp_Interes DECIMAL(18,2),
    Imp_Cuota DECIMAL(18,2)
)
AS
BEGIN
    DECLARE @Desde DATE = @FechaDesde, @Siguiente DATE, @HastaTramo DATE;
    WHILE @Desde <= @FechaHasta
    BEGIN
        SET @Siguiente = CASE @Frecuencia WHEN 'D' THEN DATEADD(DAY,1,@Desde) WHEN 'S' THEN DATEADD(DAY,7,@Desde) ELSE DATEADD(MONTH,1,@Desde) END;
        SET @HastaTramo = CASE WHEN @Siguiente <= @FechaHasta THEN DATEADD(DAY,-1,@Siguiente) ELSE @FechaHasta END;
        INSERT INTO @Cronograma (Fecha_Desde,Fecha_Hasta,Fec_Venc,Imp_Base,Imp_Interes,Imp_Cuota)
        VALUES (@Desde,@HastaTramo,@HastaTramo,0,0,0);
        SET @Desde = @Siguiente;
    END

    DECLARE @N INT=1,@Max INT,@RangoDesde DATE,@RangoHasta DATE,@Cursor DATE,@InicioCiclo DATE,@FinCiclo DATE,
            @Corte DATE,@DiasCiclo INT,@DiasTramo INT,@InteresMes DECIMAL(18,10),@InteresDia DECIMAL(18,10),@Interes DECIMAL(18,10);
    SELECT @Max=COUNT(1) FROM @Cronograma;
    SET @InteresMes=@Capital*(@Tasa/100.0);
    WHILE @N<=@Max
    BEGIN
        SELECT @RangoDesde=Fecha_Desde,@RangoHasta=Fecha_Hasta FROM @Cronograma WHERE Num_Secuencia=@N;
        SET @Cursor=@RangoDesde; SET @Interes=0;
        WHILE @Cursor<=@RangoHasta
        BEGIN
            SET @InicioCiclo=@FechaDesde;
            WHILE DATEADD(MONTH,1,@InicioCiclo)<=@Cursor SET @InicioCiclo=DATEADD(MONTH,1,@InicioCiclo);
            SET @FinCiclo=DATEADD(MONTH,1,@InicioCiclo);
            SET @DiasCiclo=DATEDIFF(DAY,@InicioCiclo,@FinCiclo);
            SET @InteresDia=CASE WHEN @DiasCiclo>0 THEN @InteresMes/@DiasCiclo ELSE 0 END;
            SET @Corte=CASE WHEN DATEADD(DAY,-1,@FinCiclo)<@RangoHasta THEN DATEADD(DAY,-1,@FinCiclo) ELSE @RangoHasta END;
            SET @DiasTramo=DATEDIFF(DAY,@Cursor,DATEADD(DAY,1,@Corte));
            SET @Interes=@Interes+(@InteresDia*@DiasTramo);
            SET @Cursor=DATEADD(DAY,1,@Corte);
        END
        UPDATE @Cronograma SET Imp_Interes=ROUND(@Interes,2),Imp_Cuota=ROUND(@Interes,2) WHERE Num_Secuencia=@N;
        SET @N=@N+1;
    END
    RETURN;
END
GO

IF OBJECT_ID('prest.p_prestamo_continuacion_vincular_ultima', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_prestamo_continuacion_vincular_ultima;
GO
CREATE PROCEDURE prest.p_prestamo_continuacion_vincular_ultima
    @Id_Prestamo INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Id INT,@Cantidad INT,@Max INT;
    SELECT TOP(1) @Id=Id_Continuacion,@Cantidad=NroCuotasGeneradas
    FROM prest.prestamo_continuacion WHERE Id_Prestamo=@Id_Prestamo AND Flg_Estado='A' ORDER BY Id_Continuacion DESC;
    SELECT @Max=MAX(Num_Secuencia) FROM prest.cuota WHERE Id_Prestamo=@Id_Prestamo;
    UPDATE prest.prestamo_continuacion SET NumSecuenciaDesde=@Max-@Cantidad+1,NumSecuenciaHasta=@Max
    WHERE Id_Continuacion=@Id AND NumSecuenciaDesde IS NULL;
END
GO

IF OBJECT_ID('prest.p_prestamo_continuacion_listar', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_prestamo_continuacion_listar;
GO
CREATE PROCEDURE prest.p_prestamo_continuacion_listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT pc.Id_Continuacion,pc.Id_Prestamo,ISNULL(a.Des_Anexo,'') Cliente,pc.FechaDesde,pc.FechaHasta,
           pc.FrecuenciaPago,pc.PorcInteresMensual,pc.CapitalBase,pc.NroCuotasGeneradas,pc.ImporteInteresTotal,
           ISNULL(pc.Observacion,'') Observacion,pc.Flg_Estado,
           CAST(CASE WHEN pc.Flg_Estado='A'
                      AND pc.Id_Continuacion=(SELECT MAX(x.Id_Continuacion) FROM prest.prestamo_continuacion x WHERE x.Id_Prestamo=pc.Id_Prestamo AND x.Flg_Estado='A')
                      AND NOT EXISTS(SELECT 1 FROM prest.cuota c JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen
                                     WHERE c.Id_Prestamo=pc.Id_Prestamo AND c.Num_Secuencia BETWEEN pc.NumSecuenciaDesde AND pc.NumSecuenciaHasta AND ISNULL(fc.ImpCancelado,0)>0)
                     THEN 1 ELSE 0 END AS BIT) PuedeEditar,
           CASE WHEN pc.Flg_Estado<>'A' THEN 'Continuacion inactiva.'
                WHEN pc.Id_Continuacion<>(SELECT MAX(x.Id_Continuacion) FROM prest.prestamo_continuacion x WHERE x.Id_Prestamo=pc.Id_Prestamo AND x.Flg_Estado='A') THEN 'Existe una continuacion posterior.'
                WHEN EXISTS(SELECT 1 FROM prest.cuota c JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen
                            WHERE c.Id_Prestamo=pc.Id_Prestamo AND c.Num_Secuencia BETWEEN pc.NumSecuenciaDesde AND pc.NumSecuenciaHasta AND ISNULL(fc.ImpCancelado,0)>0) THEN 'Tiene pagos aplicados.' ELSE '' END MotivoBloqueo
    FROM prest.prestamo_continuacion pc
    JOIN prest.prestamo p ON p.Id_Prestamo=pc.Id_Prestamo
    LEFT JOIN dbo.CN_AnexosContables a ON a.Cod_TipAnex=p.Cod_TipAnex AND a.Cod_Anxo=p.Cod_Anxo
    ORDER BY pc.Id_Continuacion DESC;
END
GO

IF OBJECT_ID('prest.p_prestamo_continuacion_obtener', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_prestamo_continuacion_obtener;
GO
CREATE PROCEDURE prest.p_prestamo_continuacion_obtener @Id_Continuacion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdPrestamoVincular INT;
    SELECT @IdPrestamoVincular=Id_Prestamo FROM prest.prestamo_continuacion WHERE Id_Continuacion=@Id_Continuacion;
    EXEC prest.p_prestamo_continuacion_vincular_ultima @Id_Prestamo=@IdPrestamoVincular;
    SELECT pc.Id_Continuacion,pc.Id_Prestamo,ISNULL(a.Des_Anexo,'') Cliente,pc.FechaDesde,pc.FechaHasta,pc.FrecuenciaPago,
           pc.PorcInteresMensual,pc.CapitalBase,pc.NroCuotasGeneradas,pc.ImporteInteresTotal,ISNULL(pc.Observacion,'') Observacion,
           pc.Flg_Estado,pc.NumSecuenciaDesde,pc.NumSecuenciaHasta,
           CAST(CASE WHEN pc.Flg_Estado='A' AND pc.Id_Continuacion=(SELECT MAX(x.Id_Continuacion) FROM prest.prestamo_continuacion x WHERE x.Id_Prestamo=pc.Id_Prestamo AND x.Flg_Estado='A')
                      AND NOT EXISTS(SELECT 1 FROM prest.cuota c JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen WHERE c.Id_Prestamo=pc.Id_Prestamo AND c.Num_Secuencia BETWEEN pc.NumSecuenciaDesde AND pc.NumSecuenciaHasta AND ISNULL(fc.ImpCancelado,0)>0)
                     THEN 1 ELSE 0 END AS BIT) PuedeEditar,'' MotivoBloqueo
    FROM prest.prestamo_continuacion pc JOIN prest.prestamo p ON p.Id_Prestamo=pc.Id_Prestamo
    LEFT JOIN dbo.CN_AnexosContables a ON a.Cod_TipAnex=p.Cod_TipAnex AND a.Cod_Anxo=p.Cod_Anxo
    WHERE pc.Id_Continuacion=@Id_Continuacion;

    SELECT c.Num_Secuencia,c.Fec_Venc Fecha_Desde,c.Fec_Venc Fecha_Hasta,c.Fec_Venc,c.Imp_Base,c.Imp_Interes,c.Imp_Cuota
    FROM prest.cuota c JOIN prest.prestamo_continuacion pc ON pc.Id_Prestamo=c.Id_Prestamo AND c.Num_Secuencia BETWEEN pc.NumSecuenciaDesde AND pc.NumSecuenciaHasta
    WHERE pc.Id_Continuacion=@Id_Continuacion ORDER BY c.Num_Secuencia;
END
GO

IF OBJECT_ID('prest.p_prestamo_continuacion_editar_simular', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_prestamo_continuacion_editar_simular;
GO
CREATE PROCEDURE prest.p_prestamo_continuacion_editar_simular
    @Id_Continuacion INT,@FechaHasta DATE,@PorcInteresMensual DECIMAL(18,4),@FrecuenciaPago CHAR(1),@CapitalBase DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Desde DATE,@IdPrestamo INT,@Cliente VARCHAR(150);
    SELECT @Desde=pc.FechaDesde,@IdPrestamo=pc.Id_Prestamo,@Cliente=ISNULL(a.Des_Anexo,'')
    FROM prest.prestamo_continuacion pc JOIN prest.prestamo p ON p.Id_Prestamo=pc.Id_Prestamo
    LEFT JOIN dbo.CN_AnexosContables a ON a.Cod_TipAnex=p.Cod_TipAnex AND a.Cod_Anxo=p.Cod_Anxo WHERE pc.Id_Continuacion=@Id_Continuacion;
    IF @Desde IS NULL BEGIN SELECT CAST(0 AS BIT) Ok,'No existe la continuacion.' Mensaje; RETURN; END
    IF @FechaHasta<@Desde BEGIN SELECT CAST(0 AS BIT) Ok,'La fecha hasta no puede ser menor a la fecha inicial.' Mensaje; RETURN; END
    IF @FrecuenciaPago NOT IN('D','S','M') OR @PorcInteresMensual<=0 OR @CapitalBase<=0 BEGIN SELECT CAST(0 AS BIT) Ok,'Revise frecuencia, interes y capital base.' Mensaje; RETURN; END
    SELECT CAST(1 AS BIT) Ok,'Simulacion de correccion generada.' Mensaje,@IdPrestamo Id_Prestamo,@Cliente Cliente,'' NroCobranza,'' Cod_Almacen,
           @Desde FechaDesde,@FechaHasta FechaHasta,@CapitalBase CapitalBase,@PorcInteresMensual PorcInteresMensual,@FrecuenciaPago FrecuenciaPago,
           COUNT(1) NroCuotas,SUM(Imp_Interes) InteresTotal,SUM(Imp_Cuota) TotalGenerado
    FROM prest.fn_continuacion_cronograma(@Desde,@FechaHasta,@FrecuenciaPago,@CapitalBase,@PorcInteresMensual);
    SELECT * FROM prest.fn_continuacion_cronograma(@Desde,@FechaHasta,@FrecuenciaPago,@CapitalBase,@PorcInteresMensual) ORDER BY Num_Secuencia;
END
GO

IF OBJECT_ID('prest.p_prestamo_continuacion_editar_aplicar', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_prestamo_continuacion_editar_aplicar;
GO
CREATE PROCEDURE prest.p_prestamo_continuacion_editar_aplicar
    @Id_Continuacion INT,@FechaHasta DATE,@PorcInteresMensual DECIMAL(18,4),@FrecuenciaPago CHAR(1),@CapitalBase DECIMAL(18,2),
    @Observacion VARCHAR(250),@CodUsuario INT,@Ok BIT OUTPUT,@Mensaje VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Ok=0;
    DECLARE @IdPrestamo INT,@Desde DATE,@SecDesde INT,@SecHasta INT,@InteresAnterior DECIMAL(18,2),@InteresNuevo DECIMAL(18,2),
            @Cantidad INT,@NroCobranza CHAR(8),@Almacen CHAR(2),@Delta DECIMAL(18,2);
    SELECT @IdPrestamo=pc.Id_Prestamo,@Desde=pc.FechaDesde,@SecDesde=pc.NumSecuenciaDesde,@SecHasta=pc.NumSecuenciaHasta,@InteresAnterior=pc.ImporteInteresTotal,
           @Almacen=p.Cod_Almacen FROM prest.prestamo_continuacion pc JOIN prest.prestamo p ON p.Id_Prestamo=pc.Id_Prestamo WHERE pc.Id_Continuacion=@Id_Continuacion AND pc.Flg_Estado='A';
    IF @IdPrestamo IS NULL BEGIN SET @Mensaje='No existe la continuacion activa.'; RETURN; END
    IF EXISTS(SELECT 1 FROM prest.prestamo_continuacion WHERE Id_Prestamo=@IdPrestamo AND Flg_Estado='A' AND Id_Continuacion>@Id_Continuacion) BEGIN SET @Mensaje='Solo se puede editar la ultima continuacion.'; RETURN; END
    SELECT TOP(1) @NroCobranza=c.NroCobranza FROM prest.cuota c WHERE c.Id_Prestamo=@IdPrestamo;
    IF EXISTS(SELECT 1 FROM dbo.FI_Cobranza_Cuota WHERE NroCobranza=@NroCobranza AND Cod_Almacen=@Almacen AND NumCuota BETWEEN @SecDesde AND @SecHasta AND ISNULL(ImpCancelado,0)>0) BEGIN SET @Mensaje='No se puede editar: existen pagos aplicados.'; RETURN; END
    IF @FechaHasta<@Desde OR @FrecuenciaPago NOT IN('D','S','M') OR @PorcInteresMensual<=0 OR @CapitalBase<=0 BEGIN SET @Mensaje='Revise fecha, frecuencia, interes y capital.'; RETURN; END
    DECLARE @Nuevo TABLE(Num_Secuencia INT,Fecha_Desde DATE,Fecha_Hasta DATE,Fec_Venc DATE,Imp_Base DECIMAL(18,2),Imp_Interes DECIMAL(18,2),Imp_Cuota DECIMAL(18,2));
    INSERT @Nuevo SELECT * FROM prest.fn_continuacion_cronograma(@Desde,@FechaHasta,@FrecuenciaPago,@CapitalBase,@PorcInteresMensual);
    SELECT @Cantidad=COUNT(1),@InteresNuevo=SUM(Imp_Interes) FROM @Nuevo; SET @Delta=@InteresNuevo-@InteresAnterior;
    BEGIN TRY
      BEGIN TRAN;
      DELETE dbo.FI_Cobranza_Cuota WHERE NroCobranza=@NroCobranza AND Cod_Almacen=@Almacen AND NumCuota BETWEEN @SecDesde AND @SecHasta;
      DELETE prest.cuota WHERE Id_Prestamo=@IdPrestamo AND Num_Secuencia BETWEEN @SecDesde AND @SecHasta;
      INSERT prest.cuota(Id_Prestamo,Num_Secuencia,Fec_Venc,Imp_Base,Imp_Interes,Imp_Cuota,Estado,NroCobranza)
      SELECT @IdPrestamo,@SecDesde+Num_Secuencia-1,Fec_Venc,Imp_Base,Imp_Interes,Imp_Cuota,'P',@NroCobranza FROM @Nuevo;
      INSERT dbo.FI_Cobranza_Cuota(NroCobranza,NumCuota,Cod_Almacen,Fec_vencDocum,ImporteBase,ImporteInteres,ImpComision,ImpCuota,ImpCancelado,FecCancelado,FlgStatusPago,Fec_Creacion)
      SELECT @NroCobranza,@SecDesde+Num_Secuencia-1,@Almacen,Fec_Venc,Imp_Base,Imp_Interes,0,Imp_Cuota,0,NULL,'P',GETDATE() FROM @Nuevo;
      UPDATE prest.prestamo_continuacion SET FechaHasta=@FechaHasta,FrecuenciaPago=@FrecuenciaPago,PorcInteresMensual=@PorcInteresMensual,CapitalBase=@CapitalBase,
             NroCuotasGeneradas=@Cantidad,ImporteInteresTotal=@InteresNuevo,Observacion=@Observacion,NumSecuenciaHasta=@SecDesde+@Cantidad-1,Usu_Modif=@CodUsuario,Fec_Modif=GETDATE() WHERE Id_Continuacion=@Id_Continuacion;
      UPDATE prest.prestamo SET Nro_Cuotas=@SecDesde+@Cantidad-1,FechaFinCobro=@FechaHasta,InteresTotal=ISNULL(InteresTotal,0)+@Delta,TotalCobrar=ISNULL(TotalCobrar,0)+@Delta,Usu_Modif=@CodUsuario,Fec_Modif=GETDATE() WHERE Id_Prestamo=@IdPrestamo;
      UPDATE dbo.FI_CobranzaPedido SET NroCuotas=@SecDesde+@Cantidad-1,ImporteTotal=ISNULL(ImporteTotal,0)+@Delta,ImporteSumaCuotas=ISNULL(ImporteSumaCuotas,0)+@Delta,ImporteInteres=ISNULL(ImporteInteres,0)+@Delta
      WHERE NroCobranza=@NroCobranza AND Cod_Almacen=@Almacen AND OrigenTipo='PR' AND IdOrigen=CONVERT(VARCHAR(30),@IdPrestamo);
      COMMIT; SET @Ok=1; SET @Mensaje='Continuacion actualizada correctamente.';
    END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; SET @Mensaje=ERROR_MESSAGE(); END CATCH
END
GO
