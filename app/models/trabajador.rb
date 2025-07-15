class Trabajador < ApplicationRecord
  belongs_to :tipo_contrato

  has_many :asignacion_turnos, dependent: :destroy
  has_many :plantilla_horarios, through: :asignacion_turnos
  has_many :historial_contratos, dependent: :destroy
  has_many :entrada_diarias, dependent: :destroy
  has_many :movimiento_bolsas, dependent: :destroy
  has_many :limite_festivo_libranzas, dependent: :destroy
  has_one :bolsa_horas_saldo, dependent: :destroy
  has_many :historial_jornada_anuals, dependent: :destroy

  validates :nombre, presence: true

  def horas_teoricas_para(fecha)
    # Lógica para calcular las horas teóricas de un día...
    # (Este método ya debería estar correcto según nuestros pasos anteriores)
    asignacion = asignacion_turnos.where("fecha_inicio <= ? AND (fecha_fin IS NULL OR fecha_fin >= ?)", fecha, fecha).order(fecha_inicio: :desc).first
    return 0.0 unless asignacion&.plantilla_horario&.horario

    plantilla = asignacion.plantilla_horario
    dias_desde_inicio = (fecha - asignacion.fecha_inicio).to_i
    semana_del_ciclo = (dias_desde_inicio / 7) % 4 + 1
    dias_map = %w[domingo lunes martes miercoles jueves viernes sabado]
    dia_key = dias_map[fecha.wday]
    BigDecimal(plantilla.horario.dig("semana#{semana_del_ciclo}", dia_key)&.to_s || "0.0").to_f
  end

  def jornada_semanal_actual
    historial_contratos.order(fecha_inicio_vigencia: :desc).first&.horas_semanales_contratadas || 0.0
  end
end
