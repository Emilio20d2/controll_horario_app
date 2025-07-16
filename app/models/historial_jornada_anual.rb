class HistorialJornadaAnual < ApplicationRecord  
  # Le indicamos a Rails el nombre correcto de la tabla en la base de datos.
  self.table_name = 'historial_jornada_anuales'

  belongs_to :trabajador

  # --- Validaciones ---
  # Asegura que cada trabajador tenga solo un registro por año.
  validates :anio, presence: true, uniqueness: { scope: :trabajador_id, message: "ya tiene un registro para este año" }

  # Asegura que los campos de horas siempre sean numéricos y estén presentes.
  validates :jornada_anual_ajustada, :horas_anuales_realizadas, :balance_final, presence: true, numericality: true  
end
