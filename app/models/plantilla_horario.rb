# -----------------------------------------------------------------
# Archivo 1 (CORRECTO): app/models/plantilla_horario.rb
# -----------------------------------------------------------------
# OBJETIVO: Asegurar que el campo 'horario' se trata como un Hash.

class PlantillaHorario < ApplicationRecord
  has_many :asignacion_turnos

  # 'attribute' le dice a Rails cómo manejar este campo. Para un campo
  # jsonb/text que almacena un Hash, esto es moderno y robusto.
  attribute :horario, :json, default: {}

  validates :nombre, presence: true, uniqueness: true
end