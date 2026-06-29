USE [DB_9FA64E_bdgas]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET LOCK_TIMEOUT 15000
GO

/* Extiende el staging Yape existente sin duplicar la infraestructura actual. */
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Lote', 'NombreArchivo') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Lote ADD NombreArchivo VARCHAR(260) NULL;
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Lote', 'HashArchivo') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Lote ADD HashArchivo VARCHAR(64) NULL;
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Lote', 'FechaDesde') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Lote ADD FechaDesde DATE NULL;
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Lote', 'FechaHasta') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Lote ADD FechaHasta DATE NULL;
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Lote', 'Flg_Estado') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Lote ADD Flg_Estado VARCHAR(1) NOT NULL CONSTRAINT DF_CJ_Yape_Lote_Estado DEFAULT('R');
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Lote', 'Fec_Confirma') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Lote ADD Fec_Confirma DATETIME NULL;
GO

IF COL_LENGTH('dbo.CJ_Yape_Importacion_Detalle', 'NumFilaExcel') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Detalle ADD NumFilaExcel INT NULL;
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Detalle', 'TipoNormalizado') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Detalle ADD TipoNormalizado VARCHAR(20) NULL;
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Detalle', 'Flg_Seleccionado') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Detalle ADD Flg_Seleccionado VARCHAR(1) NOT NULL CONSTRAINT DF_CJ_Yape_Det_Seleccion DEFAULT('N');
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Detalle', 'Flg_Estado') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Detalle ADD Flg_Estado VARCHAR(1) NOT NULL CONSTRAINT DF_CJ_Yape_Det_Estado DEFAULT('P');
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Detalle', 'Sec_Movimiento_Existente') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Detalle ADD Sec_Movimiento_Existente INT NULL;
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Detalle', 'Sec_Movimiento_Generado') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Detalle ADD Sec_Movimiento_Generado INT NULL;
IF COL_LENGTH('dbo.CJ_Yape_Importacion_Detalle', 'MotivoResultado') IS NULL
    ALTER TABLE dbo.CJ_Yape_Importacion_Detalle ADD MotivoResultado VARCHAR(300) NULL;
GO

