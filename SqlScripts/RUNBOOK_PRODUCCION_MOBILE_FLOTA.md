# RUNBOOK Produccion Mobile Flota

## Objetivo
Publicar el piloto mobile del modulo Flota para que el chofer registre desde produccion:
- inicio
- fin
- combustible
- pagos declarados
- adjuntos y vouchers

Piloto operativo solamente. No incluye liquidacion final.

## Reglas del piloto
- No tocar caja/cobranza.
- No aplicar `PagoContrato` a `ReciboAlquiler`.
- No liquidar combustible.
- No usar PIN `123456` en produccion.
- Todo paso debe quedar con log y bitacora.

## Alcance incluido
- Login mobile
- Cookie persistente 30 dias
- Contrato fijo por sesion
- Inicio/fin operacion
- Combustible separado
- Pago declarado
- Edicion de pago pendiente
- Upload recibo GLP / voucher
- Bloqueo de contrato ajeno

## Alcance no incluido
- Liquidacion combustible
- Aplicacion de `PagoContrato` a recibos
- Caja/cobranza
- `PagoContratoAplicacion`
- CRUD maestros completos
- Bandeja admin `PagoContrato`

## Base objetivo
- Produccion: `DB_9FA64E_bdgas`

## Orden SQL produccion
Aplicar sobre `DB_9FA64E_bdgas` en este orden:

1. [20260706_flota_fase2_mobile_captura_PROD.sql](E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/PROD/20260706_flota_fase2_mobile_captura_PROD.sql)
2. [20260706A_flota_pagocontrato_filtros_admin_PROD.sql](E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/PROD/20260706A_flota_pagocontrato_filtros_admin_PROD.sql)
3. [20260707_flota_usuario_mobile_PROD.sql](E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/PROD/20260707_flota_usuario_mobile_PROD.sql)
4. [20260707B_flota_combustible_operacion_PROD.sql](E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/PROD/20260707B_flota_combustible_operacion_PROD.sql)
5. [20260707C_flota_operacion_dia_horas_PROD.sql](E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/PROD/20260707C_flota_operacion_dia_horas_PROD.sql)
6. [20260707D_flota_pagocontrato_edicion_mobile_PROD.sql](E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/PROD/20260707D_flota_pagocontrato_edicion_mobile_PROD.sql)
7. `SEED_USUARIO_MOBILE_PRODUCCION.sql` solo cuando se completen datos reales y se genere hash/salt compatible

## Alta de maestros del piloto
Flujo principal:
- Crear vehiculo, chofer y contrato desde la UI/admin del sistema, si la pantalla existe y funciona correctamente.
- Confirmar luego los IDs reales generados:
  - `IdVehiculo`
  - `IdChofer`
  - `IdContrato`

Plan B:
- Usar [SEED_FLOTA_PILOTO_MAESTROS_PRODUCCION_TEMPLATE.sql](E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/PROD/SEED_FLOTA_PILOTO_MAESTROS_PRODUCCION_TEMPLATE.sql) solo si la UI no existe, falla o se necesita carga controlada urgente.

Advertencias:
- No ejecutar `SEED_USUARIO_MOBILE_PRODUCCION.sql` hasta que existan `IdVehiculo`, `IdChofer` e `IdContrato` reales.
- No inventar `IdChofer` ni `IdContrato`.
- El usuario mobile depende de un contrato real.

## Advertencias previas
- `20260707B` y `20260707C` existen como archivos finales.
- Antes del pase, revisar que esos dos scripts fueron los mismos usados y validados en desarrollo.
- Si algun script productivo necesita adaptacion final a `DB_9FA64E_bdgas`, detener el pase hasta cerrar esa revision.

## Precheck obligatorio
Ejecutar primero:
- [PRECHECK_PRODUCCION_MOBILE_FLOTA.sql](E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/PRECHECK_PRODUCCION_MOBILE_FLOTA.sql)

Si el precheck devuelve `FALTA` o `ALERTA` critica, no continuar.

## Comandos sugeridos sqlcmd
Autenticacion SQL:

```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -U <USUARIO> -P <PASSWORD> -b -i "SqlScripts\<script>.sql" -o "Logs\<script>.log"
```

Autenticacion Windows:

```powershell
sqlcmd -S <SERVIDOR> -d DB_9FA64E_bdgas -E -b -i "SqlScripts\<script>.sql" -o "Logs\<script>.log"
```

Crear carpeta de logs:

```powershell
New-Item -ItemType Directory -Force -Path "<CARPETA_LOGS>"
```

Notas:
- `-b` hace que `sqlcmd` termine con error si el script falla.
- Guardar un log por script y otro para el precheck.

## Backup obligatorio antes de SQL
Registrar en bitacora:
- Base: `DB_9FA64E_bdgas`
- Archivo backup
- Fecha/hora
- Responsable
- Ubicacion
- Tamano
- Si se pudo verificar o no

