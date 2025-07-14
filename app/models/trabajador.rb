# app/models/trabajador.rb
class Trabajador < ApplicationRecord
  belongs_to :tipo_contrato
  has_many :movimiento_bolsas, dependent: :destroy
  has_many :historial_contratos, dependent: :destroy
  has_many :asignacion_turnos, dependent: :destroy
  has_many :entrada_diarias, dependent: :destroy
  has_many :historial_jornada_anuales, class_name: "::HistorialJornadaAnual", dependent: :destroy
  has_one :bolsa_horas_saldo, dependent: :destroy

  validates :jornada_semanal_actual, numericality: { greater_than_or_equal_to: 0 }, multiple_of: { multiple_of: 0.25 }, allow_nil: true


  def horas_teoricas_para(fecha)
    # 1. Encontrar la asignación de turno activa para la fecha dada.
    # Se busca la asignación cuya fecha de inicio sea la más reciente pero no posterior a la fecha consultada.
    asignacion = asignacion_turnos.where("fecha_inicio <= ?", fecha).order(fecha_inicio: :desc).first

    # Si no hay asignación o la asignación no tiene una plantilla, no hay horas teóricas.
    return BigDecimal("0.0") unless asignacion&.plantilla_horario

    plantilla = asignacion.plantilla_horario
    fecha_referencia = plantilla.fecha_referencia

    # 2. Calcular en qué semana de la rotación nos encontramos.
    # Se asume una rotación de 4 semanas, como en el archivo de importación.
    # Se cuentan las semanas completas desde la fecha de referencia de la plantilla para saber el turno.
    semanas_desde_referencia = ((fecha.to_date - fecha_referencia.to_date) / 7).to_i
    turno_num = (semanas_desde_referencia % 4) + 1 # El resultado es 1, 2, 3 o 4

    # 3. Obtener el día de la semana (Lunes, Martes, etc.) en minúsculas.
    # Se usa un mapa numérico (wday) para evitar problemas de idioma.
    # Date#wday devuelve 0 para Domingo, 1 para Lunes, ..., 6 para Sábado.
    dias_semana_map = {
      1 => 'lunes',
      2 => 'martes',
      3 => 'miercoles',
      4 => 'jueves',
      5 => 'viernes',
      6 => 'sabado',
      0 => 'domingo'
    }
    dia_semana_key = dias_semana_map[fecha.wday]

    # 4. Buscar las horas en el JSON del horario y devolverlas como BigDecimal.
    horas = plantilla.horario.dig("turno#{turno_num}", dia_semana_key)
    BigDecimal(horas || 0)
  end

  # Calcula el resumen de la jornada para un año específico.
  def calculo_jornada_anual(anio)
    fecha_inicio_anio = Date.new(anio, 1, 1)
    fecha_fin_anio = Date.new(anio, 12, 31)

    # --- 1. El Punto de Partida: La Jornada Anual de Convenio ---
    configuracion_anual = ConfiguracionJornada.find_by(anio: anio)
    return { horas_teoricas: 0, horas_reales: 0, balance: 0 } unless configuracion_anual
    horas_convenio = configuracion_anual.horas_maximas
    jornada_semanal_referencia = configuracion_anual.jornada_semanal_maxima

    # --- 2. Cálculo de la Jornada Anual Teórica Individual (Prorrateo por Contratos) ---
    jornada_anual_teorica_bruta = historial_contratos
      .where("fecha_inicio_vigencia <= ? AND (fecha_fin_vigencia IS NULL OR fecha_fin_vigencia >= ?)", fecha_fin_anio, fecha_inicio_anio)
      .reduce(BigDecimal("0.0")) do |total, contrato|
        periodo_inicio = [contrato.fecha_inicio_vigencia, fecha_inicio_anio].max
        periodo_fin = [contrato.fecha_fin_vigencia || fecha_fin_anio, fecha_fin_anio].min
        dias_en_periodo = (periodo_fin - periodo_inicio).to_i + 1

        # Ajuste por Jornada Parcial: Calcula la jornada anual de referencia para este contrato.
        jornada_referencia_contrato = (contrato.horas_semanales_contratadas / jornada_semanal_referencia) * horas_convenio

        # Ajuste por Duración del Contrato: Prorratea la jornada de referencia según el tiempo activo en el año.
        dias_del_anio = Date.new(anio, 12, 31).yday
        horas_prorrateadas = (dias_en_periodo / dias_del_anio.to_f) * jornada_referencia_contrato

        total + horas_prorrateadas
      end

    # --- 3. ¿Qué Horas "Restan" de la Jornada Anual Teórica? ---
    # Se restan las horas teóricas de los días con ausencias NO retribuidas.
    total_horas_ausencia_no_retribuida = entrada_diarias
      .joins(:tipo_ausencia)
      .where(fecha: fecha_inicio_anio..fecha_fin_anio, tipo_ausencias: { es_retribuida: false })
      .sum { |ed| horas_teoricas_para(ed.fecha) }

    # --- 4. Fórmula Final: Jornada Anual Ajustada ---
    jornada_anual_ajustada = jornada_anual_teorica_bruta - total_horas_ausencia_no_retribuida

    # --- 5. ¿Qué Horas "Suman" para el Cómputo de la Jornada Anual? ---
    # El balance anual ya representa la diferencia entre las horas realizadas (trabajadas + ausencias retribuidas + uso de bolsas)
    # y las horas teóricas. Por lo tanto, es la forma más directa de obtener las horas realizadas.
    balance_anual = movimiento_bolsas
                      .where(categoria_bolsa_afectada: :horas, fecha_efectiva: fecha_inicio_anio..fecha_fin_anio)
                      .sum(:cantidad_horas)

    # --- 6. Cálculo de Horas Anuales Realizadas ---
    horas_reales_anuales = jornada_anual_ajustada + balance_anual

    { horas_teoricas: jornada_anual_ajustada, horas_reales: horas_reales_anuales, balance: balance_anual }
  end
end