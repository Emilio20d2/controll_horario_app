# Conecta a un Trabajador con una PlantillaHorario para un
# período de tiempo determinado (fecha_inicio a fecha_fin).
class AsignacionTurno < ApplicationRecord
  belongs_to :trabajador
  belongs_to :plantilla_horario

  validates :fecha_inicio, presence: true
end
