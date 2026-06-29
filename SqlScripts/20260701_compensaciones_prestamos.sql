/* =============================================================
   COMPENSACIONES DE PRESTAMOS - MVP MULTITENANT
   Sin movimiento de caja. SQL Server 2014 compatible.
============================================================= */
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name='comp') EXEC('CREATE SCHEMA comp');
GO
IF OBJECT_ID('comp.concepto_obligacion','U') IS NULL
 CREATE TABLE comp.concepto_obligacion(Cod_Concepto VARCHAR(3) NOT NULL PRIMARY KEY,Nombre VARCHAR(100) NOT NULL,Flg_Activo VARCHAR(1) NOT NULL DEFAULT('S'),Orden INT NOT NULL DEFAULT(0));
GO
IF NOT EXISTS(SELECT 1 FROM comp.concepto_obligacion WHERE Cod_Concepto='REP') INSERT comp.concepto_obligacion VALUES('REP','Reparacion o mantenimiento asumido','S',1);
IF NOT EXISTS(SELECT 1 FROM comp.concepto_obligacion WHERE Cod_Concepto='COM') INSERT comp.concepto_obligacion VALUES('COM','Comision o servicio pendiente','S',2);
IF NOT EXISTS(SELECT 1 FROM comp.concepto_obligacion WHERE Cod_Concepto='GAS') INSERT comp.concepto_obligacion VALUES('GAS','Gasto asumido por tercero','S',3);
IF NOT EXISTS(SELECT 1 FROM comp.concepto_obligacion WHERE Cod_Concepto='ADE') INSERT comp.concepto_obligacion VALUES('ADE','Adelanto o saldo a favor','S',4);
IF NOT EXISTS(SELECT 1 FROM comp.concepto_obligacion WHERE Cod_Concepto='OTR') INSERT comp.concepto_obligacion VALUES('OTR','Otro concepto autorizado','S',99);
GO
IF OBJECT_ID('comp.obligacion','U') IS NULL
BEGIN
 CREATE TABLE comp.obligacion(
  Id_Obligacion INT IDENTITY(1,1) NOT NULL PRIMARY KEY,id_empresa INT NOT NULL,id_est CHAR(2) NOT NULL,
  Cod_TipAnex CHAR(1) NOT NULL,Cod_Anxo CHAR(6) NOT NULL,Cod_Concepto VARCHAR(3) NOT NULL,
  Fecha DATE NOT NULL,Importe DECIMAL(18,2) NOT NULL,ImporteAplicado DECIMAL(18,2) NOT NULL DEFAULT(0),
  Referencia VARCHAR(80) NULL,Observacion VARCHAR(300) NULL,Flg_Estado VARCHAR(1) NOT NULL DEFAULT('A'),
  Usu_Creacion INT NOT NULL,Fec_Creacion DATETIME NOT NULL DEFAULT(GETDATE()),Usu_Modif INT NULL,Fec_Modif DATETIME NULL,
  CONSTRAINT FK_comp_obligacion_concepto FOREIGN KEY(Cod_Concepto) REFERENCES comp.concepto_obligacion(Cod_Concepto),
  CONSTRAINT CK_comp_obligacion_importe CHECK(Importe>0 AND ImporteAplicado>=0 AND ImporteAplicado<=Importe));
 CREATE INDEX IX_comp_obligacion_persona ON comp.obligacion(id_empresa,id_est,Cod_TipAnex,Cod_Anxo,Flg_Estado);
