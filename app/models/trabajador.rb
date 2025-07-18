class Trabajador < ApplicationRecord
  # --- ASOCIACIONES ---
  belongs_to :tipo_contrato
  has_many :historial_contratos, dependent: :destroy
  has_many :asignacion_turnos, dependent: :destroy
  has_many :plantillas_horario, through: :asignacion_turnos
  has_many :entrada_diarias, dependent: :destroy
  has_many :movimiento_bolsas, dependent: :destroy
  has_one :bolsa_horas_saldo, dependent: :destroy
  has_many :historial_jornada_anuales, class_name: 'HistorialJornadaAnual', dependent: :destroy
 
  # --- VALIDACIONES ---
  validates :nombre, presence: true, uniqueness: { case_sensitive: false }
  validates :activo, inclusion: { in: [true, false] }
 
  # --- MÉTODOS DE INSTANCIA ---
 
  def contrato_vigente_en(fecha)
    historial_contratos.where("fecha_inicio_vigencia <= ?", fecha).order(fecha_inicio_vigencia: :desc).first
  end
 
  def horas_teoricas_para(fecha)
    # LÓGICA CORREGIDA: Se elimina la conversión a minutos (* 60).
    # El método ahora devuelve horas en formato decimal directamente desde la plantilla.
    asignacion = asignacion_turnos.where("fecha_inicio <= ? AND (fecha_fin IS NULL OR fecha_fin >= ?)", fecha, fecha).first
    return BigDecimal("0.0") unless asignacion && asignacion.plantilla_horario&.horario
 
    semanas_desde_referencia = ((fecha - asignacion.plantilla_horario.fecha_referencia).to_i / 7)
    numero_turno = (semanas_desde_referencia % 4) + 1
    dia_semana_key = fecha.strftime('%A').downcase.to_sym
    valor_horario = asignacion.plantilla_horario.horario.dig("turno#{numero_turno}", dia_semana_key)
    BigDecimal((valor_horario.presence || "0.0").to_s)
  end

  # --- CÁLCULO DE JORNADA ANUAL (EN HORAS DECIMALES) ---
  def calculo_jornada_anual(anio)
    # 1. Obtener configuración de jornada para el año
    configuracion = ConfiguracionJornada.find_by(anio: anio)
    return { error: "No hay configuración de jornada para el año #{anio}." } unless configuracion
 
    # 2. Determinar el período de actividad del trabajador en el año
    inicio_anio = Date.new(anio, 1, 1)
    fin_anio = Date.new(anio, 12, 31)
 
    primer_contrato = historial_contratos.order(:fecha_inicio_vigencia).first
    return { error: "El trabajador no tiene historial de contratos." } unless primer_contrato
 
    fecha_alta_real = primer_contrato.fecha_inicio_vigencia
    fecha_baja_real = self.fecha_baja || fin_anio
 
    inicio_periodo = [inicio_anio, fecha_alta_real].max
    fin_periodo = [fin_anio, fecha_baja_real].min
 
    if inicio_periodo > fin_periodo
      return { horas_teoricas: 0, horas_reales: 0, balance: 0, debug_info: { error: "El trabajador no estuvo activo en el año #{anio}" } }
    end

    # 3. Calcular días brutos del contrato en el año
    dias_totales_anio = (fin_anio - inicio_anio).to_i + 1
    dias_brutos_periodo = (fin_periodo - inicio_periodo).to_i + 1

    # 4. [LÓGICA CORREGIDA] Descontar días de suspensión de contrato del período
    dias_suspension = entrada_diarias
                        .joins(:tipo_ausencia)
                        .where(fecha: inicio_periodo..fin_periodo)
                        .where(tipo_ausencias: { suspende_contrato: true })
                        .distinct
                        .count(:fecha)

    dias_efectivos_contrato = dias_brutos_periodo - dias_suspension
    dias_efectivos_contrato = [dias_efectivos_contrato, 0].max

    # 5. Calcular jornada teórica prorrateada usando los días EFECTIVOS y horas decimales
    horas_anuales_base = configuracion.horas_maximas # El campo ya es decimal
    horas_teoricas_prorrateadas = (horas_anuales_base / dias_totales_anio) * dias_efectivos_contrato

    # 6. Calcular horas reales trabajadas en el período (SUMA de las horas de las entradas diarias)
    horas_reales_trabajadas = entrada_diarias
                              .where(fecha: inicio_periodo..fin_periodo)
                              .sum(:horas_trabajadas) # Las horas ya son decimales

    # 7. Calcular balance (horas reales - horas teóricas)
    balance_horas = horas_reales_trabajadas - horas_teoricas_prorrateadas

    {
      horas_teoricas: horas_teoricas_prorrateadas.round(2),
      horas_reales: horas_reales_trabajadas.round(2),
      balance: balance_horas.round(2),
      debug_info: {
        horas_anuales_convenio: horas_anuales_base,
        dias_totales_anio: dias_totales_anio,
        dias_brutos_periodo: dias_brutos_periodo,
        dias_suspension: dias_suspension,
        dias_efectivos_contrato: dias_efectivos_contrato
      }
    }
  end

  # Devuelve un resumen anual desde el primer contrato hasta el año actual.
  # Cada elemento incluye jornada teórica, horas computables reales y balance.
  def resumen_jornadas_anuales
    inicio = historial_contratos.minimum(:fecha_inicio_vigencia)
    return [] unless inicio

    fin = [Date.today.year, fecha_baja&.year].compact.max

    (inicio.year..fin).map do |anio|
      calculo = CalculoJornadaAnualService.call(self, anio)
      calculo.merge(anio: anio)
    end
  end
end
  