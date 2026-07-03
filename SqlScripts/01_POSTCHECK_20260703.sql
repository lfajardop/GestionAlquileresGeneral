SET NOCOUNT ON;

DECLARE @Resultado TABLE(
    Etapa VARCHAR(50),
    Validacion VARCHAR(200),
    Resultado VARCHAR(20),
    Detalle VARCHAR(500)
);

INSERT INTO @Resultado
VALUES
('POSTCHECK 20260703', 'Tabla flota.modalidad', CASE WHEN OBJECT_ID('flota.modalidad', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.modalidad', 'U') IS NOT NULL THEN 'Existe flota.modalidad' ELSE 'No existe flota.modalidad' END),
('POSTCHECK 20260703', 'Tabla flota.motivo_dia', CASE WHEN OBJECT_ID('flota.motivo_dia', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.motivo_dia', 'U') IS NOT NULL THEN 'Existe flota.motivo_dia' ELSE 'No existe flota.motivo_dia' END),
('POSTCHECK 20260703', 'Tabla flota.contrato', CASE WHEN OBJECT_ID('flota.contrato', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.contrato', 'U') IS NOT NULL THEN 'Existe flota.contrato' ELSE 'No existe flota.contrato' END),
('POSTCHECK 20260703', 'Tabla flota.operacion_dia', CASE WHEN OBJECT_ID('flota.operacion_dia', 'U') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.operacion_dia', 'U') IS NOT NULL THEN 'Existe flota.operacion_dia' ELSE 'No existe flota.operacion_dia' END);

IF OBJECT_ID('flota.modalidad', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260703', 'Catalogo modalidad D', 'FALTA', 'No existe flota.modalidad');
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260703', 'Catalogo modalidad L', 'FALTA', 'No existe flota.modalidad');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT 'POSTCHECK 20260703', 'Catalogo modalidad D',
           CASE WHEN EXISTS (SELECT 1 FROM flota.modalidad WHERE Cod_Modalidad = 'D') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.modalidad WHERE Cod_Modalidad = 'D') THEN 'Existe modalidad D' ELSE 'Falta modalidad D' END
    UNION ALL
    SELECT 'POSTCHECK 20260703', 'Catalogo modalidad L',
           CASE WHEN EXISTS (SELECT 1 FROM flota.modalidad WHERE Cod_Modalidad = 'L') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.modalidad WHERE Cod_Modalidad = 'L') THEN 'Existe modalidad L' ELSE 'Falta modalidad L' END;
END;

IF OBJECT_ID('flota.motivo_dia', 'U') IS NULL
BEGIN
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260703', 'Motivo TRA', 'FALTA', 'No existe flota.motivo_dia');
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260703', 'Motivo DES', 'FALTA', 'No existe flota.motivo_dia');
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260703', 'Motivo MAN', 'FALTA', 'No existe flota.motivo_dia');
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260703', 'Motivo AVE', 'FALTA', 'No existe flota.motivo_dia');
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260703', 'Motivo FAL', 'FALTA', 'No existe flota.motivo_dia');
    INSERT INTO @Resultado VALUES ('POSTCHECK 20260703', 'Motivo OTR', 'FALTA', 'No existe flota.motivo_dia');
END
ELSE
BEGIN
    INSERT INTO @Resultado
    SELECT 'POSTCHECK 20260703', 'Motivo TRA',
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'TRA') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'TRA') THEN 'Existe motivo TRA' ELSE 'Falta motivo TRA' END
    UNION ALL
    SELECT 'POSTCHECK 20260703', 'Motivo DES',
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'DES') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'DES') THEN 'Existe motivo DES' ELSE 'Falta motivo DES' END
    UNION ALL
    SELECT 'POSTCHECK 20260703', 'Motivo MAN',
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'MAN') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'MAN') THEN 'Existe motivo MAN' ELSE 'Falta motivo MAN' END
    UNION ALL
    SELECT 'POSTCHECK 20260703', 'Motivo AVE',
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'AVE') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'AVE') THEN 'Existe motivo AVE' ELSE 'Falta motivo AVE' END
    UNION ALL
    SELECT 'POSTCHECK 20260703', 'Motivo FAL',
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'FAL') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'FAL') THEN 'Existe motivo FAL' ELSE 'Falta motivo FAL' END
    UNION ALL
    SELECT 'POSTCHECK 20260703', 'Motivo OTR',
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'OTR') THEN 'OK' ELSE 'FALTA' END,
           CASE WHEN EXISTS (SELECT 1 FROM flota.motivo_dia WHERE Cod_Motivo = 'OTR') THEN 'Existe motivo OTR' ELSE 'Falta motivo OTR' END;
