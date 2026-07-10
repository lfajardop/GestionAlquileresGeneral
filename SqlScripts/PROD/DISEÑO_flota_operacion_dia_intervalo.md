# Diseño futuro - flota.operacion_dia_intervalo

## Objetivo
- Permitir que un mismo día operativo tenga múltiples intervalos reales de trabajo.
- Separar el día administrativo de los tramos reales hora a hora.
- Calcular horas acumuladas sobre intervalos activos.
- Generar alertas administrativas si el total supera 12 horas.
- No generar todavía día adicional cobrable de forma automática.

## Relación con operacion_dia
- `flota.operacion_dia` sigue siendo la cabecera del día.
- `flota.operacion_dia_intervalo` sería el detalle 1:N de intervalos.
- La cabecera conservaría:
  - contrato
  - fecha operativa
  - trabajo/no trabajo
  - motivo
  - cobrable administrativo
  - km
  - importes base
- Los intervalos guardarían:
  - hora real de inicio
  - hora real de fin
  - observación opcional
  - estado activo/anulado

## Tabla propuesta
- `flota.operacion_dia_intervalo`

## Columnas propuestas
- `Id_OperacionDiaIntervalo INT IDENTITY PRIMARY KEY`
- `id_empresa INT NOT NULL`
- `id_est CHAR(2) NOT NULL`
- `Id_OperacionDia INT NOT NULL`
- `FechaHoraInicio DATETIME NOT NULL`
- `FechaHoraFin DATETIME NULL`
- `Observacion VARCHAR(250) NULL`
- `FlgEstado VARCHAR(1) NOT NULL`
- `Usu_Creacion INT NOT NULL`
- `Fec_Creacion DATETIME NOT NULL`
- `Usu_Modif INT NULL`
- `Fec_Modif DATETIME NULL`
- `Usu_Anula INT NULL`
- `Fec_Anula DATETIME NULL`
- `MotivoAnula VARCHAR(250) NULL`

## Checks propuestos
- `FlgEstado IN ('A','X')`
- `FechaHoraFin IS NULL OR FechaHoraFin >= FechaHoraInicio`

## Índices propuestos
- `IX_flota_operacion_dia_intervalo_OperacionEstado`
  - `(Id_OperacionDia, FlgEstado, FechaHoraInicio)`
- `IX_flota_operacion_dia_intervalo_TenantFecha`
  - `(id_empresa, id_est, FechaHoraInicio, FlgEstado)`

## Reglas funcionales
- No crear dos intervalos activos con el mismo inicio exacto para la misma operación.
- Permitir cerrar un intervalo abierto.
- Permitir anulación lógica con motivo obligatorio.
- Las horas acumuladas deben sumar solo intervalos activos.
- Si un intervalo cruza medianoche, el cálculo debe respetar datetimes reales.
- La decisión final de cobrable sigue siendo administrativa, no del chofer.

## SP futuros
- `flota.p_OperacionDiaIntervalo_Abrir`
- `flota.p_OperacionDiaIntervalo_Cerrar`
- `flota.p_OperacionDiaIntervalo_Anular`
- `flota.p_OperacionDiaIntervalo_ListarPorOperacion`
- `flota.p_OperacionDiaIntervalo_ResumenHoras`

## Impacto en AdminCalendario
- El detalle del día debe mostrar:
  - horas acumuladas
  - cantidad de intervalos
  - último inicio
  - último fin
- Corrección administrativa futura:
  - anular intervalo
  - editar horas
  - recalcular horas del día

## Impacto en Mobile
- El flujo futuro del chofer sería:
  - abrir jornada
  - pausar/reanudar si aplica
  - cerrar jornada
- En esta etapa aún no se implementa ese flujo múltiple.

## Cálculo futuro de horas acumuladas
- Sumar `DATEDIFF(MINUTE, FechaHoraInicio, FechaHoraFin)` de intervalos activos cerrados.
- Si existe intervalo abierto, mostrar alerta de jornada incompleta.
- Exponer también:
  - horas totales
  - minutos totales
  - estado abierto/cerrado

## Alerta > 12 horas
- Si horas acumuladas del día > 12:
  - mostrar alerta administrativa
  - no generar automáticamente nuevo cobro todavía
  - dejar decisión manual para administración

## Día adicional cobrable
- Queda solo diseñado.
- Regla futura:
  - si la política del negocio lo aprueba, una jornada extraordinaria podría generar un día adicional cobrable.
- Esta lógica no se ejecuta todavía en SQL ni en backend.

## Exclusiones explícitas
- No genera recibo automático.
- No toca caja/cobranza.
- No aplica pagos.
- No liquida combustible.
