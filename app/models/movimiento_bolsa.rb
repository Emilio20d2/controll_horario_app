# Registra cada cambio individual en la bolsa de horas de un trabajador.
# Es el historial detallado de la bolsa.
class MovimientoBolsa < ApplicationRecord
  belongs_to :trabajador

  # Usar enums mejora la integridad de los datos y la legibilidad del código.
  # Se pueden usar métodos como: movimiento.credito! o movimiento.categoria_horas_normales?
  enum tipo_movimiento: {
    credito: 'credito',                 # Suma horas a la bolsa (ej. horas extra)
    debito: 'debito',                   # Resta horas de la bolsa (ej. día libre)
    saldo_inicial: 'saldo_inicial',     # Movimiento especial para la importación inicial
    balance_semanal: 'balance_semanal'  # Ajuste resultante del cómputo semanal
  }, _prefix: :tipo

  enum categoria_bolsa_afectada: {
    # Nomenclatura unificada según la directiva.
    horas: 'horas',
    festivos: 'festivos',
    libranza: 'libranza'
  }, _prefix: :categoria

  validates :fecha_efectiva, presence: true
  validates :cantidad_horas, presence: true, multiple_of: { multiple_of: 0.25 }
  validates :tipo_movimiento, presence: true
  validates :categoria_bolsa_afectada, presence: true
  validates :concepto, presence: true
end