END
GO
IF OBJECT_ID('comp.compensacion','U') IS NULL
BEGIN
 CREATE TABLE comp.compensacion(
  Id_Compensacion INT IDENTITY(1,1) NOT NULL PRIMARY KEY,Numero VARCHAR(16) NULL,id_empresa INT NOT NULL,id_est CHAR(2) NOT NULL,
  Cod_TipAnex CHAR(1) NOT NULL,Cod_Anxo CHAR(6) NOT NULL,Id_Obligacion INT NOT NULL,Fecha DATE NOT NULL,
  ImporteSolicitado DECIMAL(18,2) NOT NULL,ImporteAplicado DECIMAL(18,2) NOT NULL,Flg_SoloVencidas VARCHAR(1) NOT NULL DEFAULT('S'),
  Flg_Estado VARCHAR(1) NOT NULL DEFAULT('A'),Motivo VARCHAR(3) NOT NULL,Observacion VARCHAR(300) NULL,
  Usu_Creacion INT NOT NULL,Fec_Creacion DATETIME NOT NULL DEFAULT(GETDATE()),Usu_Reversa INT NULL,Fec_Reversa DATETIME NULL,MotivoReversa VARCHAR(250) NULL,
  CONSTRAINT FK_comp_compensacion_obligacion FOREIGN KEY(Id_Obligacion) REFERENCES comp.obligacion(Id_Obligacion));
 CREATE INDEX IX_comp_compensacion_persona ON comp.compensacion(id_empresa,id_est,Cod_TipAnex,Cod_Anxo,Fecha,Flg_Estado);
END
GO
IF OBJECT_ID('comp.compensacion_detalle','U') IS NULL
BEGIN
 CREATE TABLE comp.compensacion_detalle(
  Id_Detalle INT IDENTITY(1,1) NOT NULL PRIMARY KEY,Id_Compensacion INT NOT NULL,OrdenAplicacion INT NOT NULL,
  Id_Prestamo INT NOT NULL,NroCobranza CHAR(8) NOT NULL,NumCuota INT NOT NULL,Cod_Almacen CHAR(2) NOT NULL,Fec_Venc DATE NULL,
  SaldoAntes DECIMAL(18,2) NOT NULL,InteresAplicado DECIMAL(18,2) NOT NULL,CapitalAplicado DECIMAL(18,2) NOT NULL,
  ImporteAplicado DECIMAL(18,2) NOT NULL,SaldoDespues DECIMAL(18,2) NOT NULL,
  CONSTRAINT FK_comp_detalle_cab FOREIGN KEY(Id_Compensacion) REFERENCES comp.compensacion(Id_Compensacion));
 CREATE UNIQUE INDEX UX_comp_detalle_cuota ON comp.compensacion_detalle(Id_Compensacion,NroCobranza,NumCuota,Cod_Almacen);
END
GO
IF OBJECT_ID('comp.compensacion_historial','U') IS NULL
 CREATE TABLE comp.compensacion_historial(Id_Historial INT IDENTITY(1,1) NOT NULL PRIMARY KEY,Id_Compensacion INT NOT NULL,EstadoAnterior VARCHAR(1) NULL,EstadoNuevo VARCHAR(1) NOT NULL,Motivo VARCHAR(250) NULL,Usuario INT NOT NULL,Fecha DATETIME NOT NULL DEFAULT(GETDATE()),CONSTRAINT FK_comp_historial_cab FOREIGN KEY(Id_Compensacion) REFERENCES comp.compensacion(Id_Compensacion));
GO

