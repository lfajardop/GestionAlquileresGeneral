/*
ETAPA 1 URGENTE FLOTA - RESUMEN GLOBAL DEUDA CHOFER
Base objetivo: DB_9FA64E_bdgas

Reglas:
- Solo consulta
- No tocar caja/cobranza
- No aplicar PagoContrato a recibos
- No liquidar combustible
- No borrar datos
*/

IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en DB_9FA64E_bdgas.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.chofer','U') IS NULL
BEGIN
    RAISERROR('No existe flota.chofer.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.contrato','U') IS NULL
BEGIN
    RAISERROR('No existe flota.contrato.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.ReciboAlquiler','U') IS NULL
BEGIN
    RAISERROR('No existe flota.ReciboAlquiler.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.PagoContrato','U') IS NULL
BEGIN
    RAISERROR('No existe flota.PagoContrato.',16,1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('flota.p_Chofer_DeudaResumen','P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_Chofer_DeudaResumen AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE flota.p_Chofer_DeudaResumen
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdChofer INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChoferBase AS
    (
        SELECT
            ch.Id_Chofer,
            ch.Nombres AS Chofer,
            ISNULL(ch.Documento,'') AS Documento,
            ISNULL(ch.Telefono,'') AS Telefono
        FROM flota.chofer ch
        WHERE ch.id_empresa = @IdEmpresa
          AND ch.id_est = @IdEst
          AND (@IdChofer IS NULL OR ch.Id_Chofer = @IdChofer)
    ),
    ContratoAgg AS
    (
        SELECT
            c.Id_Chofer,
            COUNT(1) AS TotalContratos,
            SUM(CASE WHEN ISNULL(c.Flg_Estado,'') = 'A' THEN 1 ELSE 0 END) AS ContratosActivos,
            SUM(CASE WHEN ISNULL(c.Flg_Estado,'') = 'C' THEN 1 ELSE 0 END) AS ContratosCerrados
        FROM flota.contrato c
        WHERE c.id_empresa = @IdEmpresa
          AND c.id_est = @IdEst
          AND (@IdChofer IS NULL OR c.Id_Chofer = @IdChofer)
        GROUP BY c.Id_Chofer
    ),
    ReciboAgg AS
    (
        SELECT
            c.Id_Chofer,
            SUM(ISNULL(r.ImporteTotal,0)) AS TotalGeneradoRecibos,
            SUM(ISNULL(r.ImportePagado,0)) AS TotalPagadoRecibos,
            SUM(ISNULL(r.Saldo,0)) AS SaldoRecibos,
            MAX(CASE WHEN ISNULL(r.Saldo,0) > 0 THEN COALESCE(r.FechaFin,r.FechaInicio,r.FechaEmision) END) AS UltimaFechaDeuda
        FROM flota.contrato c
        INNER JOIN flota.ReciboAlquiler r
            ON r.Id_Contrato = c.Id_Contrato
           AND r.id_empresa = c.id_empresa
           AND r.id_est = c.id_est
        WHERE c.id_empresa = @IdEmpresa
          AND c.id_est = @IdEst
          AND ISNULL(r.Estado,'') <> 'X'
          AND (@IdChofer IS NULL OR c.Id_Chofer = @IdChofer)
        GROUP BY c.Id_Chofer
    ),
    PagoContratoAgg AS
    (
        SELECT
            pc.Id_Chofer,
            SUM(CASE WHEN ISNULL(pc.FlgEstado,'') = 'A' AND ISNULL(pc.FlgValidado,'') = 'N' THEN ISNULL(pc.ImporteDisponible,0) ELSE 0 END) AS PagoDeclaradoPendiente,
            SUM(CASE WHEN ISNULL(pc.FlgEstado,'') = 'A' AND ISNULL(pc.FlgValidado,'') = 'S' THEN ISNULL(pc.ImporteDisponible,0) ELSE 0 END) AS PagoDeclaradoValidadoNoAplicado
        FROM flota.PagoContrato pc
        WHERE pc.id_empresa = @IdEmpresa
          AND pc.id_est = @IdEst
          AND (@IdChofer IS NULL OR pc.Id_Chofer = @IdChofer)
        GROUP BY pc.Id_Chofer
    )
    SELECT
        cb.Id_Chofer AS IdChofer,
        cb.Chofer,
        cb.Documento,
        cb.Telefono,
        ISNULL(ca.TotalContratos,0) AS TotalContratos,
        ISNULL(ca.ContratosActivos,0) AS ContratosActivos,
        ISNULL(ca.ContratosCerrados,0) AS ContratosCerrados,
        ISNULL(ra.TotalGeneradoRecibos,0) AS TotalGeneradoRecibos,
        ISNULL(ra.TotalPagadoRecibos,0) AS TotalPagadoRecibos,
        ISNULL(ra.SaldoRecibos,0) AS SaldoRecibos,
        ISNULL(pa.PagoDeclaradoPendiente,0) AS PagoDeclaradoPendiente,
        ISNULL(pa.PagoDeclaradoValidadoNoAplicado,0) AS PagoDeclaradoValidadoNoAplicado,
        ra.UltimaFechaDeuda
    FROM ChoferBase cb
    LEFT JOIN ContratoAgg ca
        ON ca.Id_Chofer = cb.Id_Chofer
    LEFT JOIN ReciboAgg ra
        ON ra.Id_Chofer = cb.Id_Chofer
    LEFT JOIN PagoContratoAgg pa
        ON pa.Id_Chofer = cb.Id_Chofer
    ORDER BY cb.Chofer;
END;
GO
