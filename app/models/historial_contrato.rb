# Guarda un registro de las condiciones contractuales de un trabajador
# (como las horas semanales) para un período específico.
class HistorialContrato < ApplicationRecord
  belongs_to :trabajador

  validates :horas_semanales_contratadas, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :fecha_inicio_vigencia, presence: true
end