No ejecutar SQL si no existe backup reciente confirmado.

## Secuencia operativa recomendada
1. Confirmar backup.
2. Ejecutar precheck.
3. Revisar log del precheck.
4. Ejecutar SQL 20260706.
5. Revisar log.
6. Ejecutar SQL 20260706A.
7. Revisar log.
8. Ejecutar SQL 20260707.
9. Revisar log.
10. Ejecutar SQL 20260707B.
11. Revisar log.
12. Ejecutar SQL 20260707C.
13. Revisar log.
14. Ejecutar SQL 20260707D.
15. Revisar log.
16. Publicar backend/UI.
17. Verificar que `/Flota` carga.
18. Confirmar carpeta `wwwroot/uploads/flota` y permisos.
19. Crear vehiculo, chofer y contrato desde UI/admin si existe y funciona.
20. Solo si la UI no existe o falla, evaluar el plan B con `SEED_FLOTA_PILOTO_MAESTROS_PRODUCCION_TEMPLATE.sql`.
21. Ejecutar [CONSULTA_IDS_MAESTROS_FLOTA_PILOTO.sql](E:/LEFP/Proyectos/ControlAlquileres/GestionDeAlquileres/SqlScripts/PROD/CONSULTA_IDS_MAESTROS_FLOTA_PILOTO.sql).
22. Completar `@Placa`, `@DocumentoChofer` y confirmar `@TelefonoChofer`.
23. Confirmar `IdVehiculo`, `IdChofer` e `IdContrato` reales.
24. Completar `SEED_USUARIO_MOBILE_PRODUCCION.sql`.
25. Ejecutar seed del usuario mobile.
26. Probar `/Flota/MobileLogin`.
27. Ejecutar smoke test mobile.
28. Registrar GO / NO-GO.

Uso de la consulta de confirmacion:
- completar `@Placa`
- completar `@DocumentoChofer`
- confirmar `@TelefonoChofer`
- obtener `IdVehiculo`, `IdChofer` e `IdContrato` reales

Advertencia:
- No continuar con `SEED_USUARIO_MOBILE_PRODUCCION.sql` si la consulta no devuelve exactamente los maestros esperados.

## Deploy app
Pasos sugeridos:
1. Detener app si aplica.
2. Publicar paquete actualizado.
3. Confirmar carpeta `wwwroot/uploads/flota`.
4. Confirmar permisos de escritura para el proceso web.
5. Confirmar HTTPS.
6. Confirmar cookie `Secure` en produccion si aplica.
7. Levantar app.
8. Revisar logs de aplicacion.

## Pruebas post deploy
Con usuario real:
1. Abrir `/Flota/MobileLogin`
2. Hacer login
3. Abrir `/Flota/EstacionMobile`
4. Confirmar contrato fijo
5. Guardar inicio
6. Guardar fin
7. Registrar combustible
8. Subir recibo GLP
9. Registrar pago declarado
10. Subir voucher
11. Editar pago pendiente
12. Logout
13. Intentar contrato ajeno y confirmar bloqueo

## GO / NO-GO
### GO
- Backup confirmado
- Precheck sin bloqueantes
- SQL sin errores
- App levanta
- Login mobile funciona
- Contrato fijo funciona
- Uploads funcionan
- No se rompe `AdminCalendario`
- Para seed mobile:
  - existe vehiculo real
  - existe chofer real
  - existe contrato real
  - se conoce `IdContrato`
  - se conoce `IdChofer`
  - `PasswordHash` y `PasswordSalt` ya fueron generados fuera del SQL

### NO-GO
- Falla cualquier script SQL
- Falla login
- Falla upload
- App no levanta
- Contrato ajeno no bloquea
- Se rompe `AdminCalendario`
- Aparece error 500
- `flota.vehiculo` esta vacio
- `flota.chofer` esta vacio
- `flota.contrato` esta vacio
- `PasswordHash` o `PasswordSalt` estan incompletos

## Rollback
### App
- Restaurar paquete anterior
- Reiniciar app/pool

### Base de datos
- No borrar objetos manualmente en caliente
- Evaluar reversa controlada solo si existe y esta validada
- Si el fallo es critico, restaurar backup segun procedimiento del hosting

## Riesgos operativos del piloto
- Aun no liquida combustible
- Aun no aplica pagos a recibos
- Admin debe revisar pagos declarados
- Admin debe revisar dias/horas si hay error
- CRUD maestros pendiente
- Bandeja admin `PagoContrato` pendiente

## Fase futura documentada
La liquidacion de combustible queda para Fase 4 y debera considerar:
- combustible inicial/entrega
- combustible cargado por chofer
- combustible cargado por dueno
- km recorrido
- consumo esperado por km
- diferencia
- saldo a favor o en contra

No implementar en este piloto.