IF OBJECT_ID('comp.p_catalogos','P') IS NOT NULL DROP PROCEDURE comp.p_catalogos;
GO
CREATE PROCEDURE comp.p_catalogos AS BEGIN SET NOCOUNT ON;SELECT Cod_Concepto,Nombre FROM comp.concepto_obligacion WHERE Flg_Activo='S' ORDER BY Orden,Nombre;END
GO
IF OBJECT_ID('comp.p_obligacion_crear','P') IS NOT NULL DROP PROCEDURE comp.p_obligacion_crear;
GO
CREATE PROCEDURE comp.p_obligacion_crear @id_empresa INT,@id_est CHAR(2),@Cod_TipAnex CHAR(1),@Cod_Anxo CHAR(6),@Cod_Concepto VARCHAR(3),@Fecha DATE,@Importe DECIMAL(18,2),@Referencia VARCHAR(80)=NULL,@Observacion VARCHAR(300)=NULL,@Usuario INT,@Ok BIT OUTPUT,@Mensaje VARCHAR(300) OUTPUT,@Id INT OUTPUT
AS BEGIN SET NOCOUNT ON;SET @Ok=0;SET @Id=NULL;IF @Importe<=0 BEGIN SET @Mensaje='El importe debe ser mayor a cero.';RETURN;END;IF NOT EXISTS(SELECT 1 FROM comp.concepto_obligacion WHERE Cod_Concepto=@Cod_Concepto AND Flg_Activo='S') BEGIN SET @Mensaje='Concepto de obligacion invalido.';RETURN;END;INSERT comp.obligacion(id_empresa,id_est,Cod_TipAnex,Cod_Anxo,Cod_Concepto,Fecha,Importe,Referencia,Observacion,Usu_Creacion) VALUES(@id_empresa,@id_est,@Cod_TipAnex,@Cod_Anxo,@Cod_Concepto,@Fecha,@Importe,@Referencia,@Observacion,@Usuario);SET @Id=SCOPE_IDENTITY();SET @Ok=1;SET @Mensaje='Saldo a favor registrado.';END
GO
IF OBJECT_ID('comp.p_obligacion_listar','P') IS NOT NULL DROP PROCEDURE comp.p_obligacion_listar;
GO
CREATE PROCEDURE comp.p_obligacion_listar @id_empresa INT,@id_est CHAR(2),@Cod_TipAnex CHAR(1)=NULL,@Cod_Anxo CHAR(6)=NULL
AS BEGIN SET NOCOUNT ON;SELECT o.Id_Obligacion,o.Fecha,o.Cod_TipAnex,o.Cod_Anxo,ISNULL(a.Des_Anexo,'') Persona,o.Cod_Concepto,c.Nombre Concepto,o.Importe,o.ImporteAplicado,o.Importe-o.ImporteAplicado SaldoDisponible,ISNULL(o.Referencia,'') Referencia,ISNULL(o.Observacion,'') Observacion,o.Flg_Estado FROM comp.obligacion o JOIN comp.concepto_obligacion c ON c.Cod_Concepto=o.Cod_Concepto LEFT JOIN dbo.CN_AnexosContables a ON a.Cod_TipAnex=o.Cod_TipAnex AND a.Cod_Anxo=o.Cod_Anxo WHERE o.id_empresa=@id_empresa AND o.id_est=@id_est AND (@Cod_TipAnex IS NULL OR o.Cod_TipAnex=@Cod_TipAnex) AND (@Cod_Anxo IS NULL OR o.Cod_Anxo=@Cod_Anxo) ORDER BY o.Id_Obligacion DESC;END
GO

