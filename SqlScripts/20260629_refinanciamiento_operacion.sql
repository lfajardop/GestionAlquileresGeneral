/* =============================================================
   REFINANCIACION - SELECCION, CALCULO Y APLICACION
   SQL Server 2014 compatible. IDs se reciben CSV y se validan.
============================================================= */
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('prest.p_refinanciamiento_prestamos_cliente','P') IS NOT NULL DROP PROCEDURE prest.p_refinanciamiento_prestamos_cliente;
GO
CREATE PROCEDURE prest.p_refinanciamiento_prestamos_cliente
 @id_empresa INT,@id_est CHAR(2)=NULL,@Cod_TipAnex CHAR(1),@Cod_Anxo CHAR(6),@FechaCorte DATE
AS
BEGIN
 SET NOCOUNT ON;
 SELECT p.Id_Prestamo,p.Fecha,p.Capital,p.TotalCobrar,p.PorcInteresMensual,p.FrecuenciaPago,p.FechaFinCobro,
        ISNULL(cp.Nombre,'') Concepto,
        CAST(SUM(CASE WHEN ISNULL(fc.ImporteBase,0)-CASE WHEN ISNULL(fc.ImpCancelado,0)>ISNULL(fc.ImporteInteres,0) THEN ISNULL(fc.ImpCancelado,0)-ISNULL(fc.ImporteInteres,0) ELSE 0 END>0
             THEN ISNULL(fc.ImporteBase,0)-CASE WHEN ISNULL(fc.ImpCancelado,0)>ISNULL(fc.ImporteInteres,0) THEN ISNULL(fc.ImpCancelado,0)-ISNULL(fc.ImporteInteres,0) ELSE 0 END ELSE 0 END) AS DECIMAL(18,2)) CapitalPendiente,
        CAST(SUM(CASE WHEN fc.Fec_vencDocum<=@FechaCorte THEN CASE WHEN ISNULL(fc.ImporteInteres,0)-ISNULL(fc.ImpCancelado,0)>0 THEN ISNULL(fc.ImporteInteres,0)-ISNULL(fc.ImpCancelado,0) ELSE 0 END ELSE 0 END) AS DECIMAL(18,2)) InteresVencido,
        CAST(SUM(CASE WHEN fc.Fec_vencDocum>@FechaCorte THEN CASE WHEN ISNULL(fc.ImporteInteres,0)-ISNULL(fc.ImpCancelado,0)>0 THEN ISNULL(fc.ImporteInteres,0)-ISNULL(fc.ImpCancelado,0) ELSE 0 END ELSE 0 END) AS DECIMAL(18,2)) InteresFuturoExcluido,
        CAST(SUM(CASE WHEN ISNULL(fc.ImpCuota,0)-ISNULL(fc.ImpCancelado,0)>0 THEN ISNULL(fc.ImpCuota,0)-ISNULL(fc.ImpCancelado,0) ELSE 0 END) AS DECIMAL(18,2)) SaldoProgramado,
        CAST(SUM(ISNULL(fc.ImpCancelado,0)) AS DECIMAL(18,2)) TotalPagado,
        SUM(CASE WHEN fc.Fec_vencDocum<@FechaCorte AND ISNULL(fc.ImpCuota,0)>ISNULL(fc.ImpCancelado,0) THEN 1 ELSE 0 END) CuotasVencidas
 FROM prest.prestamo p
 JOIN prest.cuota c ON c.Id_Prestamo=p.Id_Prestamo
 JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen
 LEFT JOIN prest.concepto cp ON cp.Cod_Concepto=p.Cod_Concepto
 WHERE p.id_empresa=@id_empresa AND (@id_est IS NULL OR p.Alcance='E' OR p.id_est_origen=@id_est
       OR EXISTS(SELECT 1 FROM prest.prestamo_establecimiento_acceso a WHERE a.Id_Prestamo=p.Id_Prestamo AND a.id_empresa=@id_empresa AND a.id_est=@id_est AND a.Flg_Activo='S'))
   AND p.Cod_TipAnex=@Cod_TipAnex AND p.Cod_Anxo=@Cod_Anxo
   AND ISNULL(p.Flg_Estado,'A') NOT IN('X','R')
 GROUP BY p.Id_Prestamo,p.Fecha,p.Capital,p.TotalCobrar,p.PorcInteresMensual,p.FrecuenciaPago,p.FechaFinCobro,cp.Nombre
 HAVING SUM(CASE WHEN ISNULL(fc.ImpCuota,0)>ISNULL(fc.ImpCancelado,0) THEN ISNULL(fc.ImpCuota,0)-ISNULL(fc.ImpCancelado,0) ELSE 0 END)>0
 ORDER BY p.Fecha,p.Id_Prestamo;
