# Diseño futuro - pago global por chofer

## Objetivo
- Permitir una vista global de deuda real por chofer.
- Consolidar recibos pendientes de múltiples contratos del mismo chofer.
- Diseñar un pago global futuro sin aplicarlo todavía.

## Estado actual
- `flota.p_Chofer_DeudaResumen` ya resume:
  - deuda real de recibos
  - contratos activos/cerrados
  - pagos declarados separados
- `PagoContrato` todavía no descuenta recibos.
- No existe pago global aplicado.

## Principio funcional
- La deuda real se calcula desde recibos activos.
- Los `PagoContrato` se muestran separados:
  - pendiente
  - validado no aplicado
- No se debe mezclar deuda real con dinero todavía no aplicado.

## Vista futura esperada
- Chofer
- Documento
- Teléfono
- Total contratos
- Contratos activos
- Contratos cerrados
- Total generado
- Total pagado
- Saldo recibos
- Pago declarado pendiente
- Pago declarado validado no aplicado
- Última fecha de deuda

## Flujo futuro de pago global
1. Administración revisa deuda global del chofer.
2. Registra un pago global manual.
3. El sistema propone distribución por antigüedad o deja distribución manual.
4. Se generan detalles por recibo.
5. Recién ahí impacta `PagoReciboAlquiler`.

## Tablas futuras propuestas
- `flota.PagoGlobalChofer`
- `flota.PagoGlobalChoferDetalle`

## flota.PagoGlobalChofer
- `IdPagoGlobalChofer INT IDENTITY PRIMARY KEY`
- `id_empresa INT NOT NULL`
- `id_est CHAR(2) NOT NULL`
- `Id_Chofer INT NOT NULL`
- `FechaPago DATE NOT NULL`
- `ImporteTotal DECIMAL(18,2) NOT NULL`
- `IdFormaPago INT NOT NULL`
- `OperacionReferencia VARCHAR(100) NULL`
- `Observacion VARCHAR(250) NULL`
- `FlgEstado VARCHAR(1) NOT NULL`
- `Usu_Creacion INT NOT NULL`
- `Fec_Creacion DATETIME NOT NULL`

## flota.PagoGlobalChoferDetalle
- `IdPagoGlobalChoferDetalle INT IDENTITY PRIMARY KEY`
- `id_empresa INT NOT NULL`
- `id_est CHAR(2) NOT NULL`
- `IdPagoGlobalChofer INT NOT NULL`
- `Id_ReciboAlquiler INT NOT NULL`
- `ImporteAplicado DECIMAL(18,2) NOT NULL`
- `OrdenAplicacion INT NOT NULL`
- `FlgEstado VARCHAR(1) NOT NULL`
- `Usu_Creacion INT NOT NULL`
- `Fec_Creacion DATETIME NOT NULL`

## Relación futura con PagoReciboAlquiler
- Opción preferida:
  - que cada aplicación global termine generando trazabilidad compatible con `PagoReciboAlquiler`
- Antes de eso, `PagoReciboAlquiler` debe migrar o ampliarse correctamente hacia `IdFormaPago`.

## Reglas futuras
- No aplicar más de lo adeudado por recibo.
- No aplicar a recibos anulados.
- Respetar orden de antigüedad si se usa aplicación automática.
- Mantener auditoría de aplicación y reversa.

## Riesgos
- Duplicar deuda si no se separa bien `PagoContrato`.
- Aplicar pagos globales sin migrar correctamente `PagoReciboAlquiler`.
- Mezclar pago global con caja/cobranza general antes de tiempo.

## Exclusiones explícitas
- No crear tablas ejecutables todavía.
- No registrar pago global todavía.
- No aplicar pagos a recibos todavía.
- No tocar caja/cobranza.
- No liquidar combustible.