END;

INSERT INTO @Resultado
VALUES
('POSTCHECK 20260703', 'Columna flota.vehiculo.id_empresa', CASE WHEN COL_LENGTH('flota.vehiculo', 'id_empresa') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'id_empresa') IS NOT NULL THEN 'Existe columna id_empresa' ELSE 'Falta columna id_empresa' END),
('POSTCHECK 20260703', 'Columna flota.vehiculo.id_est', CASE WHEN COL_LENGTH('flota.vehiculo', 'id_est') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'id_est') IS NOT NULL THEN 'Existe columna id_est' ELSE 'Falta columna id_est' END),
('POSTCHECK 20260703', 'Columna flota.vehiculo.MarcaTexto', CASE WHEN COL_LENGTH('flota.vehiculo', 'MarcaTexto') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'MarcaTexto') IS NOT NULL THEN 'Existe columna MarcaTexto' ELSE 'Falta columna MarcaTexto' END),
('POSTCHECK 20260703', 'Columna flota.vehiculo.ModeloTexto', CASE WHEN COL_LENGTH('flota.vehiculo', 'ModeloTexto') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'ModeloTexto') IS NOT NULL THEN 'Existe columna ModeloTexto' ELSE 'Falta columna ModeloTexto' END),
('POSTCHECK 20260703', 'Columna flota.vehiculo.ColorTexto', CASE WHEN COL_LENGTH('flota.vehiculo', 'ColorTexto') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'ColorTexto') IS NOT NULL THEN 'Existe columna ColorTexto' ELSE 'Falta columna ColorTexto' END),
('POSTCHECK 20260703', 'Columna flota.vehiculo.GalonesTanque', CASE WHEN COL_LENGTH('flota.vehiculo', 'GalonesTanque') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'GalonesTanque') IS NOT NULL THEN 'Existe columna GalonesTanque' ELSE 'Falta columna GalonesTanque' END),
('POSTCHECK 20260703', 'Columna flota.vehiculo.PrecioGalon', CASE WHEN COL_LENGTH('flota.vehiculo', 'PrecioGalon') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'PrecioGalon') IS NOT NULL THEN 'Existe columna PrecioGalon' ELSE 'Falta columna PrecioGalon' END),
('POSTCHECK 20260703', 'Columna flota.vehiculo.RendimientoTanqueKm', CASE WHEN COL_LENGTH('flota.vehiculo', 'RendimientoTanqueKm') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'RendimientoTanqueKm') IS NOT NULL THEN 'Existe columna RendimientoTanqueKm' ELSE 'Falta columna RendimientoTanqueKm' END),
('POSTCHECK 20260703', 'Columna flota.vehiculo.Flg_Compartido', CASE WHEN COL_LENGTH('flota.vehiculo', 'Flg_Compartido') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.vehiculo', 'Flg_Compartido') IS NOT NULL THEN 'Existe columna Flg_Compartido' ELSE 'Falta columna Flg_Compartido' END),
('POSTCHECK 20260703', 'Columna flota.chofer.Id_Chofer', CASE WHEN COL_LENGTH('flota.chofer', 'Id_Chofer') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.chofer', 'Id_Chofer') IS NOT NULL THEN 'Existe columna Id_Chofer' ELSE 'Falta columna Id_Chofer' END),
('POSTCHECK 20260703', 'Columna flota.chofer.id_empresa', CASE WHEN COL_LENGTH('flota.chofer', 'id_empresa') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.chofer', 'id_empresa') IS NOT NULL THEN 'Existe columna id_empresa' ELSE 'Falta columna id_empresa' END),
('POSTCHECK 20260703', 'Columna flota.chofer.id_est', CASE WHEN COL_LENGTH('flota.chofer', 'id_est') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.chofer', 'id_est') IS NOT NULL THEN 'Existe columna id_est' ELSE 'Falta columna id_est' END),
('POSTCHECK 20260703', 'Columna flota.chofer.Nombres', CASE WHEN COL_LENGTH('flota.chofer', 'Nombres') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.chofer', 'Nombres') IS NOT NULL THEN 'Existe columna Nombres' ELSE 'Falta columna Nombres' END),
('POSTCHECK 20260703', 'Columna flota.chofer.Documento', CASE WHEN COL_LENGTH('flota.chofer', 'Documento') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.chofer', 'Documento') IS NOT NULL THEN 'Existe columna Documento' ELSE 'Falta columna Documento' END),
('POSTCHECK 20260703', 'Columna flota.chofer.Telefono', CASE WHEN COL_LENGTH('flota.chofer', 'Telefono') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN COL_LENGTH('flota.chofer', 'Telefono') IS NOT NULL THEN 'Existe columna Telefono' ELSE 'Falta columna Telefono' END);

INSERT INTO @Resultado
SELECT
    'POSTCHECK 20260703',
    'Indice UX_flota_chofer_id',
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.chofer', 'U') AND name = 'UX_flota_chofer_id') THEN 'OK' ELSE 'FALTA' END,
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('flota.chofer', 'U') AND name = 'UX_flota_chofer_id') THEN 'Existe indice UX_flota_chofer_id' ELSE 'Falta indice UX_flota_chofer_id' END;

INSERT INTO @Resultado
VALUES
('POSTCHECK 20260703', 'SP flota.p_catalogos', CASE WHEN OBJECT_ID('flota.p_catalogos', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_catalogos', 'P') IS NOT NULL THEN 'Existe flota.p_catalogos' ELSE 'Falta flota.p_catalogos' END),
('POSTCHECK 20260703', 'SP flota.p_vehiculo_crear', CASE WHEN OBJECT_ID('flota.p_vehiculo_crear', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_vehiculo_crear', 'P') IS NOT NULL THEN 'Existe flota.p_vehiculo_crear' ELSE 'Falta flota.p_vehiculo_crear' END),
('POSTCHECK 20260703', 'SP flota.p_chofer_crear', CASE WHEN OBJECT_ID('flota.p_chofer_crear', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_chofer_crear', 'P') IS NOT NULL THEN 'Existe flota.p_chofer_crear' ELSE 'Falta flota.p_chofer_crear' END),
('POSTCHECK 20260703', 'SP flota.p_contrato_crear', CASE WHEN OBJECT_ID('flota.p_contrato_crear', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_contrato_crear', 'P') IS NOT NULL THEN 'Existe flota.p_contrato_crear' ELSE 'Falta flota.p_contrato_crear' END),
('POSTCHECK 20260703', 'SP flota.p_dashboard', CASE WHEN OBJECT_ID('flota.p_dashboard', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_dashboard', 'P') IS NOT NULL THEN 'Existe flota.p_dashboard' ELSE 'Falta flota.p_dashboard' END),
('POSTCHECK 20260703', 'SP flota.p_trabajo_dia_guardar', CASE WHEN OBJECT_ID('flota.p_trabajo_dia_guardar', 'P') IS NOT NULL THEN 'OK' ELSE 'FALTA' END, CASE WHEN OBJECT_ID('flota.p_trabajo_dia_guardar', 'P') IS NOT NULL THEN 'Existe flota.p_trabajo_dia_guardar' ELSE 'Falta flota.p_trabajo_dia_guardar' END);

SELECT Etapa, Validacion, Resultado, Detalle
FROM @Resultado
ORDER BY
    CASE Resultado WHEN 'FALTA' THEN 1 WHEN 'ALERTA' THEN 2 WHEN 'OK' THEN 3 ELSE 4 END,
    Validacion;
