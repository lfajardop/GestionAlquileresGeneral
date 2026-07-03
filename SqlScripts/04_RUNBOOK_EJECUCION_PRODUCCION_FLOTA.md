# Runbook Ejecución Producción Flota

## Objetivo
Aplicar en producción `DB_9FA64E_bdgas` el modelo nuevo de Flota en el orden correcto, con verificaciones antes y después de cada etapa, y recién al final publicar backend/UI.

## Regla principal
- No ejecutar nada fuera de `DB_9FA64E_bdgas`.
- No continuar al siguiente paso si el actual falla.
- Registrar todo en [BITACORA_VENTANA_MANTENIMIENTO_FLOTA.md](/E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/BITACORA_VENTANA_MANTENIMIENTO_FLOTA.md).

## Archivos a usar en orden
1. [00_PRECHECK_GENERAL_PRODUCCION.sql](/E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/00_PRECHECK_GENERAL_PRODUCCION.sql)
2. [20260703_flota_alquiler_base.sql](/E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/20260703_flota_alquiler_base.sql)
3. [01_POSTCHECK_20260703.sql](/E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/01_POSTCHECK_20260703.sql)
4. [20260704_flota_recibos_calendario.sql](/E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/20260704_flota_recibos_calendario.sql)
5. [02_POSTCHECK_20260704.sql](/E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/02_POSTCHECK_20260704.sql)
6. [20260705_flota_correccion_administrativa.sql](/E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/20260705_flota_correccion_administrativa.sql)
7. [03_POSTCHECK_20260705.sql](/E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/03_POSTCHECK_20260705.sql)
8. Deploy backend/UI
9. [BITACORA_VENTANA_MANTENIMIENTO_FLOTA.md](/E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/BITACORA_VENTANA_MANTENIMIENTO_FLOTA.md)

## Variables a completar antes de la ventana
- `<SERVIDOR>`
- `<USUARIO>`
- `<PASSWORD>`
- `<CARPETA_LOGS>`
- `<RUTA_SCRIPT>`

Ejemplo de carpeta de logs:
- `C:\Logs\Flota_Produccion_YYYYMMDD`

## Crear carpeta de logs antes de empezar
```powershell
New-Item -ItemType Directory -Force -Path "<CARPETA_LOGS>"
```

## Comandos sugeridos con sqlcmd

### Opción A: autenticación integrada
```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -E -i "<SCRIPT>" -o "<LOG>" -b
```

### Opción B: autenticación SQL
```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -U <USUARIO> -P <PASSWORD> -i "<SCRIPT>" -o "<LOG>" -b
```

## Qué hace `-b`
- `-b` hace que `sqlcmd` retorne error si el script falla.
- Esto permite cortar la ejecución automática o manual cuando aparece un error SQL real.
- Debe mantenerse en todos los comandos de producción.

## Secuencia operativa exacta

### 1. Precheck general
Ejecutar:
```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -E -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\00_PRECHECK_GENERAL_PRODUCCION.sql" -o "<CARPETA_LOGS>\00_PRECHECK_GENERAL_PRODUCCION.log" -b
```

o

```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -U <USUARIO> -P <PASSWORD> -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\00_PRECHECK_GENERAL_PRODUCCION.sql" -o "<CARPETA_LOGS>\00_PRECHECK_GENERAL_PRODUCCION.log" -b
```

Revisar resultado antes de continuar.

Nota:
- En `00_PRECHECK_GENERAL_PRODUCCION.sql` es esperado que todavía no existan:
  - `flota.contrato`
  - `flota.operacion_dia`
  - `flota.ReciboAlquiler`
  - `flota.PagoReciboAlquiler`
- Eso no es bloqueante antes de `20260703` y `20260704`; forma parte del estado esperado de producción previo al pase.

### 2. Ejecutar 20260703
```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -E -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\20260703_flota_alquiler_base.sql" -o "<CARPETA_LOGS>\20260703_flota_alquiler_base.log" -b
```

```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -U <USUARIO> -P <PASSWORD> -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\20260703_flota_alquiler_base.sql" -o "<CARPETA_LOGS>\20260703_flota_alquiler_base.log" -b
```

### 3. Postcheck 20260703
```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -E -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\01_POSTCHECK_20260703.sql" -o "<CARPETA_LOGS>\01_POSTCHECK_20260703.log" -b
```

```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -U <USUARIO> -P <PASSWORD> -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\01_POSTCHECK_20260703.sql" -o "<CARPETA_LOGS>\01_POSTCHECK_20260703.log" -b
```

