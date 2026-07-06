/*
CONSULTA DE CONFIRMACION DE IDS MAESTROS FLOTA PILOTO

Uso:
- Ejecutar solo despues de crear vehiculo, chofer y contrato desde la UI temporal de /Flota
- Sirve para identificar:
  - IdVehiculo real
  - IdChofer real
  - IdContrato real
- No modifica datos
- Solo lectura
*/

DECLARE @IdEmpresa INT = 6;
DECLARE @IdEst CHAR(2) = '4';

DECLARE @Placa VARCHAR(10) = 'COMPLETAR';
DECLARE @DocumentoChofer VARCHAR(20) = 'COMPLETAR';
DECLARE @TelefonoChofer VARCHAR(20) = '949222682';

SELECT
    DB_NAME() AS BaseActual,
    @IdEmpresa AS IdEmpresa,
    @IdEst AS IdEst,
    @Placa AS PlacaBuscada,
    @DocumentoChofer AS DocumentoBuscado,
    @TelefonoChofer AS TelefonoBuscado;

-- 1. Vehiculo por placa
SELECT TOP 10
    v.Id_Vehiculo,
    v.Placa,
    v.MarcaTexto AS Marca,
    v.ModeloTexto AS Modelo,
    v.flg_activo AS Flg_Estado
FROM flota.vehiculo v
WHERE v.id_empresa = @IdEmpresa
  AND RTRIM(ISNULL(v.id_est, '')) = RTRIM(@IdEst)
  AND v.Placa = @Placa
ORDER BY v.Id_Vehiculo DESC;

-- 2. Chofer por documento o telefono
SELECT TOP 10
    ch.Id_Chofer,
    ch.Nombres,
    ch.Documento,
    ch.Telefono,
    ch.Activo AS Flg_Estado
FROM flota.chofer ch
WHERE ch.id_empresa = @IdEmpresa
  AND RTRIM(ISNULL(ch.id_est, '')) = RTRIM(@IdEst)
  AND (
        ch.Documento = @DocumentoChofer
        OR ch.Telefono = @TelefonoChofer
      )
ORDER BY ch.Id_Chofer DESC;

-- 3. Contrato mas reciente del vehiculo/chofer
SELECT TOP 10
    c.Id_Contrato,
    c.Numero,
    c.Id_Vehiculo,
    v.Placa,
    c.Id_Chofer,
    ch.Nombres,
    ch.Documento,
    ch.Telefono,
    c.Cod_Modalidad,
    c.Cod_Periodicidad,
    c.FechaInicio,
    c.FechaFin,
    c.TarifaDia,
    c.Flg_Estado
FROM flota.contrato c
LEFT JOIN flota.vehiculo v
    ON v.Id_Vehiculo = c.Id_Vehiculo
LEFT JOIN flota.chofer ch
    ON ch.Id_Chofer = c.Id_Chofer
WHERE c.id_empresa = @IdEmpresa
  AND RTRIM(ISNULL(c.id_est, '')) = RTRIM(@IdEst)
  AND (
        v.Placa = @Placa
        OR ch.Documento = @DocumentoChofer
        OR ch.Telefono = @TelefonoChofer
      )
ORDER BY c.Id_Contrato DESC;

-- 4. Resumen recomendado
SELECT
    (
        SELECT TOP 1 v.Id_Vehiculo
        FROM flota.vehiculo v
        WHERE v.id_empresa = @IdEmpresa
          AND RTRIM(ISNULL(v.id_est, '')) = RTRIM(@IdEst)
          AND v.Placa = @Placa
        ORDER BY v.Id_Vehiculo DESC
    ) AS IdVehiculoRecomendado,
    (
        SELECT TOP 1 ch.Id_Chofer
        FROM flota.chofer ch
        WHERE ch.id_empresa = @IdEmpresa
          AND RTRIM(ISNULL(ch.id_est, '')) = RTRIM(@IdEst)
          AND (
                ch.Documento = @DocumentoChofer
                OR ch.Telefono = @TelefonoChofer
              )
        ORDER BY ch.Id_Chofer DESC
    ) AS IdChoferRecomendado,
    (
        SELECT TOP 1 c.Id_Contrato
        FROM flota.contrato c
        LEFT JOIN flota.vehiculo v
            ON v.Id_Vehiculo = c.Id_Vehiculo
        LEFT JOIN flota.chofer ch
            ON ch.Id_Chofer = c.Id_Chofer
        WHERE c.id_empresa = @IdEmpresa
          AND RTRIM(ISNULL(c.id_est, '')) = RTRIM(@IdEst)
          AND (
                v.Placa = @Placa
                OR ch.Documento = @DocumentoChofer
                OR ch.Telefono = @TelefonoChofer
              )
        ORDER BY c.Id_Contrato DESC
    ) AS IdContratoRecomendado;
