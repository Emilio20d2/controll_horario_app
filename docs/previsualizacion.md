# Guía Detallada: Lógica de Cálculo de la Previsualización Semanal

Este documento describe cómo el sistema calcula los valores de previsualización en la tabla semanal de **Fichajes**. Cada vez que se modifica cualquier dato de la fila de un trabajador, se recalculan automáticamente los cuatro campos de previsualización usando JavaScript. No es necesario recargar la página.

## Confirmación implícita de las horas teóricas

- Si un campo de horas trabajadas está vacío o mantiene el valor teórico, se da por confirmado que el trabajador ha realizado esas horas.
- Solo cuando se introduce un valor distinto (incluido `0`), el sistema utilizará ese valor.

## Flujo de actualización

1. **Disparador del usuario**: al modificar una celda y perder el foco, se lanza el evento `onchange`.
2. **Recolección de datos**: un script de JavaScript recopila los valores de los siete días de la fila, aplicando la regla anterior.
3. **Cálculo**: con estos datos se calculan inmediatamente los cuatro campos:

### 1. Total Horas Computadas

Suma de horas semanales que cuentan como cumplidas.

```
SUMA(Horas Trabajadas) + SUMA(Ausencias sin deuda) - SUMA(Ausencias con deuda)
```

### 2. Impacto Bolsa HORAS (Ordinaria)

Balance semanal que se suma o resta de la bolsa principal de horas.

```
Suma de balances diarios
```

El balance diario parte de las horas trabajadas, restando complementarias pagadas y horas de festivos que van a otra bolsa según el contrato.

### 3. Impacto Bolsa FESTIVOS

Horas que entran o salen de la bolsa de festivos trabajados.

- **Suma**: horas de un festivo trabajado cuando no se marca pago doble y el contrato permite acumular en esta bolsa.
- **Resta**: horas de una ausencia de tipo "Devolución de Festivo".

### 4. Impacto Bolsa LIBRANZA

Horas que se acumulan en la bolsa de festivos en día de libranza.

- **Suma**: festivo de cierre con 0 horas teóricas añade `(jornada semanal / 5)`.
- **Resta**: ausencia "Libranza de Festivo".

Al terminar el cálculo, los cuatro valores se muestran en su fila correspondiente, ofreciendo una visión clara del impacto de cada cambio.