IF OBJECT_ID('dbo.CJ_Yape_Importacion_Log', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CJ_Yape_Importacion_Log
    (
        IdLog BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        IdLote INT NOT NULL,
        Accion VARCHAR(30) NOT NULL,
        Mensaje VARCHAR(500) NULL,
        Cod_Usuario VARCHAR(50) NULL,
        Fec_Crea DATETIME NOT NULL CONSTRAINT DF_CJ_Yape_ImpLog_Fecha DEFAULT(GETDATE()),
        CONSTRAINT FK_CJ_Yape_ImpLog_Lote FOREIGN KEY(IdLote)
            REFERENCES dbo.CJ_Yape_Importacion_Lote(IdLote)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CJ_Yape_Importacion_Detalle') AND name='IX_CJ_Yape_Detalle_Hash')
    CREATE INDEX IX_CJ_Yape_Detalle_Hash ON dbo.CJ_Yape_Importacion_Detalle(HashMovimiento, IdLote);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CJ_Yape_Importacion_Detalle') AND name='IX_CJ_Yape_Detalle_Lote')
    CREATE INDEX IX_CJ_Yape_Detalle_Lote ON dbo.CJ_Yape_Importacion_Detalle(IdLote, Flg_Estado, Flg_Seleccionado);
GO

IF TYPE_ID('dbo.CJ_Yape_MovimientoWebType') IS NULL
EXEC('CREATE TYPE dbo.CJ_Yape_MovimientoWebType AS TABLE
(
    NumFilaExcel INT NOT NULL,
    FechaYape DATETIME NOT NULL,
    TipoYape VARCHAR(50) NOT NULL,
    TipoNormalizado VARCHAR(20) NOT NULL,
    Origen VARCHAR(200) NULL,
    Destino VARCHAR(200) NULL,
    Monto DECIMAL(18,2) NOT NULL,
    Glosa VARCHAR(500) NULL,
    Beneficiario VARCHAR(200) NULL,
    HashMovimiento VARCHAR(64) NOT NULL
)');
GO

IF OBJECT_ID('dbo.CJ_Yape_CajaActiva_Listar','P') IS NULL EXEC('CREATE PROCEDURE dbo.CJ_Yape_CajaActiva_Listar AS SELECT 1')
GO
ALTER PROCEDURE dbo.CJ_Yape_CajaActiva_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        m.Cod_CajaChica,
        ISNULL(c.Des_CajaChica, m.Cod_CajaChica) AS Des_CajaChica,
        m.Num_Movstk,
        m.Num_Transaccion,
        CONVERT(DATE, DATEFROMPARTS(YEAR(m.Fec_Movimiento), MONTH(m.Fec_Movimiento), 1)) AS FechaDesde,
        CONVERT(DATE, EOMONTH(m.Fec_Movimiento)) AS FechaHasta,
        m.Observaciones
    FROM dbo.CJ_Movimientos m
    LEFT JOIN dbo.CJ_CajaChica c ON c.Cod_CajaChica=m.Cod_CajaChica
    WHERE m.Flg_Status='P'
    ORDER BY m.Fec_Movimiento DESC, m.Cod_CajaChica;
END
GO

IF OBJECT_ID('dbo.CJ_Yape_Concepto_Listar','P') IS NULL EXEC('CREATE PROCEDURE dbo.CJ_Yape_Concepto_Listar AS SELECT 1')
GO
ALTER PROCEDURE dbo.CJ_Yape_Concepto_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RTRIM(Cod_Concepto_Caja) AS Cod_Concepto_Caja,
           RTRIM(Des_Concepto_Caja) AS Des_Concepto_Caja,
           RTRIM(ISNULL(Tip_Concepto,'')) AS Tip_Concepto
    FROM dbo.CJ_Conceptos
    WHERE ISNULL(Flg_Seleccionable,'N')='S'
      AND ISNULL(Flg_Muestra,'S')<>'N'
    ORDER BY Des_Concepto_Caja;
END
GO

IF OBJECT_ID('dbo.CJ_Yape_Importacion_Web_Crear','P') IS NULL EXEC('CREATE PROCEDURE dbo.CJ_Yape_Importacion_Web_Crear AS SELECT 1')
GO
ALTER PROCEDURE dbo.CJ_Yape_Importacion_Web_Crear
(
    @NombreArchivo VARCHAR(260),
    @HashArchivo VARCHAR(64),
    @Cod_CajaChica CHAR(2),
    @Cod_Usuario VARCHAR(50),
    @Movimientos dbo.CJ_Yape_MovimientoWebType READONLY,
    @IdLote INT OUTPUT,
    @Mensaje VARCHAR(500) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Num_Movstk INT, @Num_Transaccion INT, @FechaDesde DATE, @FechaHasta DATE;
    SELECT @Num_Movstk=Num_Movstk, @Num_Transaccion=Num_Transaccion,
           @FechaDesde=DATEFROMPARTS(YEAR(Fec_Movimiento),MONTH(Fec_Movimiento),1),
           @FechaHasta=EOMONTH(Fec_Movimiento)
    FROM dbo.CJ_Movimientos
    WHERE Cod_CajaChica=@Cod_CajaChica AND Flg_Status='P';

    IF @Num_Movstk IS NULL
        RAISERROR('La caja seleccionada ya no se encuentra abierta.',16,1);
    IF NOT EXISTS(SELECT 1 FROM @Movimientos)
        RAISERROR('El archivo no contiene movimientos del periodo de la caja activa.',16,1);

    BEGIN TRY
        BEGIN TRAN;
        INSERT dbo.CJ_Yape_Importacion_Lote
        (NombreTablaOrigen,Periodo,Cod_CajaChica,Num_Movstk,Num_Transaccion,Motivo,
         TotalFilas,TotalInsertadas,TotalDuplicadas,TotalRevision,Cod_Usuario,Fec_Crea,
         NombreArchivo,HashArchivo,FechaDesde,FechaHasta,Flg_Estado)
        SELECT @NombreArchivo,CONVERT(CHAR(7),@FechaDesde,120),@Cod_CajaChica,@Num_Movstk,@Num_Transaccion,
               'IMPORTACION WEB YAPE',COUNT(1),0,0,0,@Cod_Usuario,GETDATE(),
               @NombreArchivo,@HashArchivo,@FechaDesde,@FechaHasta,'R'
        FROM @Movimientos;
        SET @IdLote=SCOPE_IDENTITY();

        INSERT dbo.CJ_Yape_Importacion_Detalle
        (IdLote,FechaYape,TipoYape,Origen,Destino,Monto,Glosa,Beneficiario,
         Cod_Concepto_Caja,IdReglaAplicada,PalabraAplicada,Score,RequiereRevision,
         FueInsertado,FueDuplicado,HashMovimiento,Observacion,Fec_Crea,
         NumFilaExcel,TipoNormalizado,Flg_Seleccionado,Flg_Estado,MotivoResultado)
        SELECT @IdLote,x.FechaYape,x.TipoYape,x.Origen,x.Destino,x.Monto,x.Glosa,x.Beneficiario,
               NULL,NULL,NULL,0,0,0,0,x.HashMovimiento,NULL,GETDATE(),x.NumFilaExcel,x.TipoNormalizado,
               CASE WHEN x.TipoNormalizado='SALIDA' THEN 'S' ELSE 'N' END,'P',NULL
        FROM @Movimientos x;

        /* Idempotencia entre archivos y coincidencia exacta en la caja. */
        UPDATE d SET FueDuplicado=1, Flg_Seleccionado='N', Flg_Estado='D',
                     Observacion='El mismo movimiento ya fue cargado en otro lote.'
        FROM dbo.CJ_Yape_Importacion_Detalle d
        WHERE d.IdLote=@IdLote AND EXISTS
        (SELECT 1 FROM dbo.CJ_Yape_Importacion_Detalle a
         WHERE a.IdLote<>@IdLote AND a.HashMovimiento=d.HashMovimiento
           AND (a.FueInsertado=1 OR a.FueDuplicado=1));

        UPDATE d SET FueDuplicado=1, Flg_Seleccionado='N', Flg_Estado='D',
                     Sec_Movimiento_Existente=m.Sec_Movimiento,
                     Observacion='Coincidencia exacta encontrada en movimientos de caja.'
        FROM dbo.CJ_Yape_Importacion_Detalle d
        CROSS APPLY
        (SELECT TOP 1 md.Sec_Movimiento
         FROM dbo.CJ_Movimientos_Detalle md
         WHERE md.Cod_CajaChica=@Cod_CajaChica
           AND CONVERT(DATE,md.Fec_Movimiento)=CONVERT(DATE,d.FechaYape)
           AND ABS(ISNULL(md.Imp_Movimiento,0)-ISNULL(d.Monto,0))<0.01
           AND (dbo.fn_NormalizarTexto(md.Glosa)=dbo.fn_NormalizarTexto(d.Glosa)
                OR dbo.fn_NormalizarTexto(md.Beneficiario)=dbo.fn_NormalizarTexto(d.Beneficiario))
         ORDER BY md.Sec_Movimiento DESC) m
        WHERE d.IdLote=@IdLote AND d.FueDuplicado=0;

        DECLARE @IdDetalle INT,@Tipo VARCHAR(50),@TipoNorm VARCHAR(20),@Glosa VARCHAR(500),
                @Origen VARCHAR(200),@Destino VARCHAR(200),@Benef VARCHAR(200),@Monto DECIMAL(18,2),
                @Concepto VARCHAR(10),@IdRegla INT,@Palabra VARCHAR(100),@Score INT,@Revision BIT,@Motivo VARCHAR(300);
        DECLARE c CURSOR LOCAL FAST_FORWARD FOR
            SELECT IdDetalleImportacion,TipoYape,TipoNormalizado,Glosa,Origen,Destino,Beneficiario,Monto
            FROM dbo.CJ_Yape_Importacion_Detalle WHERE IdLote=@IdLote AND FueDuplicado=0;
        OPEN c;
        FETCH NEXT FROM c INTO @IdDetalle,@Tipo,@TipoNorm,@Glosa,@Origen,@Destino,@Benef,@Monto;
        WHILE @@FETCH_STATUS=0
        BEGIN
            EXEC dbo.CJ_Yape_CategorizarMovimientoSmart
                @Tipo=@Tipo,@TipoNormalizado=@TipoNorm,@CodConceptoGenerico=NULL,
                @Glosa=@Glosa,@Origen=@Origen,@Destino=@Destino,@Beneficiario=@Benef,@Monto=@Monto,
                @RegistrarUsoRegla=0,@Cod_Concepto_Caja=@Concepto OUTPUT,@IdReglaAplicada=@IdRegla OUTPUT,
                @PalabraAplicada=@Palabra OUTPUT,@Score=@Score OUTPUT,@RequiereRevision=@Revision OUTPUT,
                @MotivoResultado=@Motivo OUTPUT;
            UPDATE dbo.CJ_Yape_Importacion_Detalle
            SET Cod_Concepto_Caja=@Concepto,IdReglaAplicada=@IdRegla,PalabraAplicada=@Palabra,
                Score=@Score,RequiereRevision=@Revision,MotivoResultado=@Motivo
            WHERE IdDetalleImportacion=@IdDetalle;
            FETCH NEXT FROM c INTO @IdDetalle,@Tipo,@TipoNorm,@Glosa,@Origen,@Destino,@Benef,@Monto;
        END
        CLOSE c; DEALLOCATE c;

        UPDATE l SET TotalDuplicadas=(SELECT COUNT(1) FROM dbo.CJ_Yape_Importacion_Detalle WHERE IdLote=@IdLote AND FueDuplicado=1),
                     TotalRevision=(SELECT COUNT(1) FROM dbo.CJ_Yape_Importacion_Detalle WHERE IdLote=@IdLote AND RequiereRevision=1)
        FROM dbo.CJ_Yape_Importacion_Lote l WHERE IdLote=@IdLote;
        INSERT dbo.CJ_Yape_Importacion_Log(IdLote,Accion,Mensaje,Cod_Usuario)
        VALUES(@IdLote,'CARGAR','Archivo cargado y categorizado para vista previa.',@Cod_Usuario);
        COMMIT;
        SET @Mensaje='Archivo cargado correctamente.';
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local','c')>=0 CLOSE c;
        IF CURSOR_STATUS('local','c')>=-1 DEALLOCATE c;
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH
END
GO

IF OBJECT_ID('dbo.CJ_Yape_Importacion_Web_Preview','P') IS NULL EXEC('CREATE PROCEDURE dbo.CJ_Yape_Importacion_Web_Preview AS SELECT 1')
GO
ALTER PROCEDURE dbo.CJ_Yape_Importacion_Web_Preview @IdLote INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT l.IdLote,l.NombreArchivo,l.Periodo,l.Cod_CajaChica,l.Num_Movstk,l.Num_Transaccion,
           l.FechaDesde,l.FechaHasta,l.Flg_Estado,l.TotalFilas,l.TotalInsertadas,l.TotalDuplicadas,l.TotalRevision
    FROM dbo.CJ_Yape_Importacion_Lote l WHERE l.IdLote=@IdLote;
    SELECT d.IdDetalleImportacion,d.NumFilaExcel,d.FechaYape,d.TipoYape,d.TipoNormalizado,d.Origen,d.Destino,
           d.Beneficiario,d.Monto,d.Glosa,RTRIM(d.Cod_Concepto_Caja) Cod_Concepto_Caja,
           ISNULL(RTRIM(c.Des_Concepto_Caja),'') Des_Concepto_Caja,d.Score,d.RequiereRevision,d.FueDuplicado,
           d.Flg_Seleccionado,d.Flg_Estado,d.Observacion,d.MotivoResultado,d.Sec_Movimiento_Existente
    FROM dbo.CJ_Yape_Importacion_Detalle d
    LEFT JOIN dbo.CJ_Conceptos c ON c.Cod_Concepto_Caja=d.Cod_Concepto_Caja
    WHERE d.IdLote=@IdLote ORDER BY d.FechaYape,d.IdDetalleImportacion;
END
GO

IF OBJECT_ID('dbo.CJ_Yape_Importacion_Web_Actualizar','P') IS NULL EXEC('CREATE PROCEDURE dbo.CJ_Yape_Importacion_Web_Actualizar AS SELECT 1')
GO
ALTER PROCEDURE dbo.CJ_Yape_Importacion_Web_Actualizar
 @IdLote INT,@IdDetalle INT,@Flg_Seleccionado VARCHAR(1),@Cod_Concepto_Caja VARCHAR(10),@Observacion VARCHAR(300)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM dbo.CJ_Yape_Importacion_Lote WHERE IdLote=@IdLote AND Flg_Estado<>'R')
        RAISERROR('El lote ya no se puede modificar.',16,1);
    UPDATE dbo.CJ_Yape_Importacion_Detalle
    SET Flg_Seleccionado=CASE WHEN FueDuplicado=1 THEN 'N' ELSE @Flg_Seleccionado END,
        Cod_Concepto_Caja=@Cod_Concepto_Caja,Observacion=@Observacion,
        RequiereRevision=CASE WHEN ISNULL(@Cod_Concepto_Caja,'')='' THEN 1 ELSE 0 END
    WHERE IdLote=@IdLote AND IdDetalleImportacion=@IdDetalle;
END
GO

IF OBJECT_ID('dbo.CJ_Yape_Importacion_Web_Confirmar','P') IS NULL EXEC('CREATE PROCEDURE dbo.CJ_Yape_Importacion_Web_Confirmar AS SELECT 1')
GO
ALTER PROCEDURE dbo.CJ_Yape_Importacion_Web_Confirmar
 @IdLote INT,@Cod_Usuario VARCHAR(50),@Cod_Estacion VARCHAR(15),@Ok BIT OUTPUT,@Mensaje VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @Ok=0;
    DECLARE @Caja CHAR(2),@Mov INT,@Tra INT,@Estado VARCHAR(1);
    SELECT @Caja=Cod_CajaChica,@Mov=Num_Movstk,@Tra=Num_Transaccion,@Estado=Flg_Estado
    FROM dbo.CJ_Yape_Importacion_Lote WITH(UPDLOCK,HOLDLOCK) WHERE IdLote=@IdLote;
    IF @Estado<>'R' BEGIN SET @Mensaje='El lote ya fue confirmado o no está disponible.'; RETURN; END
    IF NOT EXISTS(SELECT 1 FROM dbo.CJ_Movimientos WHERE Cod_CajaChica=@Caja AND Num_Movstk=@Mov AND Num_Transaccion=@Tra AND Flg_Status='P')
    BEGIN SET @Mensaje='La caja del lote ya no está abierta.'; RETURN; END
    IF EXISTS(SELECT 1 FROM dbo.CJ_Yape_Importacion_Detalle WHERE IdLote=@IdLote AND Flg_Seleccionado='S' AND ISNULL(Cod_Concepto_Caja,'')='')
    BEGIN SET @Mensaje='Hay movimientos seleccionados sin concepto de caja.'; RETURN; END

    BEGIN TRY
      BEGIN TRAN;
      DECLARE @Id INT,@Fecha DATETIME,@Concepto CHAR(3),@Monto DECIMAL(18,2),@Glosa VARCHAR(500),@Benef VARCHAR(100),@Tipo VARCHAR(50),@Origen VARCHAR(200),@Destino VARCHAR(200),@SecAntes INT,@SecNuevo INT;
      DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT IdDetalleImportacion,FechaYape,LEFT(Cod_Concepto_Caja,3),Monto,Glosa,LEFT(Beneficiario,100),TipoYape,Origen,Destino
        FROM dbo.CJ_Yape_Importacion_Detalle
        WHERE IdLote=@IdLote AND Flg_Seleccionado='S' AND FueDuplicado=0 AND FueInsertado=0 ORDER BY FechaYape;
      OPEN c; FETCH NEXT FROM c INTO @Id,@Fecha,@Concepto,@Monto,@Glosa,@Benef,@Tipo,@Origen,@Destino;
      WHILE @@FETCH_STATUS=0
      BEGIN
        SET @Glosa=CASE WHEN NULLIF(LTRIM(RTRIM(@Glosa)),'') IS NULL THEN 'IMPORTADO DESDE EXCEL YAPE' ELSE @Glosa END;
        SELECT @SecAntes=ISNULL(MAX(Sec_Movimiento),0) FROM dbo.CJ_Movimientos_Detalle WITH(UPDLOCK,HOLDLOCK) WHERE Cod_CajaChica=@Caja AND Num_Movstk=@Mov AND Num_Transaccion=@Tra;
        EXEC dbo.CJ_MAN_MOVIMIENTO_DETALLE @ACCION='I',@Cod_CajaChica=@Caja,@Num_Movstk=@Mov,@Sec_Movimiento=0,
          @Num_Transaccion=@Tra,@Fec_Movimiento=@Fecha,@Cod_Concepto_Caja=@Concepto,@Cod_TipAnex='',@Cod_Anxo='',
          @Cod_Moneda_Docum='SOL',@Imp_Movimiento_MonedaDocum=@Monto,@Imp_Movimiento=@Monto,@Tipo_Cambio=1,@Tipo_Cambio_Otros=0,
          @Num_Corre_Previo='',@Cod_TipDoc='20',@Ser_docum='',@Num_Docum='',@Glosa=@Glosa,@Beneficiario=@Benef,
          @Cod_Area='00',@Cod_Usuario=@Cod_Usuario,@Cod_Estacion=@Cod_Estacion,@FLG_TRANSACCION='N',
          @Num_Corre_Compras='',@Sec_Pago_Compras='',@Flg_Ingresado_Caja_Usuario='N',@cod_Fabrica='',@Tip_Trabajador='',
          @Cod_Trabajador='',@nro_docide_beneficiario='',@Motivo='IMPORTACION YAPE',@De=@Origen,@A=@Destino,@Cod_ClaBie='',
          @Num_corre_doc_diversos='',@Num_Cobranza=NULL,@NumCuota=NULL,@Cod_Almacen=NULL,@Flg_Puede_Elim='S',@Fec_Efectiva=@Fecha,@Cod_Inversion=NULL;
        SELECT @SecNuevo=MAX(Sec_Movimiento) FROM dbo.CJ_Movimientos_Detalle WHERE Cod_CajaChica=@Caja AND Num_Movstk=@Mov AND Num_Transaccion=@Tra AND Sec_Movimiento>@SecAntes;
        UPDATE dbo.CJ_Yape_Importacion_Detalle SET FueInsertado=1,Flg_Estado='I',Sec_Movimiento_Generado=@SecNuevo WHERE IdDetalleImportacion=@Id;
        FETCH NEXT FROM c INTO @Id,@Fecha,@Concepto,@Monto,@Glosa,@Benef,@Tipo,@Origen,@Destino;
      END
      CLOSE c; DEALLOCATE c;
      UPDATE dbo.CJ_Yape_Importacion_Lote SET Flg_Estado='C',Fec_Confirma=GETDATE(),
        TotalInsertadas=(SELECT COUNT(1) FROM dbo.CJ_Yape_Importacion_Detalle WHERE IdLote=@IdLote AND FueInsertado=1)
      WHERE IdLote=@IdLote;
      INSERT dbo.CJ_Yape_Importacion_Log(IdLote,Accion,Mensaje,Cod_Usuario)
      VALUES(@IdLote,'CONFIRMAR','Movimientos seleccionados insertados en caja.',@Cod_Usuario);
      COMMIT; SET @Ok=1; SET @Mensaje='Importación confirmada correctamente.';
    END TRY
    BEGIN CATCH
      IF CURSOR_STATUS('local','c')>=0 CLOSE c;
      IF CURSOR_STATUS('local','c')>=-1 DEALLOCATE c;
      IF @@TRANCOUNT>0 ROLLBACK;
      SET @Mensaje=ERROR_MESSAGE();
    END CATCH
END
GO
