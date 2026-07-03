USE db_9fa64e_adminfg;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE flota.p_PagoContrato_Obtener
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdPagoContrato INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPagoContrato,
        p.id_empresa,
        p.id_est,
        p.Id_Contrato,
        p.Id_Chofer,
        p.Id_Vehiculo,
        p.Id_OperacionDia,
        p.FechaPago,
        p.Importe,
        p.IdFormaPago,
        fp.tipo AS FormaPago,
        fp.tipo AS FormaPagoTexto,
        fp.abrev AS FormaPagoAbrev,
        p.OperacionReferencia,
        p.Observacion,
        p.FlgValidado,
        p.FlgEstado,
        p.ImporteAplicado,
        p.ImporteDisponible,
        p.Usu_Creacion,
        p.Fec_Creacion,
        p.Usu_Valida,
        p.Fec_Valida,
        p.MotivoValidacion,
        p.Usu_Anula,
        p.Fec_Anula,
        p.MotivoAnula,
        c.Numero AS ContratoNumero,
        v.Placa,
        ISNULL(ch.Nombres, ch.Cod_TipAnex + '-' + ch.Cod_Anxo) AS Chofer
    FROM flota.PagoContrato p
    INNER JOIN flota.contrato c ON c.Id_Contrato = p.Id_Contrato
    INNER JOIN flota.vehiculo v ON v.Id_Vehiculo = p.Id_Vehiculo
    INNER JOIN flota.chofer ch ON ch.Id_Chofer = p.Id_Chofer
    INNER JOIN dbo.formaPago fp ON fp.IdFormaPago = p.IdFormaPago
    WHERE p.IdPagoContrato = @IdPagoContrato
      AND p.id_empresa = @IdEmpresa
      AND p.id_est = @IdEst;

    SELECT
        IdAdjunto,
        TipoAdjunto,
        RutaArchivo,
        NombreOriginal,
        MimeType,
        TamanoBytes,
        Observacion,
        Fec_Creacion
    FROM flota.AdjuntoFlota
    WHERE id_empresa = @IdEmpresa
      AND id_est = @IdEst
      AND TipoEntidad = 'PAGO_CONTRATO'
      AND IdEntidad = @IdPagoContrato
      AND FlgEstado = 'A'
    ORDER BY Fec_Creacion DESC, IdAdjunto DESC;
END;
GO
ALTER PROCEDURE flota.p_PagoContrato_ListarPorContrato
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT,
    @FlgValidado VARCHAR(1) = NULL,
    @FlgEstado VARCHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPagoContrato,
        p.Id_Contrato,
        c.Numero AS ContratoNumero,
        p.Id_Chofer,
        ISNULL(ch.Nombres, ch.Cod_TipAnex + '-' + ch.Cod_Anxo) AS Chofer,
        p.Id_Vehiculo,
        v.Placa,
        p.Id_OperacionDia,
        p.FechaPago,
        p.Importe,
        p.ImporteAplicado,
        p.ImporteDisponible,
        p.IdFormaPago,
        fp.tipo AS FormaPago,
        fp.tipo AS FormaPagoTexto,
        p.OperacionReferencia,
        p.Observacion,
        p.FlgValidado,
        p.FlgEstado,
        p.Fec_Creacion,
        p.Fec_Valida
    FROM flota.PagoContrato p
    INNER JOIN flota.contrato c ON c.Id_Contrato = p.Id_Contrato
    INNER JOIN flota.chofer ch ON ch.Id_Chofer = p.Id_Chofer
    INNER JOIN flota.vehiculo v ON v.Id_Vehiculo = p.Id_Vehiculo
    INNER JOIN dbo.formaPago fp ON fp.IdFormaPago = p.IdFormaPago
    WHERE p.id_empresa = @IdEmpresa
      AND p.id_est = @IdEst
      AND p.Id_Contrato = @IdContrato
      AND (@FlgValidado IS NULL OR p.FlgValidado = @FlgValidado)
      AND (@FlgEstado IS NULL OR p.FlgEstado = @FlgEstado)
    ORDER BY p.FechaPago DESC, p.IdPagoContrato DESC;
END;
GO
ALTER PROCEDURE flota.p_PagoContrato_ListarPendientes
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT = NULL,
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPagoContrato,
        p.Id_Contrato,
        c.Numero AS ContratoNumero,
        p.Id_Chofer,
        ISNULL(ch.Nombres, ch.Cod_TipAnex + '-' + ch.Cod_Anxo) AS Chofer,
        p.Id_Vehiculo,
        v.Placa,
        p.Id_OperacionDia,
        p.FechaPago,
        p.Importe,
        p.ImporteAplicado,
        p.ImporteDisponible,
        p.IdFormaPago,
        fp.tipo AS FormaPago,
        fp.tipo AS FormaPagoTexto,
        p.OperacionReferencia,
        p.Observacion,
        p.FlgValidado,
        p.FlgEstado,
        p.Fec_Creacion
    FROM flota.PagoContrato p
    INNER JOIN flota.contrato c ON c.Id_Contrato = p.Id_Contrato
    INNER JOIN flota.chofer ch ON ch.Id_Chofer = p.Id_Chofer
    INNER JOIN flota.vehiculo v ON v.Id_Vehiculo = p.Id_Vehiculo
    INNER JOIN dbo.formaPago fp ON fp.IdFormaPago = p.IdFormaPago
    WHERE p.id_empresa = @IdEmpresa
      AND p.id_est = @IdEst
      AND p.FlgEstado = 'A'
      AND p.FlgValidado = 'N'
      AND (@IdContrato IS NULL OR p.Id_Contrato = @IdContrato)
      AND (@FechaDesde IS NULL OR CONVERT(DATE, p.FechaPago) >= @FechaDesde)
      AND (@FechaHasta IS NULL OR CONVERT(DATE, p.FechaPago) <= @FechaHasta)
    ORDER BY p.FechaPago DESC, p.IdPagoContrato DESC;
END;
GO
