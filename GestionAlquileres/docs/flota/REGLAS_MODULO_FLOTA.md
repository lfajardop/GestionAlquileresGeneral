# Reglas actuales del modulo Flota

Este documento resume el comportamiento vigente del modulo Flota de alquiler de vehiculos segun el controlador, el servicio y los scripts SQL actuales.

## 1. Estado actual implementado

### Alcance funcional actual
- Alta de vehiculos.
- Alta de conductores.
- Creacion de contratos de alquiler.
- Registro de operacion diaria por contrato y fecha.
- Generacion de recibos de alquiler.
- Generacion manual de recibos por fechas seleccionadas.
- Registro de pagos contra un recibo.
- Consulta de calendario administrativo y detalle de recibos.

### Catalogos vigentes
- Modalidades activas:
  - `D` = Alquiler diario.
  - `L` = Puerta libre.
- Periodicidades activas del contrato:
  - `S` = Semanal.
  - `Q` = Quincenal.
  - `M` = Mensual.
- Motivos de dia activos:
  - `TRA` = Dia trabajado, cobrable.
  - `DES` = Descanso acordado, no cobrable.
  - `MAN` = Mantenimiento aprobado, no cobrable.
  - `AVE` = Averia del vehiculo, no cobrable.
  - `FAL` = Falta del conductor, cobrable.
  - `OTR` = Otro motivo autorizado, no cobrable.
- Medios de pago activos:
  - `EF` = Efectivo.
  - `YA` = Yape.
  - `TR` = Transferencia.

### Reglas de contrato
- Un contrato se crea con vehiculo, conductor, modalidad, periodicidad, fecha de inicio y tarifa diaria.
- La tarifa diaria debe ser mayor a cero.
- La periodicidad debe existir y estar activa.
- Un vehiculo no puede tener mas de un contrato activo al mismo tiempo dentro de la misma empresa.
- El contrato se numera automaticamente con formato `ALQ-000000`.
- El contrato guarda:
  - `Flg_CobraDomingo`
  - `Flg_ControlKm`
  - observacion opcional
- El modulo trabaja hoy con la empresa `6` y la estacion `4`.

### Reglas de operacion diaria
- Cada dia operativo pertenece a un unico contrato.
- No puede existir mas de un registro diario para el mismo contrato y la misma fecha.
- Si el contrato controla kilometraje, el guardado diario exige:
  - kilometraje inicial informado,
  - kilometraje final informado,
  - kilometraje final mayor o igual al inicial.
- El kilometraje recorrido se calcula automaticamente como `KmFinal - KmInicial` cuando corresponde.
- El costo de consumo estimado se calcula con la informacion del vehiculo:
  - `(GalonesTanque * PrecioGalon) / RendimientoTanqueKm`
  - multiplicado por el kilometraje recorrido
  - redondeado a 2 decimales.
- El importe generado del dia se define asi:
  - si `Cobrable = N`, el importe es `0`;
  - en modalidad `L`, si el dia es domingo y el contrato no cobra domingo, el importe es `0`;
  - en modalidad `D`, si el dia no fue marcado como trabajado, el importe es `0`;
  - en los demas casos, el importe es igual a la tarifa diaria del contrato.
- Al registrar carga historica manual:
  - el dia se guarda como trabajado,
  - el motivo es `TRA`,
  - el dia queda cobrable,
  - el origen se guarda como `M`.

### Reglas de recibos
- Un recibo de alquiler agrupa dias cobrables de un contrato activo.
- La generacion automatica toma solo dias del rango solicitado que cumplan:
  - contrato activo,
  - dia cobrable,
  - importe mayor a cero,
  - no pertenecer ya a un recibo activo.
- Si no hay dias cobrables disponibles en el periodo, no se genera el recibo.
- El recibo se numera automaticamente con formato `RA-00000000`.
- El recibo almacena:
  - fecha de emision,
  - fecha inicio,
  - fecha fin,
  - cantidad de dias,
  - tarifa diaria,
  - importe total,
  - importe pagado,
  - saldo,
  - estado,
  - origen.
- Origen del recibo:
  - `O` = Operativo/automatico.
  - `M` = Manual.
- Estados vigentes del recibo:
  - `P` = Pendiente.
  - `A` = Parcial.
  - `C` = Pagado.
  - `X` = Anulado.
- La lista de recibos por contrato se puede filtrar por ano y mes, usando la fecha de inicio del recibo.
- El detalle de recibo devuelve:
  - cabecera,
  - dias incluidos,
  - pagos activos asociados.

### Generacion manual de recibos
- El usuario puede seleccionar uno o varios dias para generar carga historica.
- La generacion manual exige al menos un dia y una tarifa diaria valida.
- Los dias seleccionados no deben pertenecer ya a un recibo activo.
- La implementacion actual admite dos modos de agrupacion:
  - `U` = un solo recibo con todos los dias seleccionados.
  - `R` = recibos separados por bloques de fechas consecutivas.