END
GO

IF OBJECT_ID('prest.p_refinanciamiento_calcular','P') IS NOT NULL DROP PROCEDURE prest.p_refinanciamiento_calcular;
GO
CREATE PROCEDURE prest.p_refinanciamiento_calcular
 @id_empresa INT,@id_est CHAR(2),@Cod_TipAnex CHAR(1),@Cod_Anxo CHAR(6),@IdsPrestamo VARCHAR(MAX),@FechaCorte DATE,
 @Mora DECIMAL(18,2)=0,@CondonacionInteres DECIMAL(18,2)=0,@CondonacionMora DECIMAL(18,2)=0,@PagoInicial DECIMAL(18,2)=0
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Ids TABLE(Id INT PRIMARY KEY);
 DECLARE @xml XML;
 BEGIN TRY SET @xml=CAST('<i>'+REPLACE(REPLACE(@IdsPrestamo,' ',''),',','</i><i>')+'</i>' AS XML); END TRY BEGIN CATCH SELECT CAST(0 AS BIT) Ok,'Lista de prestamos invalida.' Mensaje; RETURN; END CATCH;
 INSERT @Ids SELECT DISTINCT T.N.value('.','INT') FROM @xml.nodes('/i') T(N) WHERE T.N.value('.','INT')>0;
 IF NOT EXISTS(SELECT 1 FROM @Ids) BEGIN SELECT CAST(0 AS BIT) Ok,'Seleccione al menos un prestamo.' Mensaje; RETURN; END;
 IF EXISTS(SELECT 1 FROM @Ids i LEFT JOIN prest.prestamo p ON p.Id_Prestamo=i.Id AND p.id_empresa=@id_empresa AND p.Cod_TipAnex=@Cod_TipAnex AND p.Cod_Anxo=@Cod_Anxo AND ISNULL(p.Flg_Estado,'A') NOT IN('X','R') WHERE p.Id_Prestamo IS NULL)
 BEGIN SELECT CAST(0 AS BIT) Ok,'Hay prestamos invalidos, de otro cliente o ya refinanciados.' Mensaje; RETURN; END;

 DECLARE @D TABLE(Id_Prestamo INT,CapitalPendiente DECIMAL(18,2),InteresVencido DECIMAL(18,2),InteresFuturo DECIMAL(18,2),SaldoProgramado DECIMAL(18,2),TotalPagado DECIMAL(18,2));
 INSERT @D
 SELECT p.Id_Prestamo,
  SUM(CASE WHEN ISNULL(fc.ImporteBase,0)-CASE WHEN ISNULL(fc.ImpCancelado,0)>ISNULL(fc.ImporteInteres,0) THEN ISNULL(fc.ImpCancelado,0)-ISNULL(fc.ImporteInteres,0) ELSE 0 END>0 THEN ISNULL(fc.ImporteBase,0)-CASE WHEN ISNULL(fc.ImpCancelado,0)>ISNULL(fc.ImporteInteres,0) THEN ISNULL(fc.ImpCancelado,0)-ISNULL(fc.ImporteInteres,0) ELSE 0 END ELSE 0 END),
  SUM(CASE WHEN fc.Fec_vencDocum<=@FechaCorte AND ISNULL(fc.ImporteInteres,0)>ISNULL(fc.ImpCancelado,0) THEN ISNULL(fc.ImporteInteres,0)-ISNULL(fc.ImpCancelado,0) ELSE 0 END),
  SUM(CASE WHEN fc.Fec_vencDocum>@FechaCorte AND ISNULL(fc.ImporteInteres,0)>ISNULL(fc.ImpCancelado,0) THEN ISNULL(fc.ImporteInteres,0)-ISNULL(fc.ImpCancelado,0) ELSE 0 END),
  SUM(CASE WHEN ISNULL(fc.ImpCuota,0)>ISNULL(fc.ImpCancelado,0) THEN ISNULL(fc.ImpCuota,0)-ISNULL(fc.ImpCancelado,0) ELSE 0 END),SUM(ISNULL(fc.ImpCancelado,0))
 FROM @Ids i JOIN prest.prestamo p ON p.Id_Prestamo=i.Id JOIN prest.cuota c ON c.Id_Prestamo=p.Id_Prestamo
 JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen GROUP BY p.Id_Prestamo;
 DECLARE @Capital DECIMAL(18,2),@Interes DECIMAL(18,2),@Futuro DECIMAL(18,2),@Base DECIMAL(18,2);
 SELECT @Capital=SUM(CapitalPendiente),@Interes=SUM(InteresVencido),@Futuro=SUM(InteresFuturo),@Base=SUM(CapitalPendiente)+SUM(InteresVencido)+@Mora-@CondonacionInteres-@CondonacionMora-@PagoInicial FROM @D;
 IF @CondonacionInteres>@Interes OR @CondonacionMora>@Mora OR @Base<=0 BEGIN SELECT CAST(0 AS BIT) Ok,'Condonaciones, mora o pago inicial generan un importe invalido.' Mensaje; RETURN; END;
 SELECT CAST(1 AS BIT) Ok,'Calculo consolidado correcto.' Mensaje,COUNT(*) CantPrestamos,@Capital CapitalPendiente,@Interes InteresVencido,@Futuro InteresFuturoExcluido,@Mora Mora,@CondonacionInteres CondonacionInteres,@CondonacionMora CondonacionMora,@PagoInicial PagoInicial,@Base CapitalRefinanciado FROM @D;
 SELECT d.Id_Prestamo,p.Fecha,d.CapitalPendiente,d.InteresVencido,d.InteresFuturo InteresFuturoExcluido,d.SaldoProgramado,d.TotalPagado FROM @D d JOIN prest.prestamo p ON p.Id_Prestamo=d.Id_Prestamo ORDER BY p.Fecha,p.Id_Prestamo;
