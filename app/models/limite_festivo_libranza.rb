# Lleva la cuenta de cuántas horas ha acumulado un trabajador
# por festivos en libranza durante un año, para aplicar el límite.
class LimiteFestivoLibranza < ApplicationRecord
  belongs_to :trabajador

  validates :anio, presence: true, uniqueness: { scope: :trabajador_id }
  validates :horas_acumuladas, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