IF OBJECT_ID('comp.p_simular','P') IS NOT NULL DROP PROCEDURE comp.p_simular;
GO
CREATE PROCEDURE comp.p_simular @id_empresa INT,@id_est CHAR(2),@Cod_TipAnex CHAR(1),@Cod_Anxo CHAR(6),@Id_Obligacion INT,@IdsPrestamo VARCHAR(MAX),@FechaCorte DATE,@Importe DECIMAL(18,2),@SoloVencidas BIT=1
AS
BEGIN
 SET NOCOUNT ON;DECLARE @SaldoObligacion DECIMAL(18,2);SELECT @SaldoObligacion=Importe-ImporteAplicado FROM comp.obligacion WHERE Id_Obligacion=@Id_Obligacion AND id_empresa=@id_empresa AND id_est=@id_est AND Cod_TipAnex=@Cod_TipAnex AND Cod_Anxo=@Cod_Anxo AND Flg_Estado='A';IF @SaldoObligacion IS NULL BEGIN SELECT CAST(0 AS BIT) Ok,'Saldo a favor no disponible.' Mensaje;RETURN;END;IF @Importe<=0 OR @Importe>@SaldoObligacion BEGIN SELECT CAST(0 AS BIT) Ok,'El importe excede el saldo a favor.' Mensaje;RETURN;END;
 DECLARE @Ids TABLE(Id INT PRIMARY KEY);DECLARE @xml XML;BEGIN TRY SET @xml=CAST('<i>'+REPLACE(REPLACE(@IdsPrestamo,' ',''),',','</i><i>')+'</i>' AS XML);INSERT @Ids SELECT DISTINCT T.N.value('.','INT') FROM @xml.nodes('/i') T(N);END TRY BEGIN CATCH SELECT CAST(0 AS BIT) Ok,'Prestamos seleccionados invalidos.' Mensaje;RETURN;END CATCH;
 DECLARE @P TABLE(Orden INT,Id_Prestamo INT,NroCobranza CHAR(8),NumCuota INT,Cod_Almacen CHAR(2),FecVenc DATE,SaldoAntes DECIMAL(18,2),InteresPendiente DECIMAL(18,2));
 INSERT @P SELECT ROW_NUMBER() OVER(ORDER BY fc.Fec_vencDocum,p.Id_Prestamo,fc.NumCuota),p.Id_Prestamo,fc.NroCobranza,fc.NumCuota,fc.Cod_Almacen,fc.Fec_vencDocum,fc.ImpCuota-fc.ImpCancelado,CASE WHEN fc.ImporteInteres>fc.ImpCancelado THEN fc.ImporteInteres-fc.ImpCancelado ELSE 0 END FROM @Ids i JOIN prest.prestamo p ON p.Id_Prestamo=i.Id AND p.id_empresa=@id_empresa AND p.Cod_TipAnex=@Cod_TipAnex AND p.Cod_Anxo=@Cod_Anxo JOIN prest.cuota c ON c.Id_Prestamo=p.Id_Prestamo JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen WHERE ISNULL(p.Flg_Estado,'A') NOT IN('X','R') AND fc.ImpCuota>fc.ImpCancelado AND (@SoloVencidas=0 OR fc.Fec_vencDocum<=@FechaCorte);
 DECLARE @R TABLE(Orden INT,Id_Prestamo INT,NroCobranza CHAR(8),NumCuota INT,Cod_Almacen CHAR(2),FecVenc DATE,SaldoAntes DECIMAL(18,2),InteresAplicado DECIMAL(18,2),CapitalAplicado DECIMAL(18,2),ImporteAplicado DECIMAL(18,2),SaldoDespues DECIMAL(18,2));DECLARE @Restante DECIMAL(18,2)=@Importe,@o INT,@pr INT,@nc CHAR(8),@cu INT,@al CHAR(2),@fv DATE,@sa DECIMAL(18,2),@ip DECIMAL(18,2),@ap DECIMAL(18,2),@ia DECIMAL(18,2);DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT Orden,Id_Prestamo,NroCobranza,NumCuota,Cod_Almacen,FecVenc,SaldoAntes,InteresPendiente FROM @P ORDER BY Orden;OPEN cur;FETCH NEXT FROM cur INTO @o,@pr,@nc,@cu,@al,@fv,@sa,@ip;WHILE @@FETCH_STATUS=0 AND @Restante>0 BEGIN SET @ap=CASE WHEN @Restante>@sa THEN @sa ELSE @Restante END;SET @ia=CASE WHEN @ap>@ip THEN @ip ELSE @ap END;INSERT @R VALUES(@o,@pr,@nc,@cu,@al,@fv,@sa,@ia,@ap-@ia,@ap,@sa-@ap);SET @Restante-=@ap;FETCH NEXT FROM cur INTO @o,@pr,@nc,@cu,@al,@fv,@sa,@ip;END CLOSE cur;DEALLOCATE cur;
 IF NOT EXISTS(SELECT 1 FROM @R) BEGIN SELECT CAST(0 AS BIT) Ok,'No hay cuotas elegibles para compensar.' Mensaje;RETURN;END;SELECT CAST(1 AS BIT) Ok,'Simulacion correcta.' Mensaje,@SaldoObligacion SaldoFavorAntes,@Importe ImporteSolicitado,@Importe-@Restante ImporteAplicado,@SaldoObligacion-(@Importe-@Restante) SaldoFavorDespues,SUM(InteresAplicado) InteresAplicado,SUM(CapitalAplicado) CapitalAplicado,COUNT(*) CuotasAfectadas FROM @R;SELECT * FROM @R ORDER BY Orden;
END
GO

IF OBJECT_ID('comp.p_aplicar','P') IS NOT NULL DROP PROCEDURE comp.p_aplicar;
GO
CREATE PROCEDURE comp.p_aplicar @id_empresa INT,@id_est CHAR(2),@Cod_TipAnex CHAR(1),@Cod_Anxo CHAR(6),@Id_Obligacion INT,@IdsPrestamo VARCHAR(MAX),@Fecha DATE,@Importe DECIMAL(18,2),@SoloVencidas BIT,@Motivo VARCHAR(3),@Observacion VARCHAR(300),@Usuario INT,@Ok BIT OUTPUT,@Mensaje VARCHAR(300) OUTPUT,@IdCompensacion INT OUTPUT
AS
BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;SET @Ok=0;SET @IdCompensacion=NULL;BEGIN TRY BEGIN TRAN;DECLARE @SaldoFavor DECIMAL(18,2);SELECT @SaldoFavor=Importe-ImporteAplicado FROM comp.obligacion WITH(UPDLOCK,HOLDLOCK) WHERE Id_Obligacion=@Id_Obligacion AND id_empresa=@id_empresa AND id_est=@id_est AND Cod_TipAnex=@Cod_TipAnex AND Cod_Anxo=@Cod_Anxo AND Flg_Estado='A';IF @SaldoFavor IS NULL OR @Importe<=0 OR @Importe>@SaldoFavor RAISERROR('Saldo a favor insuficiente o no disponible.',16,1);
 DECLARE @Ids TABLE(Id INT PRIMARY KEY);DECLARE @xml XML;SET @xml=CAST('<i>'+REPLACE(REPLACE(@IdsPrestamo,' ',''),',','</i><i>')+'</i>' AS XML);INSERT @Ids SELECT DISTINCT T.N.value('.','INT') FROM @xml.nodes('/i') T(N);DECLARE @P TABLE(Orden INT,Id_Prestamo INT,NroCobranza CHAR(8),NumCuota INT,Cod_Almacen CHAR(2),FecVenc DATE,SaldoAntes DECIMAL(18,2),InteresPendiente DECIMAL(18,2));INSERT @P SELECT ROW_NUMBER() OVER(ORDER BY fc.Fec_vencDocum,p.Id_Prestamo,fc.NumCuota),p.Id_Prestamo,fc.NroCobranza,fc.NumCuota,fc.Cod_Almacen,fc.Fec_vencDocum,fc.ImpCuota-fc.ImpCancelado,CASE WHEN fc.ImporteInteres>fc.ImpCancelado THEN fc.ImporteInteres-fc.ImpCancelado ELSE 0 END FROM @Ids i JOIN prest.prestamo p ON p.Id_Prestamo=i.Id AND p.id_empresa=@id_empresa AND p.Cod_TipAnex=@Cod_TipAnex AND p.Cod_Anxo=@Cod_Anxo JOIN prest.cuota c ON c.Id_Prestamo=p.Id_Prestamo JOIN dbo.FI_Cobranza_Cuota fc WITH(UPDLOCK,HOLDLOCK) ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen WHERE ISNULL(p.Flg_Estado,'A') NOT IN('X','R') AND fc.ImpCuota>fc.ImpCancelado AND (@SoloVencidas=0 OR fc.Fec_vencDocum<=@Fecha);
 INSERT comp.compensacion(id_empresa,id_est,Cod_TipAnex,Cod_Anxo,Id_Obligacion,Fecha,ImporteSolicitado,ImporteAplicado,Flg_SoloVencidas,Motivo,Observacion,Usu_Creacion) VALUES(@id_empresa,@id_est,@Cod_TipAnex,@Cod_Anxo,@Id_Obligacion,@Fecha,@Importe,0,CASE WHEN @SoloVencidas=1 THEN 'S' ELSE 'N' END,@Motivo,@Observacion,@Usuario);SET @IdCompensacion=SCOPE_IDENTITY();UPDATE comp.compensacion SET Numero='CMP-'+RIGHT('00000000'+CONVERT(VARCHAR(8),@IdCompensacion),8) WHERE Id_Compensacion=@IdCompensacion;
 DECLARE @Restante DECIMAL(18,2)=@Importe,@AplicadoTotal DECIMAL(18,2)=0,@o INT,@pr INT,@nc CHAR(8),@cu INT,@al CHAR(2),@fv DATE,@sa DECIMAL(18,2),@ip DECIMAL(18,2),@ap DECIMAL(18,2),@ia DECIMAL(18,2);DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT Orden,Id_Prestamo,NroCobranza,NumCuota,Cod_Almacen,FecVenc,SaldoAntes,InteresPendiente FROM @P ORDER BY Orden;OPEN cur;FETCH NEXT FROM cur INTO @o,@pr,@nc,@cu,@al,@fv,@sa,@ip;WHILE @@FETCH_STATUS=0 AND @Restante>0 BEGIN SET @ap=CASE WHEN @Restante>@sa THEN @sa ELSE @Restante END;SET @ia=CASE WHEN @ap>@ip THEN @ip ELSE @ap END;UPDATE dbo.FI_Cobranza_Cuota SET ImpCancelado=ImpCancelado+@ap,FecCancelado=CASE WHEN ImpCuota<=ImpCancelado+@ap THEN @Fecha ELSE FecCancelado END,FlgStatusPago=CASE WHEN ImpCuota<=ImpCancelado+@ap THEN 'C' ELSE 'P' END WHERE NroCobranza=@nc AND NumCuota=@cu AND Cod_Almacen=@al;INSERT comp.compensacion_detalle(Id_Compensacion,OrdenAplicacion,Id_Prestamo,NroCobranza,NumCuota,Cod_Almacen,Fec_Venc,SaldoAntes,InteresAplicado,CapitalAplicado,ImporteAplicado,SaldoDespues) VALUES(@IdCompensacion,@o,@pr,@nc,@cu,@al,@fv,@sa,@ia,@ap-@ia,@ap,@sa-@ap);SET @Restante-=@ap;SET @AplicadoTotal+=@ap;FETCH NEXT FROM cur INTO @o,@pr,@nc,@cu,@al,@fv,@sa,@ip;END CLOSE cur;DEALLOCATE cur;IF @AplicadoTotal<=0 RAISERROR('No hay deuda elegible para aplicar.',16,1);IF @Restante>0 RAISERROR('El importe supera la deuda elegible seleccionada.',16,1);UPDATE comp.compensacion SET ImporteAplicado=@AplicadoTotal WHERE Id_Compensacion=@IdCompensacion;UPDATE comp.obligacion SET ImporteAplicado=ImporteAplicado+@AplicadoTotal,Flg_Estado=CASE WHEN ImporteAplicado+@AplicadoTotal>=Importe THEN 'C' ELSE 'A' END,Usu_Modif=@Usuario,Fec_Modif=GETDATE() WHERE Id_Obligacion=@Id_Obligacion;INSERT comp.compensacion_historial(Id_Compensacion,EstadoNuevo,Motivo,Usuario) VALUES(@IdCompensacion,'A','COMPENSACION APLICADA',@Usuario);COMMIT;SET @Ok=1;SET @Mensaje='Compensacion aplicada sin movimiento de caja.';END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;SET @Mensaje=ERROR_MESSAGE();SET @IdCompensacion=NULL;END CATCH;END
