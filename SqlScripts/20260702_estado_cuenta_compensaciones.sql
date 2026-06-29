/* Estado de cuenta: ImpCancelado es la fuente unica de saldo.
   FI_Cobranza_Pago conserva solo pagos con movimiento financiero. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('prest.p_ctacte_cliente_detalle','P') IS NOT NULL DROP PROCEDURE prest.p_ctacte_cliente_detalle;
GO
CREATE PROCEDURE prest.p_ctacte_cliente_detalle @Cod_TipAnex CHAR(1),@Cod_Anxo CHAR(6)
AS
BEGIN
 SET NOCOUNT ON;
 SELECT p.Id_Prestamo,p.Fecha,ISNULL(cp.Nombre,'') ConceptoMostrar,p.Capital,p.Nro_Cuotas,p.PorcInteresMensual,
        CONVERT(VARCHAR(20),CAST(ISNULL(p.PorcInteresMensual,0) AS DECIMAL(10,2)))+' %' PorcInteresMensualTexto,
        ISNULL(p.TotalCobrar,0) TotalProgramado,ISNULL(s.TotalPagado,0) TotalPagado,
        ISNULL(s.SaldoPendiente,0) SaldoPendiente,p.Flg_Estado,
        CASE WHEN ISNULL(s.SaldoPendiente,0)<=0 THEN 'Cancelado' WHEN ISNULL(v.CuotasVencidas,0)>0 THEN 'Vencido' ELSE 'Vigente' END EstadoTexto,
        p.Flg_Desembolsado,CASE ISNULL(p.Flg_Desembolsado,'') WHEN 'N' THEN 'No desembolsado' WHEN 'P' THEN 'Parcial' WHEN 'S' THEN 'Completo' ELSE ISNULL(p.Flg_Desembolsado,'') END DesembolsadoTexto,
        ISNULL(p.Imp_Desembolsado,0) Imp_Desembolsado,s.UltimoPago,prox.ProximaCuota,prox.ProximoVencimiento,
        ISNULL(s.CuotasPendientes,0) CuotasPendientes,ISNULL(v.CuotasVencidas,0) CuotasVencidas,
        CASE WHEN v.PrimerVencido IS NULL THEN 0 ELSE DATEDIFF(DAY,v.PrimerVencido,CONVERT(date,GETDATE())) END DiasAtraso,p.Observacion
 FROM prest.prestamo p
 LEFT JOIN prest.concepto cp ON cp.Cod_Concepto=p.Cod_Concepto
 OUTER APPLY(
  SELECT SUM(ISNULL(fc.ImpCancelado,0)) TotalPagado,SUM(CASE WHEN fc.ImpCuota>fc.ImpCancelado THEN fc.ImpCuota-fc.ImpCancelado ELSE 0 END) SaldoPendiente,
         SUM(CASE WHEN fc.ImpCuota>fc.ImpCancelado THEN 1 ELSE 0 END) CuotasPendientes,MAX(fc.FecCancelado) UltimoPago
  FROM prest.cuota c JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen WHERE c.Id_Prestamo=p.Id_Prestamo
 ) s
 OUTER APPLY(
  SELECT TOP 1 c.Num_Secuencia ProximaCuota,c.Fec_Venc ProximoVencimiento FROM prest.cuota c JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen WHERE c.Id_Prestamo=p.Id_Prestamo AND fc.ImpCuota>fc.ImpCancelado ORDER BY c.Fec_Venc,c.Num_Secuencia
 ) prox
 OUTER APPLY(
  SELECT COUNT(*) CuotasVencidas,MIN(c.Fec_Venc) PrimerVencido FROM prest.cuota c JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen WHERE c.Id_Prestamo=p.Id_Prestamo AND fc.ImpCuota>fc.ImpCancelado AND c.Fec_Venc<CONVERT(date,GETDATE())
 ) v
 WHERE p.Cod_TipAnex=@Cod_TipAnex AND p.Cod_Anxo=@Cod_Anxo AND ISNULL(p.Flg_Estado,'A') NOT IN('X','R')
 ORDER BY p.Fecha DESC,p.Id_Prestamo DESC;
END
GO
IF OBJECT_ID('prest.p_ctacte_clientes_resumen_general','P') IS NOT NULL DROP PROCEDURE prest.p_ctacte_clientes_resumen_general;
GO
CREATE PROCEDURE prest.p_ctacte_clientes_resumen_general
AS
BEGIN
 SET NOCOUNT ON;
 IF OBJECT_ID('tempdb..#base') IS NOT NULL DROP TABLE #base;
 SELECT p.Cod_TipAnex,p.Cod_Anxo,p.Id_Prestamo,p.Capital,ISNULL(p.TotalCobrar,0) TotalProgramado,
        ISNULL(s.TotalPagado,0) TotalPagado,ISNULL(s.SaldoPendiente,0) SaldoPendiente
 INTO #base FROM prest.prestamo p
 OUTER APPLY(SELECT SUM(ISNULL(fc.ImpCancelado,0)) TotalPagado,SUM(CASE WHEN fc.ImpCuota>fc.ImpCancelado THEN fc.ImpCuota-fc.ImpCancelado ELSE 0 END) SaldoPendiente FROM prest.cuota c JOIN dbo.FI_Cobranza_Cuota fc ON fc.NroCobranza=c.NroCobranza AND fc.NumCuota=c.Num_Secuencia AND fc.Cod_Almacen=p.Cod_Almacen WHERE c.Id_Prestamo=p.Id_Prestamo) s
 WHERE ISNULL(p.Flg_Estado,'A') NOT IN('X','R');
 SELECT b.Cod_TipAnex,b.Cod_Anxo,ISNULL(a.Des_Anexo,'') Cliente,COUNT(DISTINCT b.Id_Prestamo) CantPrestamos,SUM(b.Capital) TotalCapital,SUM(b.TotalProgramado) TotalProgramado,SUM(b.TotalPagado) TotalPagado,SUM(b.SaldoPendiente) TotalSaldo
 FROM #base b LEFT JOIN dbo.CN_AnexosContables a ON a.Cod_TipAnex=b.Cod_TipAnex AND a.Cod_Anxo=b.Cod_Anxo GROUP BY b.Cod_TipAnex,b.Cod_Anxo,a.Des_Anexo ORDER BY TotalSaldo DESC,a.Des_Anexo;
 SELECT COUNT(DISTINCT b.Cod_TipAnex+'-'+b.Cod_Anxo) TotalClientes,COUNT(DISTINCT b.Id_Prestamo) TotalPrestamos,SUM(b.Capital) TotalCapital,SUM(b.TotalProgramado) TotalProgramado,SUM(b.TotalPagado) TotalPagado,SUM(b.SaldoPendiente) TotalSaldo FROM #base b;
 DROP TABLE #base;
END
GO