END
GO

IF OBJECT_ID('prest.p_refinanciamiento_aplicar','P') IS NOT NULL DROP PROCEDURE prest.p_refinanciamiento_aplicar;
GO
CREATE PROCEDURE prest.p_refinanciamiento_aplicar
 @id_empresa INT,@id_est CHAR(2),@Alcance VARCHAR(1),@Cod_TipAnex CHAR(1),@Cod_Anxo CHAR(6),@IdsPrestamo VARCHAR(MAX),@FechaCorte DATE,
 @Cod_Motivo VARCHAR(3),@Mora DECIMAL(18,2),@CondonacionInteres DECIMAL(18,2),@CondonacionMora DECIMAL(18,2),@PagoInicial DECIMAL(18,2),
 @PorcInteresMensual DECIMAL(18,4),@FrecuenciaPago CHAR(1),@TipoModalidad CHAR(1),@FechaInicio DATE,@FechaFin DATE,
 @Cod_Gracia VARCHAR(1),@MesesGracia INT,@TasaReferencia DECIMAL(18,4)=NULL,@JustificacionTasa VARCHAR(250)=NULL,@Observacion VARCHAR(500)=NULL,@CodUsuario INT,
 @Ok BIT OUTPUT,@Mensaje VARCHAR(500) OUTPUT,@IdRefinanciamiento INT OUTPUT,@IdPrestamoNuevo INT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;SET @Ok=0;SET @IdRefinanciamiento=NULL;SET @IdPrestamoNuevo=NULL;
 IF @Cod_Gracia<>'N' BEGIN SET @Mensaje='El cronograma con periodo de gracia estara disponible en el siguiente tramo. Use Sin gracia.';RETURN;END;
 IF @PorcInteresMensual<=0 OR @FrecuenciaPago NOT IN('D','S','M') OR @TipoModalidad NOT IN('C','I','F') OR @FechaFin<@FechaInicio BEGIN SET @Mensaje='Revise interes, frecuencia, modalidad y fechas.';RETURN;END;
 IF @Alcance NOT IN('E','S','M') OR NOT EXISTS(SELECT 1 FROM prest.operacion_motivo WHERE Cod_Motivo=@Cod_Motivo AND Flg_Activo='S') OR NOT EXISTS(SELECT 1 FROM prest.gracia_tipo WHERE Cod_Gracia=@Cod_Gracia AND Flg_Activo='S') BEGIN SET @Mensaje='Catalogos invalidos.';RETURN;END;
 IF @PagoInicial<>0 BEGIN SET @Mensaje='Registre primero el pago inicial mediante Pago Global y vuelva a calcular.';RETURN;END;
 IF @TasaReferencia IS NOT NULL AND @PorcInteresMensual>@TasaReferencia AND ISNULL(LTRIM(RTRIM(@JustificacionTasa)),'')='' BEGIN SET @Mensaje='La tasa supera la referencia; ingrese justificacion.';RETURN;END;
 DECLARE @Ids TABLE(Id INT PRIMARY KEY);DECLARE @xml XML;
 BEGIN TRY SET @xml=CAST('<i>'+REPLACE(REPLACE(@IdsPrestamo,' ',''),',','</i><i>')+'</i>' AS XML);INSERT @Ids SELECT DISTINCT T.N.value('.','INT') FROM @xml.nodes('/i') T(N); END TRY BEGIN CATCH SET @Mensaje='Lista de prestamos invalida.';RETURN;END CATCH;
 IF NOT EXISTS(SELECT 1 FROM @Ids) BEGIN SET @Mensaje='Seleccione prestamos.';RETURN;END;
 IF EXISTS(SELECT 1 FROM @Ids i LEFT JOIN prest.prestamo p ON p.Id_Prestamo=i.Id AND p.id_empresa=@id_empresa AND p.Cod_TipAnex=@Cod_TipAnex AND p.Cod_Anxo=@Cod_Anxo AND ISNULL(p.Flg_Estado,'A') NOT IN('X','R') WHERE p.Id_Prestamo IS NULL) BEGIN SET @Mensaje='Prestamos invalidos o ya refinanciados.';RETURN;END;
 DECLARE @D TABLE(Id INT,Capital DECIMAL(18,2),Interes DECIMAL(18,2),Futuro DECIMAL(18,2),Saldo DECIMAL(18,2),Pagado DECIMAL(18,2));
 INSERT @D SELECT p.Id_Prestamo,
 SUM(CASE WHEN ISNULL(fc.ImporteBase,0)-CASE WHEN ISNULL(fc.ImpCancelado,0)>ISNULL(fc.ImporteInteres,0) THEN ISNULL(fc.ImpCancelado,0)-ISNULL(fc.ImporteInteres,0) ELSE 0 END>0 THEN ISNULL(fc.ImporteBase,0)-CASE WHEN ISNULL(fc.ImpCancelado,0)>ISNULL(fc.ImporteInteres,0) THEN ISNULL(fc.ImpCancelado,0)-ISNULL(fc.ImporteInteres,0) ELSE 0 END ELSE 0 END),
 SUM(CASE WHEN fc.Fec_vencDocum<=@FechaCorte AND ISNULL(fc.ImporteInteres,0)>ISNULL(fc.ImpCancelado,0) THEN ISNULL(fc.ImporteInteres,0)-ISNULL(fc.ImpCancelado,0) ELSE 0 END),
 SUM(CASE WHEN fc.Fec_vencDocum>@FechaCorte AND ISNULL(fc.ImporteInteres,0)>ISNULL(fc.ImpCancelado,0) THEN ISNULL(fc.ImporteInteres,0)-ISNULL(fc.ImpCancelado,0) ELSE 0 END),
 SUM(CASE WHEN ISNULL(fc.ImpCuota,0)>ISNULL(fc.ImpCancelado,0) THEN ISNULL(fc.ImpCuota,0)-ISNULL(fc.ImpCancelado,0) ELSE 0 END),SUM(ISNULL(fc.ImpCancelado,0))
 FROM @Ids i JOIN prest.prestamo p ON p.Id_Prestamo=i.Id JOIN prest.cuota c ON c.Id_Prestamo=p.Id_Prestamo JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen GROUP BY p.Id_Prestamo;
 DECLARE @Capital DECIMAL(18,2),@Interes DECIMAL(18,2),@Futuro DECIMAL(18,2),@NuevoCapital DECIMAL(18,2),@InteresNuevo DECIMAL(18,2),@TotalNuevo DECIMAL(18,2),@Cuotas INT;
 SELECT @Capital=SUM(Capital),@Interes=SUM(Interes),@Futuro=SUM(Futuro),@NuevoCapital=SUM(Capital)+SUM(Interes)+@Mora-@CondonacionInteres-@CondonacionMora FROM @D;
 IF @CondonacionInteres>@Interes OR @CondonacionMora>@Mora OR @NuevoCapital<=0 BEGIN SET @Mensaje='Importe refinanciado invalido.';RETURN;END;
 DECLARE @Sim TABLE(Ok BIT,NroCuotas INT,NroCuotasCompletas INT,DiasProrrateados INT,InteresMensual DECIMAL(18,2),InteresDiario DECIMAL(18,2),InteresTotal DECIMAL(18,2),TotalCobrar DECIMAL(18,2),ImporteCuota DECIMAL(18,2),ImporteCuotaInteres DECIMAL(18,2),ImporteUltimaCuota DECIMAL(18,2),TeaReferencial DECIMAL(18,4),Mensaje VARCHAR(500));
 BEGIN TRY INSERT @Sim EXEC prest.p_prestamo_simular @Capital=@NuevoCapital,@TipoInteres='M',@TipoModalidad=@TipoModalidad,@PorcInteresMensual=@PorcInteresMensual,@FrecuenciaPago=@FrecuenciaPago,@FechaInicioCobro=@FechaInicio,@FechaFinCobro=@FechaFin; END TRY BEGIN CATCH SET @Mensaje=ERROR_MESSAGE();RETURN;END CATCH;
 SELECT @Cuotas=NroCuotas,@InteresNuevo=InteresTotal,@TotalNuevo=TotalCobrar FROM @Sim WHERE Ok=1;IF @Cuotas IS NULL BEGIN SET @Mensaje='No se genero cronograma nuevo.';RETURN;END;
 DECLARE @Out INT;
 BEGIN TRY
  BEGIN TRAN;
  EXEC prest.p_prestamo_crear_y_plan_v2 @Cod_Almacen='PR',@Cod_TipAnex=@Cod_TipAnex,@Cod_Anxo=@Cod_Anxo,@Fecha=@FechaCorte,@Capital=@NuevoCapital,@TipoInteres='M',@PorcInteresMensual=@PorcInteresMensual,@FrecuenciaPago=@FrecuenciaPago,@FechaInicioCobro=@FechaInicio,@FechaFinCobro=@FechaFin,@TipoModalidad=@TipoModalidad,@Observacion='PRESTAMO GENERADO POR REFINANCIACION',@Usu=@CodUsuario,@Cod_Concepto='010',@Id_PrestamoOut=@Out OUTPUT;
  SET @IdPrestamoNuevo=@Out;IF @IdPrestamoNuevo IS NULL RAISERROR('No se pudo crear el nuevo prestamo.',16,1);
  UPDATE prest.prestamo SET id_empresa=@id_empresa,id_est_origen=@id_est,Alcance=@Alcance,Flg_Reprogramado='S',Tipo_Reprogramacion='F' WHERE Id_Prestamo=@IdPrestamoNuevo;
  -- La fuente final es el cronograma realmente creado, no el simulador agregado heredado.
  SELECT @Cuotas=Nro_Cuotas,@InteresNuevo=InteresTotal,@TotalNuevo=TotalCobrar
  FROM prest.prestamo WHERE Id_Prestamo=@IdPrestamoNuevo;
  INSERT prest.refinanciamiento(id_empresa,id_est_origen,Alcance,Cod_TipAnex,Cod_Anxo,Cod_Tipo,Cod_Motivo,FechaCorte,CapitalPendiente,InteresVencido,Mora,CondonacionInteres,CondonacionMora,PagoInicial,CapitalRefinanciado,PorcInteresMensual,FrecuenciaPago,TipoModalidad,FechaInicio,FechaFin,Cod_Gracia,MesesGracia,InteresNuevo,TotalNuevo,NroCuotas,TasaReferencia,SuperaTasaReferencia,JustificacionTasa,Cod_Estado,Id_Prestamo_Nuevo,Observacion,Usu_Creacion)
  VALUES(@id_empresa,@id_est,@Alcance,@Cod_TipAnex,@Cod_Anxo,'F',@Cod_Motivo,@FechaCorte,@Capital,@Interes,@Mora,@CondonacionInteres,@CondonacionMora,0,@NuevoCapital,@PorcInteresMensual,@FrecuenciaPago,@TipoModalidad,@FechaInicio,@FechaFin,@Cod_Gracia,@MesesGracia,@InteresNuevo,@TotalNuevo,@Cuotas,@TasaReferencia,CASE WHEN @TasaReferencia IS NOT NULL AND @PorcInteresMensual>@TasaReferencia THEN 'S' ELSE 'N' END,@JustificacionTasa,'A',@IdPrestamoNuevo,@Observacion,@CodUsuario);
  SET @IdRefinanciamiento=SCOPE_IDENTITY();
  INSERT prest.refinanciamiento_detalle SELECT @IdRefinanciamiento,Id,Capital,Interes,Futuro,Saldo,Pagado FROM @D;
  UPDATE p SET p.Flg_Estado='R',p.Flg_Reprogramado='S',p.Tipo_Reprogramacion='F',p.Fec_Modif=GETDATE(),p.Usu_Modif=@CodUsuario FROM prest.prestamo p JOIN @Ids i ON i.Id=p.Id_Prestamo;
  UPDATE fc SET fc.FlgStatusPago='R' FROM dbo.FI_Cobranza_Cuota fc JOIN prest.cuota c ON c.NroCobranza=fc.NroCobranza AND c.Num_Secuencia=fc.NumCuota JOIN @Ids i ON i.Id=c.Id_Prestamo WHERE ISNULL(fc.FlgStatusPago,'P')<>'C';
  COMMIT;SET @Ok=1;SET @Mensaje='Refinanciacion aplicada correctamente.';
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;SET @Mensaje=ERROR_MESSAGE();SET @Ok=0;END CATCH;
END
GO

IF OBJECT_ID('prest.p_refinanciamiento_listar','P') IS NOT NULL DROP PROCEDURE prest.p_refinanciamiento_listar;
GO
CREATE PROCEDURE prest.p_refinanciamiento_listar @id_empresa INT,@id_est CHAR(2)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SELECT r.Id_Refinanciamiento,r.FechaCorte,r.Cod_TipAnex,r.Cod_Anxo,
        LTRIM(RTRIM(ISNULL(a.Des_Anexo,''))) Cliente,r.CapitalPendiente,r.InteresVencido,r.Mora,
        r.CondonacionInteres,r.CondonacionMora,r.CapitalRefinanciado,r.PorcInteresMensual,
        r.FrecuenciaPago,r.FechaInicio,r.FechaFin,r.InteresNuevo,r.TotalNuevo,r.NroCuotas,
        r.Id_Prestamo_Nuevo,r.Cod_Estado,oe.Nombre Estado,r.Fec_Creacion,
        (SELECT COUNT(*) FROM prest.refinanciamiento_detalle d WHERE d.Id_Refinanciamiento=r.Id_Refinanciamiento) CantPrestamos
 FROM prest.refinanciamiento r
 LEFT JOIN dbo.CN_AnexosContables a ON a.Cod_TipAnex=r.Cod_TipAnex AND a.Cod_Anxo=r.Cod_Anxo
 LEFT JOIN prest.operacion_estado oe ON oe.Cod_Estado=r.Cod_Estado
 WHERE r.id_empresa=@id_empresa AND (@id_est IS NULL OR r.Alcance='E' OR r.id_est_origen=@id_est)
 ORDER BY r.Id_Refinanciamiento DESC;