- Cuando se genera manualmente, los dias quedan registrados como operativos con:
  - `Flg_Trabajo = S`
  - `Cod_Motivo = TRA`
  - `Flg_Cobrable = S`
  - `FlgOrigen = M`

### Reglas de pago
- Todo pago pertenece obligatoriamente a un recibo.
- El pago solo puede registrarse si el recibo esta en estado `P` o `A`.
- El importe del pago debe ser mayor a cero y no puede superar el saldo pendiente.
- El medio de pago debe estar activo.
- El pago admite observacion y voucher opcional.
- El voucher aceptado por la pantalla actual puede ser:
  - imagen `jpg`, `jpeg`, `png`, `webp`
  - o `pdf`
  - con tamano maximo de `5 MB`.
- Al registrar un pago:
  - se incrementa `ImportePagado`,
  - se reduce el `Saldo`,
  - el recibo pasa a `C` si el saldo llega a cero,
  - o permanece en `A` si aun queda saldo.
- La validacion del pago se guarda como marca `S/N` en `FlgValidado`.

### Pantalla Admin Calendario
La pantalla administrativa actual permite:
- seleccionar contrato,
- revisar calendario del mes,
- ver dias operativos y su origen,
- ver si un dia ya fue incluido en un recibo,
- generar recibos,
- generar carga manual,
- listar recibos del contrato,
- abrir el detalle de un recibo,
- registrar pagos sobre un recibo.

### Pantalla Operacion Diaria
La pantalla operativa actual permite:
- crear vehiculos,
- crear conductores,
- crear contratos,
- registrar el dia operativo del contrato,
- guardar kilometraje,
- guardar combustible,
- guardar observaciones.

### Reglas de consulta y auditoria visibles
- Los listados administrativos calculan totales de recibos sin contar los anulados.
- Los pagos se muestran solo cuando su `FlgEstado` esta activo.
- El sistema evita duplicar dias cobrables ya incluidos en recibos activos.
- Las fechas y cambios operativos quedan registrados con usuario y fecha de creacion o modificacion segun la tabla correspondiente.

### Limites actuales del modulo
- No hay flujo expuesto todavia para anular o editar recibos desde el controlador.
- No hay generacion de PDF de recibo implementada en este modulo.
- No hay integracion con caja general dentro de este flujo.

## 2. Reglas objetivo aprobadas

- No borrar fisicamente operaciones de negocio.
- Toda correccion administrativa debe tener motivo obligatorio.
- Toda edicion/anulacion debe guardar auditoria.
- Los pagos siempre dependen de un recibo.
- Los pagos todavia no deben integrarse con caja general ni cobranza general.
- El admin debe poder corregir dias marcados por error.
- El admin debe poder anular recibos con motivo.
- El admin debe poder editar/anular pagos con motivo.
- El sistema debe recalcular saldos luego de editar o anular pagos.
- El sistema debe evitar que un mismo dia este en dos recibos activos del mismo contrato.
- La validacion de pago se mantiene con `FlgValidado = S/N`.
- En esta fase se permite cambiar la validacion en ambos sentidos: `N -> S` y `S -> N`.
- Todo cambio de validacion de pago requiere motivo obligatorio y auditoria.
- La validacion de pago no toca caja general ni cobranza general en esta fase.
- Cuando exista integracion con caja/cobranza, se revisara si la validacion debe ser irreversible o requerir reversa formal.
- Todas las fechas/hora de auditoria, creacion, modificacion, anulacion, pagos, recibos y operaciones deben grabarse en UTC.
- No usar `GETDATE()` para fechas/hora de sistema. Usar `GETUTCDATE()` si la columna es `DATETIME` o `SYSUTCDATETIME()` si la columna es `DATETIME2`.
- El servidor puede estar en EEUU; por eso la hora local del servidor no es confiable para operacion en Peru.
- Al mostrar fechas/hora al usuario, convertir a hora Peru UTC-5 desde la capa de aplicacion o presentacion.
- En inserts nuevos del modulo Flota, enviar explicitamente `Fec_Creacion = GETUTCDATE()` cuando la tabla tenga esa columna.
- No depender de defaults antiguos con `GETDATE()`.
- Las fechas de negocio no se convierten en SQL: `Fecha`, `FechaInicio`, `FechaFin`, `FechaEmision` y `FechaPago`.
- Las fechas/hora de sistema si deben grabarse en UTC: `Fec_Creacion`, `Fec_Modif`, `Fec_Anula` y `AuditoriaFlota.Fecha`.
- Toda operacion del modulo Flota debe respetar multitenant: filtrar y validar siempre por `id_empresa` e `id_est`.
- Ningun procedimiento debe modificar recibos, pagos, dias, contratos o auditoria sin validar `id_empresa` e `id_est`.
- No permitir que una correccion deje un recibo con saldo negativo o total menor que lo ya pagado, salvo ajuste administrativo explicito con motivo.

## Regla de transacciones en procedimientos almacenados