GO

IF OBJECT_ID('comp.p_revertir','P') IS NOT NULL DROP PROCEDURE comp.p_revertir;
GO
CREATE PROCEDURE comp.p_revertir @id_empresa INT,@id_est CHAR(2),@IdCompensacion INT,@Motivo VARCHAR(250),@Usuario INT,@Ok BIT OUTPUT,@Mensaje VARCHAR(300) OUTPUT
AS BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;SET @Ok=0;IF ISNULL(LTRIM(RTRIM(@Motivo)),'')='' BEGIN SET @Mensaje='Ingrese motivo de reversa.';RETURN;END;BEGIN TRY BEGIN TRAN;DECLARE @IdOb INT,@Importe DECIMAL(18,2);SELECT @IdOb=Id_Obligacion,@Importe=ImporteAplicado FROM comp.compensacion WITH(UPDLOCK,HOLDLOCK) WHERE Id_Compensacion=@IdCompensacion AND id_empresa=@id_empresa AND id_est=@id_est AND Flg_Estado='A';IF @IdOb IS NULL RAISERROR('Compensacion no disponible para reversa.',16,1);UPDATE fc SET ImpCancelado=CASE WHEN fc.ImpCancelado>=d.ImporteAplicado THEN fc.ImpCancelado-d.ImporteAplicado ELSE 0 END,FecCancelado=NULL,FlgStatusPago='P' FROM dbo.FI_Cobranza_Cuota fc JOIN comp.compensacion_detalle d ON d.NroCobranza=fc.NroCobranza AND d.NumCuota=fc.NumCuota AND d.Cod_Almacen=fc.Cod_Almacen WHERE d.Id_Compensacion=@IdCompensacion;UPDATE comp.obligacion SET ImporteAplicado=CASE WHEN ImporteAplicado>=@Importe THEN ImporteAplicado-@Importe ELSE 0 END,Flg_Estado='A',Usu_Modif=@Usuario,Fec_Modif=GETDATE() WHERE Id_Obligacion=@IdOb;UPDATE comp.compensacion SET Flg_Estado='R',Usu_Reversa=@Usuario,Fec_Reversa=GETDATE(),MotivoReversa=@Motivo WHERE Id_Compensacion=@IdCompensacion;INSERT comp.compensacion_historial(Id_Compensacion,EstadoAnterior,EstadoNuevo,Motivo,Usuario) VALUES(@IdCompensacion,'A','R',@Motivo,@Usuario);COMMIT;SET @Ok=1;SET @Mensaje='Compensacion revertida correctamente.';END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;SET @Mensaje=ERROR_MESSAGE();END CATCH;END
GO

