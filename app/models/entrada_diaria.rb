# Almacena los datos introducidos por el administrador en la "Vista de
# Confirmación Semanal" para un trabajador en un día específico.
class EntradaDiaria < ApplicationRecord
  belongs_to :trabajador
  belongs_to :tipo_ausencia, optional: true # Una entrada puede no tener ausencia

  # Especificamos explícitamente el nombre de la tabla para resolver la inconsistencia.
  # La convención de Rails es usar nombres de tabla en plural.
  self.table_name = 'entrada_diarias'

  validates :fecha, presence: true
  validates :horas_trabajadas, numericality: { greater_than_or_equal_to: 0 }, multiple_of: { multiple_of: 0.25 }, allow_nil: true
  validates :horas_ausencia, numericality: { greater_than_or_equal_to: 0 }, multiple_of: { multiple_of: 0.25 }, allow_nil: true
  # El nombre del atributo debe coincidir con la columna de la base de datos.
  validates :horas_comp_pagadas, numericality: { greater_than_or_equal_to: 0 }, multiple_of: { multiple_of: 0.25 }, allow_nil: true
end
