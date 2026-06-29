/* =============================================================
   REFINANCIACION / REPROGRAMACION - BASE MULTIEMPRESA
   Empresa inicial: 6 | Establecimiento origen: 4
   Este script no crea ni cierra prestamos.
============================================================= */
SET XACT_ABORT ON;
GO

IF COL_LENGTH('prest.prestamo','id_empresa') IS NULL ALTER TABLE prest.prestamo ADD id_empresa INT NULL;
IF COL_LENGTH('prest.prestamo','id_est_origen') IS NULL ALTER TABLE prest.prestamo ADD id_est_origen CHAR(2) NULL;
IF COL_LENGTH('prest.prestamo','Alcance') IS NULL ALTER TABLE prest.prestamo ADD Alcance VARCHAR(1) NULL;
GO
UPDATE prest.prestamo SET id_empresa=6 WHERE id_empresa IS NULL;
UPDATE prest.prestamo SET id_est_origen='4' WHERE id_est_origen IS NULL;
UPDATE prest.prestamo SET Alcance='E' WHERE Alcance IS NULL;
GO
ALTER TABLE prest.prestamo ALTER COLUMN id_empresa INT NOT NULL;
ALTER TABLE prest.prestamo ALTER COLUMN id_est_origen CHAR(2) NOT NULL;
ALTER TABLE prest.prestamo ALTER COLUMN Alcance VARCHAR(1) NOT NULL;

-- Compatibilidad con los procedimientos heredados que aun no envian el contexto tenant.
IF NOT EXISTS(SELECT 1 FROM sys.default_constraints dc JOIN sys.columns c ON c.object_id=dc.parent_object_id AND c.column_id=dc.parent_column_id WHERE dc.parent_object_id=OBJECT_ID('prest.prestamo') AND c.name='id_empresa')
 ALTER TABLE prest.prestamo ADD CONSTRAINT DF_prestamo_id_empresa DEFAULT(6) FOR id_empresa;
IF NOT EXISTS(SELECT 1 FROM sys.default_constraints dc JOIN sys.columns c ON c.object_id=dc.parent_object_id AND c.column_id=dc.parent_column_id WHERE dc.parent_object_id=OBJECT_ID('prest.prestamo') AND c.name='id_est_origen')
 ALTER TABLE prest.prestamo ADD CONSTRAINT DF_prestamo_id_est_origen DEFAULT('4') FOR id_est_origen;
IF NOT EXISTS(SELECT 1 FROM sys.default_constraints dc JOIN sys.columns c ON c.object_id=dc.parent_object_id AND c.column_id=dc.parent_column_id WHERE dc.parent_object_id=OBJECT_ID('prest.prestamo') AND c.name='Alcance')
 ALTER TABLE prest.prestamo ADD CONSTRAINT DF_prestamo_Alcance DEFAULT('E') FOR Alcance;
GO

IF COL_LENGTH('prest.prestamo_continuacion','id_empresa') IS NULL ALTER TABLE prest.prestamo_continuacion ADD id_empresa INT NULL;
IF COL_LENGTH('prest.prestamo_continuacion','id_est_origen') IS NULL ALTER TABLE prest.prestamo_continuacion ADD id_est_origen CHAR(2) NULL;
GO
UPDATE pc SET pc.id_empresa=p.id_empresa,pc.id_est_origen=p.id_est_origen
FROM prest.prestamo_continuacion pc JOIN prest.prestamo p ON p.Id_Prestamo=pc.Id_Prestamo
WHERE pc.id_empresa IS NULL OR pc.id_est_origen IS NULL;
GO
ALTER TABLE prest.prestamo_continuacion ALTER COLUMN id_empresa INT NOT NULL;
ALTER TABLE prest.prestamo_continuacion ALTER COLUMN id_est_origen CHAR(2) NOT NULL;

IF NOT EXISTS(SELECT 1 FROM sys.default_constraints dc JOIN sys.columns c ON c.object_id=dc.parent_object_id AND c.column_id=dc.parent_column_id WHERE dc.parent_object_id=OBJECT_ID('prest.prestamo_continuacion') AND c.name='id_empresa')
 ALTER TABLE prest.prestamo_continuacion ADD CONSTRAINT DF_prestamo_cont_id_empresa DEFAULT(6) FOR id_empresa;
IF NOT EXISTS(SELECT 1 FROM sys.default_constraints dc JOIN sys.columns c ON c.object_id=dc.parent_object_id AND c.column_id=dc.parent_column_id WHERE dc.parent_object_id=OBJECT_ID('prest.prestamo_continuacion') AND c.name='id_est_origen')
 ALTER TABLE prest.prestamo_continuacion ADD CONSTRAINT DF_prestamo_cont_id_est DEFAULT('4') FOR id_est_origen;
