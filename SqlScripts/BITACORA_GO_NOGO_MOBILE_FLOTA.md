# Bitacora GO / NO-GO Mobile Flota

## Datos generales
- Fecha/hora inicio:
- Responsable:
- Base objetivo: `DB_9FA64E_bdgas`
- Backup confirmado: si
- Archivo backup: `DB_9FA64E_bdgas_7_5_2026_13.bak`
- Fecha/hora backup: `2026-07-05 15:12:15` (LastWriteTime local)
- Ubicacion backup: `E:\LEFP\Proyectos\ControlAlquileres\GestionDeAlquileres\Docs\Backup`
- Tamano backup: `176275456 bytes`
- Verificado: no

## Ejecucion SQL
| Script | Resultado | Log | Observaciones |
|---|---|---|---|
| PRECHECK_PRODUCCION_MOBILE_FLOTA.sql | OK | `Logs\MobileProduccion_20260705\PRECHECK_PRODUCCION_MOBILE_FLOTA.log` | DB correcta, SQL Server 2014 SP3, schema/tablas base/formaPago OK. Solo hay faltas esperadas de Fase 2. |
| 20260706_flota_fase2_mobile_captura_PROD.sql | OK | `Logs\MobileProduccion_20260705\20260706_flota_fase2_mobile_captura_PROD.log` | ExitCode 0. Sin Msg/Level/State. El estado final se confirmo con precheck post-scripts. |
| 20260706A_flota_pagocontrato_filtros_admin_PROD.sql | OK | `Logs\MobileProduccion_20260705\20260706A_flota_pagocontrato_filtros_admin_PROD.log` | ExitCode 0. Sin errores en log. |
| 20260707_flota_usuario_mobile_PROD.sql | OK | `Logs\MobileProduccion_20260705\20260707_flota_usuario_mobile_PROD.log` | ExitCode 0. Sin errores en log. |
| 20260707B_flota_combustible_operacion_PROD.sql | OK | `Logs\MobileProduccion_20260705\20260707B_flota_combustible_operacion_PROD.log` | ExitCode 0. Confirma tabla y SP de combustible creados. |
| 20260707C_flota_operacion_dia_horas_PROD.sql | OK | `Logs\MobileProduccion_20260705\20260707C_flota_operacion_dia_horas_PROD.log` | ExitCode 0. El precheck post-scripts confirma FechaHoraInicio/FechaHoraFin. |
| 20260707D_flota_pagocontrato_edicion_mobile_PROD.sql | OK | `Logs\MobileProduccion_20260705\20260707D_flota_pagocontrato_edicion_mobile_PROD.log` | ExitCode 0. El precheck post-scripts confirma SP y columnas de modificacion. |
| 20260706_URGENTE_flota_usuario_mobile_crud_PROD.sql | OK | `Logs\MobileProduccion_20260705\20260706_URGENTE_flota_usuario_mobile_crud_PROD.log` | ExitCode 0. SP admin UsuarioMobile creados/actualizados. `ListarAdmin` ejecuta sin error y hoy devuelve 0 filas porque aun no existen usuarios mobile reales. |
| SEED_USUARIO_MOBILE_PRODUCCION.sql |  |  |  |
| PRECHECK_POST_SCRIPTS_MOBILE_FLOTA.sql | OK | `Logs\MobileProduccion_20260705\PRECHECK_POST_SCRIPTS_MOBILE_FLOTA.log` | Todos los objetos esperados de Fase 2 quedaron en OK. Sin faltas ni alertas. |

## Alta de maestros del piloto
- Flujo principal usado: UI/admin / Plan B SQL
- Pantalla UI/admin de vehiculo operativa: si / no
- Pantalla UI/admin de chofer operativa: si / no
- Pantalla UI/admin de contrato operativa: si / no
- Se uso plan B `SEED_FLOTA_PILOTO_MAESTROS_PRODUCCION_TEMPLATE.sql`: si / no
- Se ejecuto `CONSULTA_IDS_MAESTROS_FLOTA_PILOTO.sql`: si / no
- Placa usada:
- Documento chofer usado:
- Telefono usado:
- IdVehiculo real:
- IdChofer real:
- IdContrato real:
- Observaciones:

## Deploy app
- Paquete publicado:
- Fecha/hora deploy:
- Responsable:
- `/Flota` carga: si / no
- `wwwroot/uploads/flota` existe: si / no
- Permisos de escritura OK: si / no
- HTTPS OK: si / no
- Cookie Secure OK: si / no
- Observaciones:

## Smoke test mobile
| Prueba | Resultado | Observaciones |
|---|---|---|
| `/Flota/MobileLogin` carga |  |  |
| Login correcto |  |  |
| `/Flota/EstacionMobile` carga |  |  |
| Solo ve su contrato |  |  |
| Guardar inicio |  |  |
| Guardar fin |  |  |
| Registrar combustible |  |  |
| Subir recibo GLP |  |  |
| Registrar pago declarado |  |  |
| Subir voucher |  |  |
| Editar pago pendiente |  |  |
| Logout |  |  |
| Contrato ajeno bloqueado |  |  |
| `AdminCalendario` sigue operativo |  |  |

## Datos del usuario mobile produccion
- Telefono:
- Contrato:
- Chofer:
- PIN temporal entregado:
- Fecha de entrega:
- Observaciones:

## Validacion previa al seed mobile
- `flota.vehiculo` tiene registro real: si / no
- `flota.chofer` tiene registro real: si / no
- `flota.contrato` tiene registro real: si / no
- `IdChofer` confirmado: si / no
- `IdContrato` confirmado: si / no
- `PasswordHash` generado fuera del SQL: si / no
- `PasswordSalt` generado fuera del SQL: si / no
- La consulta de confirmacion devolvio exactamente los maestros esperados: si / no
- Seed mobile autorizado: GO / NO-GO
- Motivo:

## Riesgos aceptados del piloto
- No liquida combustible.
- No aplica `PagoContrato` a recibos.
- Admin debe revisar pagos declarados.
- Admin debe revisar dias/horas si hay error.
- Bandeja admin `PagoContrato` pendiente.

## Decision
- GO / NO-GO: GO para publicar backend/UI
- Motivo: Scripts PROD estructurales aplicados con ExitCode 0 y precheck post-scripts completamente en OK. Seed mobile y alta de maestros aun pendientes.
- Firma / responsable:

## Hora fin
- Fecha/hora fin:

