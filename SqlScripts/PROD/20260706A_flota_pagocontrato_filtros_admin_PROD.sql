IF DB_NAME() <> 'DB_9FA64E_bdgas'
BEGIN
    RAISERROR('Este script solo debe ejecutarse en DB_9FA64E_bdgas.',16,1);
    SET NOEXEC ON;
END
GO

IF OBJECT_ID('flota.p_PagoContrato_Obtener', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_PagoContrato_Obtener AS BEGIN SET NOCOUNT ON; END');
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
END
GO

IF OBJECT_ID('flota.p_PagoContrato_ListarPendientes', 'P') IS NULL
    EXEC('CREATE PROCEDURE flota.p_PagoContrato_ListarPendientes AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE flota.p_PagoContrato_ListarPendientes
    @IdEmpresa INT,
    @IdEst CHAR(2),
    @IdContrato INT = NULL,
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @Texto VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @Texto = NULLIF(LTRIM(RTRIM(@Texto)), '');

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
      AND (@FechaDesde IS NULL OR p.FechaPago >= @FechaDesde)
      AND (@FechaHasta IS NULL OR p.FechaPago < DATEADD(DAY, 1, @FechaHasta))
      AND
      (
          @Texto IS NULL
          OR c.Numero LIKE '%' + @Texto + '%'
          OR ISNULL(ch.Nombres, ch.Cod_TipAnex + '-' + ch.Cod_Anxo) LIKE '%' + @Texto + '%'
          OR v.Placa LIKE '%' + @Texto + '%'
          OR ISNULL(p.OperacionReferencia, '') LIKE '%' + @Texto + '%'
          OR fp.tipo LIKE '%' + @Texto + '%'
      )
    ORDER BY p.FechaPago DESC, p.IdPagoContrato DESC;
END
GO