GO

IF OBJECT_ID('prest.operacion_tipo','U') IS NULL
BEGIN
 CREATE TABLE prest.operacion_tipo(Cod_Tipo VARCHAR(1) NOT NULL PRIMARY KEY,Nombre VARCHAR(80) NOT NULL,Flg_Activo VARCHAR(1) NOT NULL DEFAULT('S'),Orden INT NOT NULL DEFAULT(0));
END
IF OBJECT_ID('prest.operacion_estado','U') IS NULL
BEGIN
 CREATE TABLE prest.operacion_estado(Cod_Estado VARCHAR(1) NOT NULL PRIMARY KEY,Nombre VARCHAR(80) NOT NULL,Flg_Activo VARCHAR(1) NOT NULL DEFAULT('S'),Orden INT NOT NULL DEFAULT(0));
END
IF OBJECT_ID('prest.gracia_tipo','U') IS NULL
BEGIN
 CREATE TABLE prest.gracia_tipo(Cod_Gracia VARCHAR(1) NOT NULL PRIMARY KEY,Nombre VARCHAR(100) NOT NULL,GeneraInteres VARCHAR(1) NOT NULL,ExigeAutorizacion VARCHAR(1) NOT NULL,Flg_Activo VARCHAR(1) NOT NULL DEFAULT('S'),Orden INT NOT NULL DEFAULT(0));
END
IF OBJECT_ID('prest.operacion_motivo','U') IS NULL
BEGIN
 CREATE TABLE prest.operacion_motivo(Cod_Motivo VARCHAR(3) NOT NULL PRIMARY KEY,Nombre VARCHAR(120) NOT NULL,Flg_Activo VARCHAR(1) NOT NULL DEFAULT('S'),Orden INT NOT NULL DEFAULT(0));
END
IF OBJECT_ID('prest.alcance_tipo','U') IS NULL
BEGIN
 CREATE TABLE prest.alcance_tipo(Cod_Alcance VARCHAR(1) NOT NULL PRIMARY KEY,Nombre VARCHAR(80) NOT NULL,Flg_Activo VARCHAR(1) NOT NULL DEFAULT('S'),Orden INT NOT NULL DEFAULT(0));
END
GO

IF NOT EXISTS(SELECT 1 FROM prest.operacion_tipo WHERE Cod_Tipo='F') INSERT prest.operacion_tipo VALUES('F','Refinanciacion','S',1);
IF NOT EXISTS(SELECT 1 FROM prest.operacion_tipo WHERE Cod_Tipo='R') INSERT prest.operacion_tipo VALUES('R','Reprogramacion','S',2);
IF NOT EXISTS(SELECT 1 FROM prest.operacion_tipo WHERE Cod_Tipo='A') INSERT prest.operacion_tipo VALUES('A','Aplazamiento','S',3);
IF NOT EXISTS(SELECT 1 FROM prest.operacion_estado WHERE Cod_Estado='B') INSERT prest.operacion_estado VALUES('B','Borrador','S',1);
IF NOT EXISTS(SELECT 1 FROM prest.operacion_estado WHERE Cod_Estado='S') INSERT prest.operacion_estado VALUES('S','Simulada','S',2);
IF NOT EXISTS(SELECT 1 FROM prest.operacion_estado WHERE Cod_Estado='A') INSERT prest.operacion_estado VALUES('A','Aplicada','S',3);
IF NOT EXISTS(SELECT 1 FROM prest.operacion_estado WHERE Cod_Estado='X') INSERT prest.operacion_estado VALUES('X','Anulada','S',4);
IF NOT EXISTS(SELECT 1 FROM prest.gracia_tipo WHERE Cod_Gracia='N') INSERT prest.gracia_tipo VALUES('N','Sin periodo de gracia','N','N','S',1);
IF NOT EXISTS(SELECT 1 FROM prest.gracia_tipo WHERE Cod_Gracia='P') INSERT prest.gracia_tipo VALUES('P','Gracia parcial: paga interes','S','N','S',2);
IF NOT EXISTS(SELECT 1 FROM prest.gracia_tipo WHERE Cod_Gracia='T') INSERT prest.gracia_tipo VALUES('T','Gracia total con interes','S','S','S',3);
IF NOT EXISTS(SELECT 1 FROM prest.gracia_tipo WHERE Cod_Gracia='S') INSERT prest.gracia_tipo VALUES('S','Gracia total sin interes','N','S','S',4);
IF NOT EXISTS(SELECT 1 FROM prest.operacion_motivo WHERE Cod_Motivo='CAP') INSERT prest.operacion_motivo VALUES('CAP','Falta temporal de capacidad de pago','S',1);
IF NOT EXISTS(SELECT 1 FROM prest.operacion_motivo WHERE Cod_Motivo='CON') INSERT prest.operacion_motivo VALUES('CON','Consolidacion de varios prestamos','S',2);
IF NOT EXISTS(SELECT 1 FROM prest.operacion_motivo WHERE Cod_Motivo='FAM') INSERT prest.operacion_motivo VALUES('FAM','Acuerdo o apoyo familiar','S',3);
IF NOT EXISTS(SELECT 1 FROM prest.operacion_motivo WHERE Cod_Motivo='OTR') INSERT prest.operacion_motivo VALUES('OTR','Otro motivo autorizado','S',99);
IF NOT EXISTS(SELECT 1 FROM prest.alcance_tipo WHERE Cod_Alcance='E') INSERT prest.alcance_tipo VALUES('E','Toda la empresa','S',1);
IF NOT EXISTS(SELECT 1 FROM prest.alcance_tipo WHERE Cod_Alcance='S') INSERT prest.alcance_tipo VALUES('S','Solo establecimiento origen','S',2);
IF NOT EXISTS(SELECT 1 FROM prest.alcance_tipo WHERE Cod_Alcance='M') INSERT prest.alcance_tipo VALUES('M','Establecimientos seleccionados','S',3);

