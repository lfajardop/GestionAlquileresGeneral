/* =============================================================
   FIX ESTADO DE CUENTA / CUENTA CORRIENTE
   Base objetivo: DB_9FA64E_bdgas
   SQL Server 2014 compatible
   Solo corrige SPs de lectura / calculo
   No inserta datos
   No modifica prestamos reales
   No toca caja / cobranza
============================================================= */
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Base incorrecta. Este script solo debe ejecutarse en DB_9FA64E_bdgas.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('prest.prestamo', 'U') IS NULL
    OR OBJECT_ID('prest.cuota', 'U') IS NULL
    OR OBJECT_ID('dbo.FI_Cobranza_Cuota', 'U') IS NULL
    OR OBJECT_ID('dbo.FI_Cobranza_Pago', 'U') IS NULL
BEGIN
    RAISERROR('Faltan tablas base de prestamos/cobranza.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('comp.compensacion', 'U') IS NULL
    OR OBJECT_ID('comp.compensacion_detalle', 'U') IS NULL
BEGIN
    RAISERROR('Faltan tablas de compensacion. Aplicar primero migracion comp.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('prest.p_ctacte_cliente_resumen', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_ctacte_cliente_resumen;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE prest.p_ctacte_cliente_resumen
(
    @Cod_TipAnex CHAR(1),
    @Cod_Anxo CHAR(6)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.Cod_TipAnex,
        p.Cod_Anxo,
        COUNT(*) AS CantPrestamos,
        SUM(ISNULL(p.Capital, 0)) AS TotalCapital,
        SUM(ISNULL(p.TotalCobrar, 0)) AS TotalProgramado,
        SUM(ISNULL(pg.TotalPagado, 0)) AS TotalPagado,
        SUM(ISNULL(cp.TotalCompensado, 0)) AS TotalCompensado,
        SUM(ISNULL(pg.TotalPagado, 0) + ISNULL(cp.TotalCompensado, 0)) AS TotalAplicado,
        SUM(ISNULL(p.TotalCobrar, 0) - ISNULL(pg.TotalPagado, 0) - ISNULL(cp.TotalCompensado, 0)) AS SaldoPendiente
    FROM prest.prestamo p
    OUTER APPLY
    (
        SELECT
            SUM(ISNULL(pg.Importe, 0)) AS TotalPagado
        FROM prest.cuota c
        JOIN dbo.FI_Cobranza_Pago pg
            ON pg.NroCobranza = c.NroCobranza
           AND pg.NumCuota = c.Num_Secuencia
        WHERE c.Id_Prestamo = p.Id_Prestamo
    ) pg
    OUTER APPLY
    (
        SELECT
            SUM(ISNULL(d.ImporteAplicado, 0)) AS TotalCompensado
        FROM comp.compensacion_detalle d
        JOIN comp.compensacion c
            ON c.Id_Compensacion = d.Id_Compensacion
        WHERE d.Id_Prestamo = p.Id_Prestamo
          AND c.Flg_Estado = 'A'
    ) cp
    WHERE p.Cod_TipAnex = @Cod_TipAnex
      AND p.Cod_Anxo = @Cod_Anxo
      AND ISNULL(p.Flg_Estado, 'A') <> 'X'
    GROUP BY
        p.Cod_TipAnex,
        p.Cod_Anxo;
END;
GO

IF OBJECT_ID('prest.p_ctacte_cliente_detalle', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_ctacte_cliente_detalle;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE prest.p_ctacte_cliente_detalle
(
    @Cod_TipAnex CHAR(1),
    @Cod_Anxo CHAR(6)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.Id_Prestamo,
        p.Fecha,
        cp.Nombre AS Concepto,
        p.Capital,
        p.Nro_Cuotas,
        p.PorcInteresMensual,
        CONVERT(VARCHAR(20), CAST(ISNULL(p.PorcInteresMensual, 0) AS DECIMAL(10,2))) + ' %' AS PorcInteresMensualTexto,
        p.TotalCobrar AS TotalProgramado,
        ISNULL(pg.TotalPagado, 0) AS TotalPagado,
        ISNULL(cm.TotalCompensado, 0) AS TotalCompensado,
        ISNULL(pg.TotalPagado, 0) + ISNULL(cm.TotalCompensado, 0) AS TotalAplicado,
        ISNULL(p.TotalCobrar, 0) - ISNULL(pg.TotalPagado, 0) - ISNULL(cm.TotalCompensado, 0) AS SaldoPendiente,
        p.Flg_Estado,
        CASE
            WHEN ISNULL(p.TotalCobrar, 0) - ISNULL(pg.TotalPagado, 0) - ISNULL(cm.TotalCompensado, 0) <= 0 THEN 'Cancelado'
            WHEN ISNULL(v.CuotasVencidas, 0) > 0 THEN 'Vencido'
            ELSE 'Vigente'
        END AS EstadoTexto,
        p.Flg_Desembolsado,
        CASE ISNULL(p.Flg_Desembolsado, '')
            WHEN 'N' THEN 'No desembolsado'
            WHEN 'P' THEN 'Parcial'
            WHEN 'S' THEN 'Completo'
            ELSE ISNULL(p.Flg_Desembolsado, '')
        END AS DesembolsadoTexto,
        ISNULL(p.Imp_Desembolsado, 0) AS Imp_Desembolsado,
        pg.UltimoPago,
        prox.ProximaCuota,
        prox.ProximoVencimiento,
        ISNULL(s.CuotasPendientes, 0) AS CuotasPendientes,
        ISNULL(v.CuotasVencidas, 0) AS CuotasVencidas,
        CASE
            WHEN v.PrimerVencido IS NOT NULL
                THEN DATEDIFF(DAY, v.PrimerVencido, CAST(GETDATE() AS DATE))
            ELSE 0
        END AS DiasAtraso,
        p.Observacion
    FROM prest.prestamo p
    LEFT JOIN prest.concepto cp
        ON cp.Cod_Concepto = p.Cod_Concepto
    OUTER APPLY
    (
        SELECT
            SUM(CASE WHEN ISNULL(fc.ImpCuota, 0) > ISNULL(fc.ImpCancelado, 0) THEN 1 ELSE 0 END) AS CuotasPendientes
        FROM prest.cuota c
        JOIN dbo.FI_Cobranza_Cuota fc
            ON fc.NroCobranza = c.NroCobranza
           AND fc.NumCuota = c.Num_Secuencia
           AND fc.Cod_Almacen = p.Cod_Almacen
        WHERE c.Id_Prestamo = p.Id_Prestamo
    ) s
    OUTER APPLY
    (
        SELECT
            SUM(ISNULL(pg.Importe, 0)) AS TotalPagado,
            MAX(pg.Fec_Pago) AS UltimoPago
        FROM prest.cuota c
        JOIN dbo.FI_Cobranza_Pago pg
            ON pg.NroCobranza = c.NroCobranza
           AND pg.NumCuota = c.Num_Secuencia
        WHERE c.Id_Prestamo = p.Id_Prestamo
    ) pg
    OUTER APPLY
    (
        SELECT
            SUM(ISNULL(d.ImporteAplicado, 0)) AS TotalCompensado
        FROM comp.compensacion_detalle d
        JOIN comp.compensacion c
            ON c.Id_Compensacion = d.Id_Compensacion
        WHERE d.Id_Prestamo = p.Id_Prestamo
          AND c.Flg_Estado = 'A'
    ) cm
    OUTER APPLY
    (
        SELECT TOP 1
            c.Num_Secuencia AS ProximaCuota,
            c.Fec_Venc AS ProximoVencimiento
        FROM prest.cuota c
        JOIN dbo.FI_Cobranza_Cuota fc
            ON fc.NroCobranza = c.NroCobranza
           AND fc.NumCuota = c.Num_Secuencia
           AND fc.Cod_Almacen = p.Cod_Almacen
        WHERE c.Id_Prestamo = p.Id_Prestamo
          AND ISNULL(fc.ImpCuota, 0) > ISNULL(fc.ImpCancelado, 0)
        ORDER BY c.Fec_Venc, c.Num_Secuencia
    ) prox
    OUTER APPLY
    (
        SELECT
            COUNT(*) AS CuotasVencidas,
            MIN(c.Fec_Venc) AS PrimerVencido
        FROM prest.cuota c
        JOIN dbo.FI_Cobranza_Cuota fc
            ON fc.NroCobranza = c.NroCobranza
           AND fc.NumCuota = c.Num_Secuencia
           AND fc.Cod_Almacen = p.Cod_Almacen
        WHERE c.Id_Prestamo = p.Id_Prestamo
          AND ISNULL(fc.ImpCuota, 0) > ISNULL(fc.ImpCancelado, 0)
          AND c.Fec_Venc < CAST(GETDATE() AS DATE)
    ) v
    WHERE p.Cod_TipAnex = @Cod_TipAnex
      AND p.Cod_Anxo = @Cod_Anxo
      AND ISNULL(p.Flg_Estado, 'A') NOT IN ('X', 'R')
    ORDER BY p.Fecha DESC, p.Id_Prestamo DESC;
END;
GO

IF OBJECT_ID('prest.p_ctacte_cliente_cuotas', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_ctacte_cliente_cuotas;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE prest.p_ctacte_cliente_cuotas
(
    @Cod_TipAnex CHAR(1),
    @Cod_Anxo CHAR(6)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#base') IS NOT NULL
        DROP TABLE #base;

    SELECT
        p.Id_Prestamo,
        p.Fecha AS FechaPrestamo,
        p.Capital,
        p.TotalCobrar,
        p.PorcInteresMensual,
        p.Cod_Almacen,
        c.Num_Secuencia AS NumCuota,
        c.Fec_Venc,
        ISNULL(fc.ImporteBase, 0) AS ImporteBase,
        ISNULL(fc.ImporteInteres, 0) AS ImporteInteres,
        ISNULL(fc.ImpCuota, 0) AS ImpCuota,
        ISNULL(pg.ImpPagadoCaja, 0) AS ImpPagado,
        ISNULL(cm.ImpCompensado, 0) AS ImpCompensado,
        ISNULL(pg.ImpPagadoCaja, 0) + ISNULL(cm.ImpCompensado, 0) AS TotalAplicadoCuota,
        ISNULL(fc.ImpCuota, 0) - ISNULL(pg.ImpPagadoCaja, 0) - ISNULL(cm.ImpCompensado, 0) AS SaldoCuota,
        CASE
            WHEN ISNULL(fc.ImpCuota, 0) - ISNULL(pg.ImpPagadoCaja, 0) - ISNULL(cm.ImpCompensado, 0) <= 0 THEN 'C'
            WHEN ISNULL(pg.ImpPagadoCaja, 0) + ISNULL(cm.ImpCompensado, 0) > 0 THEN 'P'
            ELSE 'N'
        END AS EstadoPago
    INTO #base
    FROM prest.prestamo p
    JOIN prest.cuota c
        ON c.Id_Prestamo = p.Id_Prestamo
    JOIN dbo.FI_Cobranza_Cuota fc
        ON fc.NroCobranza = c.NroCobranza
       AND fc.NumCuota = c.Num_Secuencia
       AND fc.Cod_Almacen = p.Cod_Almacen
    OUTER APPLY
    (
        SELECT SUM(ISNULL(pg.Importe, 0)) AS ImpPagadoCaja
        FROM dbo.FI_Cobranza_Pago pg
        WHERE pg.NroCobranza = c.NroCobranza
          AND pg.NumCuota = c.Num_Secuencia
    ) pg
    OUTER APPLY
    (
        SELECT SUM(ISNULL(d.ImporteAplicado, 0)) AS ImpCompensado
        FROM comp.compensacion_detalle d
        JOIN comp.compensacion cc
            ON cc.Id_Compensacion = d.Id_Compensacion
        WHERE d.NroCobranza = c.NroCobranza
          AND d.NumCuota = c.Num_Secuencia
          AND d.Cod_Almacen = p.Cod_Almacen
          AND cc.Flg_Estado = 'A'
    ) cm
    WHERE p.Cod_TipAnex = @Cod_TipAnex
      AND p.Cod_Anxo = @Cod_Anxo
      AND ISNULL(p.Flg_Estado, 'A') <> 'X';

    SELECT
        Id_Prestamo,
        FechaPrestamo,
        Capital,
        TotalCobrar,
        PorcInteresMensual,
        CONVERT(VARCHAR(20), CAST(ISNULL(PorcInteresMensual,0) AS DECIMAL(10,2))) + ' %' AS PorcInteresMensualTexto,
        NumCuota,
        Fec_Venc,
        ImporteBase,
        ImporteInteres,
        ImpCuota,
        ImpPagado,
        ImpCompensado,
        TotalAplicadoCuota,
        SaldoCuota,
        CASE EstadoPago
            WHEN 'C' THEN 'Cancelada'
            WHEN 'P' THEN 'Parcial'
            ELSE 'Pendiente'
        END AS EstadoCuota,
        SUM(ImpCuota) OVER (
            PARTITION BY Id_Prestamo
            ORDER BY NumCuota
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS AcumProgramadoPrestamo,
        SUM(ImpPagado) OVER (
            PARTITION BY Id_Prestamo
            ORDER BY NumCuota
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS AcumPagadoPrestamo,
        SUM(ImpCompensado) OVER (
            PARTITION BY Id_Prestamo
            ORDER BY NumCuota
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS AcumCompensadoPrestamo,
        SUM(TotalAplicadoCuota) OVER (
            PARTITION BY Id_Prestamo
            ORDER BY NumCuota
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS AcumAplicadoPrestamo,
        SUM(SaldoCuota) OVER (
            PARTITION BY Id_Prestamo
            ORDER BY NumCuota
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS AcumSaldoPrestamo,
        SUM(ImpCuota) OVER (
            ORDER BY Id_Prestamo, NumCuota
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS AcumProgramadoGlobal,
        SUM(ImpPagado) OVER (
            ORDER BY Id_Prestamo, NumCuota
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS AcumPagadoGlobal,
        SUM(ImpCompensado) OVER (
            ORDER BY Id_Prestamo, NumCuota
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS AcumCompensadoGlobal,
        SUM(TotalAplicadoCuota) OVER (
            ORDER BY Id_Prestamo, NumCuota
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS AcumAplicadoGlobal,
        SUM(SaldoCuota) OVER (
            ORDER BY Id_Prestamo, NumCuota
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS AcumSaldoGlobal,
        CASE
            WHEN SaldoCuota > 0 AND Fec_Venc < CAST(GETDATE() AS DATE)
                THEN DATEDIFF(DAY, Fec_Venc, CAST(GETDATE() AS DATE))
            ELSE 0
        END AS DiasAtraso
    FROM #base
    ORDER BY Id_Prestamo, NumCuota;

    SELECT
        COUNT(DISTINCT Id_Prestamo) AS TotalPrestamos,
        SUM(ImpCuota) AS TotalProgramado,
        SUM(ImpPagado) AS TotalPagado,
        SUM(ImpCompensado) AS TotalCompensado,
        SUM(TotalAplicadoCuota) AS TotalAplicado,
        SUM(SaldoCuota) AS TotalSaldo
    FROM #base;

    DROP TABLE #base;
END;
GO

IF OBJECT_ID('prest.p_ctacte_clientes_resumen_general', 'P') IS NOT NULL
    DROP PROCEDURE prest.p_ctacte_clientes_resumen_general;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE prest.p_ctacte_clientes_resumen_general
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#base') IS NOT NULL
        DROP TABLE #base;

    SELECT
        p.Cod_TipAnex,
        p.Cod_Anxo,
        p.Id_Prestamo,
        p.Capital,
        ISNULL(p.TotalCobrar, 0) AS TotalProgramado,
        ISNULL(pg.TotalPagado, 0) AS TotalPagado,
        ISNULL(cm.TotalCompensado, 0) AS TotalCompensado,
        ISNULL(pg.TotalPagado, 0) + ISNULL(cm.TotalCompensado, 0) AS TotalAplicado,
        ISNULL(p.TotalCobrar, 0) - ISNULL(pg.TotalPagado, 0) - ISNULL(cm.TotalCompensado, 0) AS SaldoPendiente
    INTO #base
    FROM prest.prestamo p
    OUTER APPLY
    (
        SELECT
            SUM(ISNULL(pg.Importe, 0)) AS TotalPagado
        FROM prest.cuota c
        JOIN dbo.FI_Cobranza_Pago pg
            ON pg.NroCobranza = c.NroCobranza
           AND pg.NumCuota = c.Num_Secuencia
        WHERE c.Id_Prestamo = p.Id_Prestamo
    ) pg
    OUTER APPLY
    (
        SELECT
            SUM(ISNULL(d.ImporteAplicado, 0)) AS TotalCompensado
        FROM comp.compensacion_detalle d
        JOIN comp.compensacion c
            ON c.Id_Compensacion = d.Id_Compensacion
        WHERE d.Id_Prestamo = p.Id_Prestamo
          AND c.Flg_Estado = 'A'
    ) cm
    WHERE ISNULL(p.Flg_Estado, 'A') NOT IN ('X', 'R');

    SELECT
        b.Cod_TipAnex,
        b.Cod_Anxo,
        ISNULL(a.Des_Anexo, '') AS Cliente,
        COUNT(DISTINCT b.Id_Prestamo) AS CantPrestamos,
        SUM(b.Capital) AS TotalCapital,
        SUM(b.TotalProgramado) AS TotalProgramado,
        SUM(b.TotalPagado) AS TotalPagado,
        SUM(b.TotalCompensado) AS TotalCompensado,
        SUM(b.TotalAplicado) AS TotalAplicado,
        SUM(b.SaldoPendiente) AS TotalSaldo
    FROM #base b
    LEFT JOIN dbo.CN_AnexosContables a
        ON a.Cod_TipAnex = b.Cod_TipAnex
       AND a.Cod_Anxo = b.Cod_Anxo
    GROUP BY
        b.Cod_TipAnex,
        b.Cod_Anxo,
        a.Des_Anexo
    ORDER BY
        TotalSaldo DESC,
        a.Des_Anexo;

    SELECT
        COUNT(DISTINCT b.Cod_TipAnex + '-' + b.Cod_Anxo) AS TotalClientes,
        COUNT(DISTINCT b.Id_Prestamo) AS TotalPrestamos,
        SUM(b.Capital) AS TotalCapital,
        SUM(b.TotalProgramado) AS TotalProgramado,
        SUM(b.TotalPagado) AS TotalPagado,
        SUM(b.TotalCompensado) AS TotalCompensado,
        SUM(b.TotalAplicado) AS TotalAplicado,
        SUM(b.SaldoPendiente) AS TotalSaldo
    FROM #base b;

    DROP TABLE #base;
END;
GO
