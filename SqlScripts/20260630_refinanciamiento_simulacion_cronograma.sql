/* Vista previa exacta del cronograma usado por p_prestamo_crear_y_plan_v2. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('prest.p_refinanciamiento_simular_cronograma','P') IS NOT NULL
 DROP PROCEDURE prest.p_refinanciamiento_simular_cronograma;
GO
CREATE PROCEDURE prest.p_refinanciamiento_simular_cronograma
 @Capital DECIMAL(18,2),@PorcInteresMensual DECIMAL(18,4),@FrecuenciaPago CHAR(1),
 @TipoModalidad CHAR(1),@FechaInicio DATE,@FechaFin DATE
AS
BEGIN
 SET NOCOUNT ON;
 IF @Capital<=0 OR @PorcInteresMensual<=0 OR @FechaFin<@FechaInicio OR @FrecuenciaPago NOT IN('D','S','M') OR @TipoModalidad NOT IN('C','I','F')
 BEGIN SELECT CAST(0 AS BIT) Ok,'Revise capital, tasa, frecuencia, modalidad y fechas.' Mensaje;RETURN;END;
 DECLARE @FinExclusiva DATE=DATEADD(DAY,1,@FechaFin),@InteresMensual DECIMAL(18,10)=@Capital*(@PorcInteresMensual/100.0);
 DECLARE @C TABLE(Numero INT PRIMARY KEY,FechaDesde DATE,FechaHasta DATE,Vencimiento DATE,InteresRaw DECIMAL(18,10) DEFAULT(0),Capital DECIMAL(18,2) DEFAULT(0),Interes DECIMAL(18,2) DEFAULT(0),Importe DECIMAL(18,2) DEFAULT(0));
 DECLARE @n INT=1,@desde DATE=@FechaInicio,@hasta DATE,@sig DATE;
 IF @TipoModalidad='F' INSERT @C(Numero,FechaDesde,FechaHasta,Vencimiento) VALUES(1,@FechaInicio,@FechaFin,@FechaFin);
 ELSE WHILE @desde<@FinExclusiva
 BEGIN
  SET @sig=CASE @FrecuenciaPago WHEN 'D' THEN DATEADD(DAY,1,@desde) WHEN 'S' THEN DATEADD(DAY,7,@desde) ELSE DATEADD(MONTH,1,@desde) END;
  SET @hasta=CASE WHEN @sig<@FinExclusiva THEN DATEADD(DAY,-1,@sig) ELSE @FechaFin END;
  INSERT @C(Numero,FechaDesde,FechaHasta,Vencimiento) VALUES(@n,@desde,@hasta,@hasta);SET @n+=1;SET @desde=@sig;
 END;
 DECLARE @cuotas INT=(SELECT COUNT(*) FROM @C),@i INT=1,@rDesde DATE,@rHasta DATE,@cursor DATE,@cicloIni DATE,@cicloFin DATE,@corte DATE,@diasCiclo INT,@diasTramo INT,@interesPeriodo DECIMAL(18,10);
 WHILE @i<=@cuotas
 BEGIN
  SELECT @rDesde=FechaDesde,@rHasta=FechaHasta FROM @C WHERE Numero=@i;SET @interesPeriodo=0;SET @cursor=@rDesde;
  WHILE @cursor<=@rHasta
  BEGIN
   SET @cicloIni=@FechaInicio;WHILE DATEADD(MONTH,1,@cicloIni)<=@cursor SET @cicloIni=DATEADD(MONTH,1,@cicloIni);
   SET @cicloFin=DATEADD(MONTH,1,@cicloIni);SET @diasCiclo=DATEDIFF(DAY,@cicloIni,@cicloFin);
   SET @corte=CASE WHEN DATEADD(DAY,-1,@cicloFin)<@rHasta THEN DATEADD(DAY,-1,@cicloFin) ELSE @rHasta END;
   SET @diasTramo=DATEDIFF(DAY,@cursor,DATEADD(DAY,1,@corte));SET @interesPeriodo+=CASE WHEN @diasCiclo>0 THEN (@InteresMensual/@diasCiclo)*@diasTramo ELSE 0 END;SET @cursor=DATEADD(DAY,1,@corte);
  END;
  UPDATE @C SET InteresRaw=@interesPeriodo WHERE Numero=@i;SET @i+=1;
 END;
 DECLARE @interesTotalRaw DECIMAL(18,10)=(SELECT SUM(InteresRaw) FROM @C),@baseRegular DECIMAL(18,2),@baseUltima DECIMAL(18,2),@sumBase DECIMAL(18,2),@sumInteres DECIMAL(18,2),@interesUltimo DECIMAL(18,2);
 IF @TipoModalidad='F' UPDATE @C SET Capital=@Capital,Interes=CAST(@interesTotalRaw AS DECIMAL(18,2)),Importe=CAST(@Capital+@interesTotalRaw AS DECIMAL(18,2));
 ELSE IF @TipoModalidad='I'
 BEGIN
  UPDATE @C SET Capital=0,Interes=ROUND(InteresRaw,2),Importe=ROUND(InteresRaw,2) WHERE Numero<@cuotas;
  SELECT @sumInteres=ISNULL(SUM(Interes),0) FROM @C WHERE Numero<@cuotas;SET @interesUltimo=CAST(@interesTotalRaw-@sumInteres AS DECIMAL(18,2));
  UPDATE @C SET Capital=@Capital,Interes=@interesUltimo,Importe=@Capital+@interesUltimo WHERE Numero=@cuotas;
 END
 ELSE
 BEGIN
  SET @baseRegular=ROUND(@Capital/@cuotas,2);UPDATE @C SET Capital=@baseRegular WHERE Numero<@cuotas;SELECT @sumBase=ISNULL(SUM(Capital),0) FROM @C WHERE Numero<@cuotas;SET @baseUltima=@Capital-@sumBase;UPDATE @C SET Capital=@baseUltima WHERE Numero=@cuotas;
  UPDATE @C SET Interes=ROUND(InteresRaw,2) WHERE Numero<@cuotas;SELECT @sumInteres=ISNULL(SUM(Interes),0) FROM @C WHERE Numero<@cuotas;SET @interesUltimo=CAST(@interesTotalRaw-@sumInteres AS DECIMAL(18,2));UPDATE @C SET Interes=@interesUltimo WHERE Numero=@cuotas;UPDATE @C SET Importe=Capital+Interes;
 END;
 DECLARE @interesTotal DECIMAL(18,2)=(SELECT SUM(Interes) FROM @C),@total DECIMAL(18,2)=(SELECT SUM(Importe) FROM @C),@tea DECIMAL(18,4)=CAST((POWER(1+@PorcInteresMensual/100.0,12)-1)*100 AS DECIMAL(18,4));
 SELECT CAST(1 AS BIT) Ok,'Cronograma simulado correctamente.' Mensaje,@cuotas NroCuotas,@Capital Capital,@interesTotal InteresTotal,@total TotalCobrar,@tea TeaReferencial;
 SELECT Numero,FechaDesde,FechaHasta,Vencimiento,Capital,Interes,Importe FROM @C ORDER BY Numero;
END
GO