IF OBJECT_ID('comp.p_listar','P') IS NOT NULL DROP PROCEDURE comp.p_listar;
GO
CREATE PROCEDURE comp.p_listar @id_empresa INT,@id_est CHAR(2) AS BEGIN SET NOCOUNT ON;SELECT c.Id_Compensacion,c.Numero,c.Fecha,ISNULL(a.Des_Anexo,'') Persona,o.Cod_Concepto,co.Nombre Concepto,c.ImporteAplicado,c.Flg_Estado,CASE c.Flg_Estado WHEN 'A' THEN 'Aplicada' WHEN 'R' THEN 'Revertida' ELSE 'Anulada' END Estado,c.Id_Obligacion,c.Fec_Creacion,(SELECT COUNT(*) FROM comp.compensacion_detalle d WHERE d.Id_Compensacion=c.Id_Compensacion) CuotasAfectadas FROM comp.compensacion c JOIN comp.obligacion o ON o.Id_Obligacion=c.Id_Obligacion JOIN comp.concepto_obligacion co ON co.Cod_Concepto=o.Cod_Concepto LEFT JOIN dbo.CN_AnexosContables a ON a.Cod_TipAnex=c.Cod_TipAnex AND a.Cod_Anxo=c.Cod_Anxo WHERE c.id_empresa=@id_empresa AND c.id_est=@id_est ORDER BY c.Id_Compensacion DESC;END
GO
IF OBJECT_ID('comp.p_obtener','P') IS NOT NULL DROP PROCEDURE comp.p_obtener;
GO
CREATE PROCEDURE comp.p_obtener @id_empresa INT,@id_est CHAR(2),@IdCompensacion INT AS BEGIN SET NOCOUNT ON;SELECT c.*,ISNULL(a.Des_Anexo,'') Persona,ISNULL(a.Num_Ruc,'') Documento,co.Nombre Concepto,o.Importe ImporteObligacion,o.ImporteAplicado ImporteObligacionAplicado,o.Importe-o.ImporteAplicado SaldoFavorActual FROM comp.compensacion c JOIN comp.obligacion o ON o.Id_Obligacion=c.Id_Obligacion JOIN comp.concepto_obligacion co ON co.Cod_Concepto=o.Cod_Concepto LEFT JOIN dbo.CN_AnexosContables a ON a.Cod_TipAnex=c.Cod_TipAnex AND a.Cod_Anxo=c.Cod_Anxo WHERE c.Id_Compensacion=@IdCompensacion AND c.id_empresa=@id_empresa AND c.id_est=@id_est;SELECT * FROM comp.compensacion_detalle WHERE Id_Compensacion=@IdCompensacion ORDER BY OrdenAplicacion;SELECT * FROM comp.compensacion_historial WHERE Id_Compensacion=@IdCompensacion ORDER BY Id_Historial;END
GO
IF OBJECT_ID('comp.p_prestamos_cliente','P') IS NOT NULL DROP PROCEDURE comp.p_prestamos_cliente;
GO
CREATE PROCEDURE comp.p_prestamos_cliente @id_empresa INT,@Cod_TipAnex CHAR(1),@Cod_Anxo CHAR(6),@FechaCorte DATE
AS BEGIN SET NOCOUNT ON;SELECT p.Id_Prestamo,p.Fecha,p.FechaFinCobro,ISNULL(cp.Nombre,'') Concepto,CAST(SUM(CASE WHEN fc.ImpCuota>fc.ImpCancelado THEN fc.ImpCuota-fc.ImpCancelado ELSE 0 END) AS DECIMAL(18,2)) SaldoPendiente,CAST(SUM(CASE WHEN fc.Fec_vencDocum<=@FechaCorte AND fc.ImpCuota>fc.ImpCancelado THEN fc.ImpCuota-fc.ImpCancelado ELSE 0 END) AS DECIMAL(18,2)) SaldoVencido,SUM(CASE WHEN fc.Fec_vencDocum<=@FechaCorte AND fc.ImpCuota>fc.ImpCancelado THEN 1 ELSE 0 END) CuotasVencidas FROM prest.prestamo p JOIN prest.cuota c ON c.Id_Prestamo=p.Id_Prestamo JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen LEFT JOIN prest.concepto cp ON cp.Cod_Concepto=p.Cod_Concepto WHERE p.id_empresa=@id_empresa AND p.Cod_TipAnex=@Cod_TipAnex AND p.Cod_Anxo=@Cod_Anxo AND ISNULL(p.Flg_Estado,'A') NOT IN('X','R') GROUP BY p.Id_Prestamo,p.Fecha,p.FechaFinCobro,cp.Nombre HAVING SUM(CASE WHEN fc.ImpCuota>fc.ImpCancelado THEN fc.ImpCuota-fc.ImpCancelado ELSE 0 END)>0 ORDER BY p.Fecha,p.Id_Prestamo;END
GO