END
GO

IF OBJECT_ID('prest.p_refinanciamiento_obtener','P') IS NOT NULL DROP PROCEDURE prest.p_refinanciamiento_obtener;
GO
CREATE PROCEDURE prest.p_refinanciamiento_obtener @id_empresa INT,@id_est CHAR(2),@IdRefinanciamiento INT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT r.*,LTRIM(RTRIM(ISNULL(a.Des_Anexo,''))) Cliente,ISNULL(a.Num_Ruc,'') Documento,
        ISNULL(oe.Nombre,'') Estado,ISNULL(m.Nombre,'') Motivo,ISNULL(cp.ContenidoHtml,'') ContenidoPlantilla,
        ISNULL(cp.TextoMarcaAgua,'REFINANCIADO') TextoMarcaAgua
 FROM prest.refinanciamiento r
 LEFT JOIN dbo.CN_AnexosContables a ON a.Cod_TipAnex=r.Cod_TipAnex AND a.Cod_Anxo=r.Cod_Anxo
 LEFT JOIN prest.operacion_estado oe ON oe.Cod_Estado=r.Cod_Estado
 LEFT JOIN prest.operacion_motivo m ON m.Cod_Motivo=r.Cod_Motivo
 OUTER APPLY(SELECT TOP 1 p.ContenidoHtml,p.TextoMarcaAgua FROM prest.contrato_plantilla p WHERE p.id_empresa=r.id_empresa AND p.Cod_Tipo='F' AND p.Flg_Activo='S' AND (p.id_est IS NULL OR p.id_est=r.id_est_origen) ORDER BY CASE WHEN p.id_est=r.id_est_origen THEN 0 ELSE 1 END,p.Version DESC) cp
 WHERE r.Id_Refinanciamiento=@IdRefinanciamiento AND r.id_empresa=@id_empresa AND (r.Alcance='E' OR r.id_est_origen=@id_est);
 SELECT d.Id_Prestamo_Origen Id_Prestamo,d.CapitalPendiente,d.InteresVencido,d.InteresFuturoExcluido,d.SaldoProgramado,d.TotalPagado
 FROM prest.refinanciamiento_detalle d JOIN prest.refinanciamiento r ON r.Id_Refinanciamiento=d.Id_Refinanciamiento
 WHERE d.Id_Refinanciamiento=@IdRefinanciamiento AND r.id_empresa=@id_empresa ORDER BY d.Id_Prestamo_Origen;
 SELECT c.Num_Secuencia,fc.Fec_vencDocum,fc.ImporteBase,fc.ImporteInteres,fc.ImpCuota
 FROM prest.refinanciamiento r JOIN prest.prestamo p ON p.Id_Prestamo=r.Id_Prestamo_Nuevo
 JOIN prest.cuota c ON c.Id_Prestamo=p.Id_Prestamo
 JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen
 WHERE r.Id_Refinanciamiento=@IdRefinanciamiento AND r.id_empresa=@id_empresa ORDER BY c.Num_Secuencia;