IF NOT EXISTS(SELECT 1 FROM prest.concepto WHERE Cod_Concepto='010')
 INSERT prest.concepto(Cod_Concepto,Nombre,Flag_Activo,OrdenVisual,FecCreacion,Usuario_Creacion)
 VALUES('010','REFINANCIAMIENTO','S',10,GETDATE(),1007);
GO

IF OBJECT_ID('prest.refinanciamiento','U') IS NULL
BEGIN
 CREATE TABLE prest.refinanciamiento
 (
  Id_Refinanciamiento INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  id_empresa INT NOT NULL,id_est_origen CHAR(2) NOT NULL,Alcance VARCHAR(1) NOT NULL DEFAULT('E'),
  Cod_TipAnex CHAR(1) NOT NULL,Cod_Anxo CHAR(6) NOT NULL,Cod_Tipo VARCHAR(1) NOT NULL,Cod_Motivo VARCHAR(3) NOT NULL,
  FechaCorte DATE NOT NULL,CapitalPendiente DECIMAL(18,2) NOT NULL,InteresVencido DECIMAL(18,2) NOT NULL,
  Mora DECIMAL(18,2) NOT NULL DEFAULT(0),CondonacionInteres DECIMAL(18,2) NOT NULL DEFAULT(0),CondonacionMora DECIMAL(18,2) NOT NULL DEFAULT(0),
  PagoInicial DECIMAL(18,2) NOT NULL DEFAULT(0),CapitalRefinanciado DECIMAL(18,2) NOT NULL,
  PorcInteresMensual DECIMAL(18,4) NOT NULL,FrecuenciaPago CHAR(1) NOT NULL,TipoModalidad CHAR(1) NOT NULL,
  FechaInicio DATE NOT NULL,FechaFin DATE NOT NULL,Cod_Gracia VARCHAR(1) NOT NULL,MesesGracia INT NOT NULL DEFAULT(0),
  InteresNuevo DECIMAL(18,2) NOT NULL,TotalNuevo DECIMAL(18,2) NOT NULL,NroCuotas INT NOT NULL,
  TasaReferencia DECIMAL(18,4) NULL,SuperaTasaReferencia VARCHAR(1) NOT NULL DEFAULT('N'),JustificacionTasa VARCHAR(250) NULL,
  Cod_Estado VARCHAR(1) NOT NULL DEFAULT('A'),Id_Prestamo_Nuevo INT NULL,Observacion VARCHAR(500) NULL,
  Usu_Creacion INT NULL,Fec_Creacion DATETIME NOT NULL DEFAULT(GETDATE()),Usu_Modif INT NULL,Fec_Modif DATETIME NULL
 );
