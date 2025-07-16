# Define el modelo para un trabajador, que es la entidad central de la aplicación.
# Contiene la lógica de negocio para calcular las horas teóricas y encontrar
# los contratos y asignaciones de turno vigentes en una fecha específica.
class Trabajador < ApplicationRecord
  # --- ASOCIACIONES ---
  # Se especifica que debe existir un tipo de contrato asociado.
  belongs_to :tipo_contrato

  # Asociaciones con otros modelos que almacenan datos del trabajador.
  # El orden en `asignacion_turnos` es crucial para encontrar el turno vigente.
  has_one :bolsa_horas_saldo, dependent: :destroy
  has_many :historial_contratos, -> { order(fecha_inicio_vigencia: :desc) }, dependent: :destroy
  has_many :asignacion_turnos, -> { order(fecha_inicio: :desc) }, dependent: :destroy
  has_many :movimiento_bolsas, dependent: :destroy
  has_many :entrada_diarias, dependent: :destroy

  # --- VALIDACIONES ---
  validates :nombre, presence: true, uniqueness: { case_sensitive: false }

  # --- LÓGICA DE NEGOCIO ---

  # Encuentra el contrato que estaba vigente en una fecha determinada.
  # Utiliza el orden descendente de `fecha_inicio_vigencia` para obtener el más reciente.
  def contrato_vigente_en(fecha)
    historial_contratos.find { |h| h.fecha_inicio_vigencia <= fecha }
  end

  # Calcula las horas teóricas que un trabajador debe realizar en una fecha específica,
  # basándose en su asignación de turno y el patrón de rotación.
  def horas_teoricas_para(fecha)
    # 1. Encontrar la asignación de turno activa para la fecha dada.
    asignacion = asignacion_turnos.where("fecha_inicio <= ? AND (fecha_fin IS NULL OR fecha_fin >= ?)", fecha, fecha).order(fecha_inicio: :desc).first
    return 0.0 unless asignacion&.plantilla_horario&.horario

    plantilla = asignacion.plantilla_horario

    # Calcular la semana del ciclo
    dias_desde_inicio = (fecha - asignacion.fecha_inicio).to_i
    semana_del_ciclo = (dias_desde_inicio / 7) % 4 + 1

    # Obtener el día de la semana (wday devuelve 0 para domingo, 1 para lunes...)
    dias_map = %w[domingo lunes martes miercoles jueves viernes sabado]
    dia_key = dias_map[fecha.wday]

    # 3. Obtener el día de la semana como una clave de texto (ej. 'lunes').
    # El `wday` de Ruby va de Domingo (0) a Sábado (6). Lo mapeamos al formato del JSON.
    dia_semana_map = { 1 => 'lunes', 2 => 'martes', 3 => 'miercoles', 4 => 'jueves', 5 => 'viernes', 6 => 'sabado', 0 => 'domingo' }
    dia_key = dia_semana_map[fecha.wday]

    # 4. Extraer las horas del JSON del horario usando las claves calculadas.
    # `dig` es una forma segura de navegar el hash, devuelve nil si una clave no existe.
    BigDecimal(plantilla.horario.dig("semana#{semana_del_ciclo}", dia_key)&.to_s || "0.0").to_f
  end
end
# Define el modelo para un trabajador, que es la entidad central de la aplicación.
# Contiene la lógica de negocio para calcular las horas teóricas y encontrar
# los contratos y asignaciones de turno vigentes en una fecha específica.
class Trabajador < ApplicationRecord
  # --- ASOCIACIONES ---
  # Se especifica que debe existir un tipo de contrato asociado.
  belongs_to :tipo_contrato

  # Asociaciones con otros modelos que almacenan datos del trabajador.
  # El orden en `asignacion_turnos` es crucial para encontrar el turno vigente.
  has_one :bolsa_horas_saldo, dependent: :destroy
  has_many :historial_contratos, -> { order(fecha_inicio_vigencia: :desc) }, dependent: :destroy
  has_many :asignacion_turnos, -> { order(fecha_inicio: :desc) }, dependent: :destroy
  has_many :movimiento_bolsas, dependent: :destroy
  has_many :entrada_diarias, dependent: :destroy

  # --- VALIDACIONES ---
  validates :nombre, presence: true, uniqueness: { case_sensitive: false }

  # --- LÓGICA DE NEGOCIO ---

  # Encuentra el contrato que estaba vigente en una fecha determinada.
  # Utiliza el orden descendente de `fecha_inicio_vigencia` para obtener el más reciente.
  def contrato_vigente_en(fecha)
    historial_contratos.find { |h| h.fecha_inicio_vigencia <= fecha }
  end

  # Calcula las horas teóricas que un trabajador debe realizar en una fecha específica,
  # basándose en su asignación de turno y el patrón de rotación.
  def horas_teoricas_para(fecha)
    # 1. Encontrar la asignación de turno activa para la fecha dada.
    asignacion = asignacion_turnos.find { |a| a.fecha_inicio <= fecha }
    return 0 unless asignacion&.plantilla_horario&.horario.present?

    plantilla = asignacion.plantilla_horario
    fecha_referencia = plantilla.fecha_referencia

    # 2. Calcular la semana de rotación y el día
    dias_diferencia = (fecha.to_date - fecha_referencia.beginning_of_week(:monday).to_date).to_i
    semana_rotacion_idx = (dias_diferencia / 7) % 4
    turno_key = "turno#{semana_rotacion_idx + 1}"
    dia_semana_map = { 1 => 'lunes', 2 => 'martes', 3 => 'miercoles', 4 => 'jueves', 5 => 'viernes', 6 => 'sabado', 0 => 'domingo' }
    dia_key = dia_semana_map[fecha.wday]

    # 3. Extraer las horas del JSON, convertir a minutos y devolver como entero.
    horas_decimal = plantilla.horario.dig(turno_key, dia_key).to_f
    (horas_decimal * 60).to_i
  end
end