END
GO

/* Ajusta SP existentes para que R (refinanciado) no vuelva a sumar deuda activa. */
DECLARE @Nombre VARCHAR(200),@Def NVARCHAR(MAX);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT name FROM sys.procedures WHERE schema_id=SCHEMA_ID('prest') AND name IN('p_ctacte_cliente_resumen','p_ctacte_cliente_detalle','p_ctacte_cliente_cuotas');
OPEN c;FETCH NEXT FROM c INTO @Nombre;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Def=OBJECT_DEFINITION(OBJECT_ID('prest.'+@Nombre));
 SET @Def=REPLACE(@Def,'CREATE PROCEDURE','ALTER PROCEDURE');SET @Def=REPLACE(@Def,'CREATE PROC','ALTER PROC');
 SET @Def=REPLACE(@Def,N'ISNULL(p.Flg_Estado,''A'') <> ''X''',N'ISNULL(p.Flg_Estado,''A'') NOT IN (''X'',''R'')');
 SET @Def=REPLACE(@Def,N'ISNULL(p.Flg_Estado, ''A'') <> ''X''',N'ISNULL(p.Flg_Estado, ''A'') NOT IN (''X'',''R'')');
 EXEC sp_executesql @Def;FETCH NEXT FROM c INTO @Nombre;
END
CLOSE c;DEALLOCATE c;
GO