- Ningun procedimiento almacenado del modulo Flota debe romper una transaccion externa abierta por el llamador.
- Si el SP es llamado sin transaccion activa, puede abrir su propia transaccion, confirmar con `COMMIT` si todo sale bien y hacer `ROLLBACK` si falla.
- Si el SP es llamado con una transaccion externa activa, no debe hacer `ROLLBACK` total de la transaccion del llamador.
- Para operaciones con riesgo de error dentro de una transaccion externa, usar `SAVE TRANSACTION` o un patron equivalente compatible con SQL Server 2014.
- Las validaciones de negocio deben ejecutarse preferentemente antes de modificar datos.
- Validaciones como motivo vacio, recibo con pagos activos, recibo no encontrado, pago no encontrado o total menor que pagado deben devolver mensaje y salir sin romper la transaccion externa.
- Todo SP que tenga parametro `@Mensaje` debe devolver el error funcional en `@Mensaje` cuando sea una validacion de negocio esperada.
- Los errores tecnicos no deben quedar ocultos: deben permitir identificar la causa real en desarrollo.
- Esta regla aplica como minimo a:
- `flota.p_ReciboAlquiler_Generar`
- `flota.p_ReciboAlquiler_GenerarManual`
- `flota.p_ReciboAlquiler_Anular`
- `flota.p_ReciboAlquiler_QuitarDia`
- `flota.p_PagoReciboAlquiler_Editar`
- `flota.p_PagoReciboAlquiler_Anular`
- `flota.p_PagoReciboAlquiler_Validar`
- `flota.p_OperacionDia_Corregir`

## Regla de vistas Razor tipadas

- Las vistas Razor del modulo Flota deben ser tipadas usando ViewModel o DTO.
- Evitar usar `ViewBag`/`ViewData` como fuente principal de datos.
- `ViewBag`/`ViewData` solo se permite para datos menores o temporales, no para estructuras principales de pantalla.
- Toda pantalla administrativa debe tener un ViewModel claro para facilitar mantenimiento.
- Los formularios o modales importantes deben mapearse a DTOs de request cuando corresponda.
- `AdminCalendario.cshtml` debe evolucionar hacia vista tipada si actualmente no lo esta.
- No mezclar logica de negocio en Razor; la logica debe quedar en Service/SP y la vista solo renderizar datos.
- Mantener nombres claros para ViewModels, por ejemplo:
- `FlotaAdminCalendarioViewModel`
- `FlotaReciboDetalleViewModel`
- `FlotaPagoReciboViewModel`

## 3. Pendientes por fase

### Fase 1.1 - Correccion administrativa
- Anular recibo con motivo.
- Quitar dia de recibo.
- Corregir motivo, observacion y estado cobrable de un dia con auditoria.
- Recalcular recibo.
- Editar pago.
- Anular pago.
- Validar pago.
- Guardar auditoria.

### Fase 2 - Estacion chofer mobile
- Ingresar km inicial.
- Ingresar km final.
- Registrar galones de GLP.
- Registrar costo del GLP.
- Adjuntar foto del recibo de GLP del grifo.
- Registrar pago.
- Adjuntar voucher Yape, Plin, transferencia o efectivo.

### Fase 3 - Tramos con kilometraje
- Permitir tramos que cruzan medianoche.
- Calcular horas y km.
- Si en ventana de 24 horas supera 12 horas o 180 km, generar dia adicional cobrable.
- Permitir carga historica sin km.

### Fase 4 - GLP y balance
- Calcular GLP pagado por chofer.
- Calcular GLP pagado por propietario.
- Calcular saldo a favor o contra.
- Permitir aplicar ajuste contra alquiler.

### Fase 5 - Liquidacion semanal/mensual
- Mostrar alquiler generado.
- Pagos aplicados.
- Saldo pendiente.
- Ajustes GLP.
- Descuentos.
- Total final.

### Fase 6 - PDF de recibo
- Generar PDF presentable con contrato, vehiculo, chofer, periodo, dias, tarifa, pagos y saldo.

### Fase 7 - Integracion futura con caja/cobranza
- Solo cuando el flujo este validado.
- No hacer integracion todavia.

## 4. Prohibiciones tecnicas
- No rehacer el modulo desde cero.
- No tocar caja general.
- No tocar cobranza general.
- No tocar otros modulos.
- El proyecto usa SQL Server 2014 SP3.
- No mezclar toda la logica en un solo JS.
- No duplicar tablas ya existentes.
- No cambiar nombres de tablas existentes sin justificar.
- No usar `FOR JSON PATH`.
- No usar `JSON_VALUE`.
- No usar funciones JSON de SQL Server 2016+.
- Para auditoria en SQL Server 2014, usar texto plano estructurado o campos separados, no JSON nativo.
- No usar `GETDATE()` en nuevos scripts del modulo Flota para fechas/hora operativas o auditoria.
- No consultar ni modificar datos solo por Id interno si tambien corresponde validar `id_empresa` e `id_est`.
- No usar reglas de memoria del chat si contradicen este archivo.