END
GO
IF OBJECT_ID('prest.refinanciamiento_detalle','U') IS NULL
BEGIN
 CREATE TABLE prest.refinanciamiento_detalle
 (
  Id_Refinanciamiento INT NOT NULL,Id_Prestamo_Origen INT NOT NULL,
  CapitalPendiente DECIMAL(18,2) NOT NULL,InteresVencido DECIMAL(18,2) NOT NULL,InteresFuturoExcluido DECIMAL(18,2) NOT NULL,
  SaldoProgramado DECIMAL(18,2) NOT NULL,TotalPagado DECIMAL(18,2) NOT NULL,
  CONSTRAINT PK_refinanciamiento_detalle PRIMARY KEY(Id_Refinanciamiento,Id_Prestamo_Origen)
 );
END
IF OBJECT_ID('prest.prestamo_establecimiento_acceso','U') IS NULL
BEGIN
 CREATE TABLE prest.prestamo_establecimiento_acceso(Id_Prestamo INT NOT NULL,id_empresa INT NOT NULL,id_est CHAR(2) NOT NULL,Flg_Activo VARCHAR(1) NOT NULL DEFAULT('S'),CONSTRAINT PK_prestamo_est_acceso PRIMARY KEY(Id_Prestamo,id_empresa,id_est));
END
GO

IF OBJECT_ID('prest.contrato_plantilla','U') IS NULL
BEGIN
 CREATE TABLE prest.contrato_plantilla
 (
  Id_Plantilla INT IDENTITY(1,1) NOT NULL PRIMARY KEY,id_empresa INT NOT NULL,id_est CHAR(2) NULL,Cod_Tipo VARCHAR(1) NOT NULL,
  Nombre VARCHAR(120) NOT NULL,Version INT NOT NULL,ContenidoHtml VARCHAR(MAX) NOT NULL,CssImpresion VARCHAR(MAX) NULL,
  TextoMarcaAgua VARCHAR(80) NULL,Flg_Activo VARCHAR(1) NOT NULL DEFAULT('S'),Usu_Creacion INT NULL,Fec_Creacion DATETIME NOT NULL DEFAULT(GETDATE())
 );
END
IF OBJECT_ID('prest.contrato_generado','U') IS NULL
BEGIN
 CREATE TABLE prest.contrato_generado
 (
  Id_Contrato INT IDENTITY(1,1) NOT NULL PRIMARY KEY,id_empresa INT NOT NULL,id_est CHAR(2) NOT NULL,
  Id_Refinanciamiento INT NOT NULL,Id_Plantilla INT NOT NULL,ContenidoResuelto VARCHAR(MAX) NOT NULL,DatosJson VARCHAR(MAX) NULL,
  HashDocumento VARCHAR(128) NULL,Flg_Estado VARCHAR(1) NOT NULL DEFAULT('A'),Usu_Creacion INT NULL,Fec_Creacion DATETIME NOT NULL DEFAULT(GETDATE())
 );
END
GO

IF NOT EXISTS(SELECT 1 FROM prest.contrato_plantilla WHERE id_empresa=6 AND Cod_Tipo='F' AND Version=1)
INSERT prest.contrato_plantilla(id_empresa,id_est,Cod_Tipo,Nombre,Version,ContenidoHtml,CssImpresion,TextoMarcaAgua,Usu_Creacion)
VALUES(6,'4','F','Acuerdo de refinanciacion',1,
'<h1>ACUERDO DE REFINANCIACION</h1><p>Conste por el presente documento el acuerdo celebrado entre {{EMPRESA}} y {{CLIENTE}}, identificado con {{DOCUMENTO}}.</p><p>Las partes acuerdan consolidar las obligaciones detalladas por un capital refinanciado de {{CAPITAL_REFINANCIADO}}, bajo una tasa mensual de {{TASA_MENSUAL}} y el cronograma adjunto.</p><p>Fecha: {{FECHA_CONTRATO}}</p><div class="firmas"><p>____________________<br>Acreedor</p><p>____________________<br>Cliente</p></div>',
'body{font-family:Arial;font-size:11pt;color:#1f2937}h1{text-align:center;font-size:16pt}.firmas{display:flex;justify-content:space-between;margin-top:70px}',
'ACUERDO DE PAGO',1007);
GO

IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prest.prestamo') AND name='IX_prestamo_empresa_cliente')
 CREATE INDEX IX_prestamo_empresa_cliente ON prest.prestamo(id_empresa,id_est_origen,Cod_TipAnex,Cod_Anxo,Flg_Estado);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prest.refinanciamiento') AND name='IX_refinanciamiento_empresa_cliente')
 CREATE INDEX IX_refinanciamiento_empresa_cliente ON prest.refinanciamiento(id_empresa,id_est_origen,Cod_TipAnex,Cod_Anxo,Cod_Estado);
GO