### 4. Ejecutar 20260704
```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -E -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\20260704_flota_recibos_calendario.sql" -o "<CARPETA_LOGS>\20260704_flota_recibos_calendario.log" -b
```

```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -U <USUARIO> -P <PASSWORD> -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\20260704_flota_recibos_calendario.sql" -o "<CARPETA_LOGS>\20260704_flota_recibos_calendario.log" -b
```

### 5. Postcheck 20260704
```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -E -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\02_POSTCHECK_20260704.sql" -o "<CARPETA_LOGS>\02_POSTCHECK_20260704.log" -b
```

```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -U <USUARIO> -P <PASSWORD> -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\02_POSTCHECK_20260704.sql" -o "<CARPETA_LOGS>\02_POSTCHECK_20260704.log" -b
```

### 6. Ejecutar 20260705
```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -E -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\20260705_flota_correccion_administrativa.sql" -o "<CARPETA_LOGS>\20260705_flota_correccion_administrativa.log" -b
```

```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -U <USUARIO> -P <PASSWORD> -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\20260705_flota_correccion_administrativa.sql" -o "<CARPETA_LOGS>\20260705_flota_correccion_administrativa.log" -b
```

### 7. Postcheck 20260705
```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -E -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\03_POSTCHECK_20260705.sql" -o "<CARPETA_LOGS>\03_POSTCHECK_20260705.log" -b
```

```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -U <USUARIO> -P <PASSWORD> -i "E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\SqlScripts\03_POSTCHECK_20260705.sql" -o "<CARPETA_LOGS>\03_POSTCHECK_20260705.log" -b
```

### 8. Deploy backend/UI
- Solo si todos los pasos anteriores quedaron en estado aceptable.

### 9. Completar bitácora
- Registrar cada hora, resultado, hallazgo, error y decisión.

## Reglas GO / NO-GO

### NO-GO inmediato
- Si `00_PRECHECK_GENERAL_PRODUCCION.sql` devuelve `ALERTA` crítica o `FALTA` crítica: detener.
- No considerar bloqueante en `00_PRECHECK_GENERAL_PRODUCCION.sql` que todavía no existan:
  - `flota.contrato`
  - `flota.operacion_dia`
  - `flota.ReciboAlquiler`
  - `flota.PagoReciboAlquiler`
- Ese es el estado esperado antes del pase.
- Si `20260703_flota_alquiler_base.sql` falla: detener, no ejecutar `20260704`.
- Si `01_POSTCHECK_20260703.sql` tiene `FALTA` crítica: detener.
- Si `20260704_flota_recibos_calendario.sql` falla: detener, no ejecutar `20260705`.
- Si `02_POSTCHECK_20260704.sql` tiene `FALTA` crítica: detener.
- Si `20260705_flota_correccion_administrativa.sql` falla: detener, no publicar app.
- Si `03_POSTCHECK_20260705.sql` tiene `FALTA` crítica: detener, no publicar app.

### GO
- Solo publicar app si todos los SQL y postchecks pasan.
- El smoke test debe salir sin errores críticos antes de cerrar la ventana.

## Revisión manual obligatoria de resultados
Abrir cada log y buscar:
- `Msg`
- `Level`
- `FALTA`
- `ALERTA`
- `Invalid object name`
- `Cannot`
- `failed`

Puntos de lectura:
- confirmar que `sqlcmd` no cortó por error
- confirmar que el postcheck no marcó faltantes críticos
- confirmar que no hay errores de compilación o dependencias

## Evidencias a guardar
- Logs SQL de cada paso
- Captura o evidencia del backup
- Resultado de cada postcheck
- Captura del smoke test
- Bitácora completada

## Advertencia especial
El mayor riesgo es [20260703_flota_alquiler_base.sql](/E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/20260703_flota_alquiler_base.sql) porque:
- altera `flota.vehiculo`
- altera `flota.chofer`
- agrega `Id_Chofer INT IDENTITY` si no existe

Si el precheck marca alerta sobre `flota.chofer` con datos e `Id_Chofer` faltante:
- no continuar sin validación explícita
- no asumir que el ALTER será inocuo en producción

## Criterio final antes de deploy
- Backup confirmado
- Restore confirmado
- Precheck general sin bloqueantes
- `20260703` aplicado y validado
- `20260704` aplicado y validado
- `20260705` aplicado y validado
- Logs revisados
- Bitácora al día
- Recién entonces publicar backend/UI
