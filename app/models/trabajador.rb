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
    # Busca la asignación de turno activa para esta fecha
    asignacion = asignacion_turnos.where("fecha_inicio <= ? AND (fecha_fin IS NULL OR fecha_fin >= ?)", fecha, fecha).order(fecha_inicio: :desc).first
    return 0.0 unless asignacion&.plantilla_horario&.horario

    plantilla = asignacion.plantilla_horario
    
    # Calcular la semana del ciclo
    dias_desde_inicio = (fecha - asignacion.fecha_inicio).to_i
    semana_del_ciclo = (dias_desde_inicio / 7) % 4 + 1
    
    # Obtener el día de la semana (wday devuelve 0 para domingo, 1 para lunes...)
    dias_map = %w[domingo lunes martes miercoles jueves viernes sabado]
    dia_key = dias_map[fecha.wday]

    # Usar .dig para navegar de forma segura por el Hash
    BigDecimal(plantilla.horario.dig("semana#{semana_del_ciclo}", dia_key)&.to_s || "0.0").to_f
  end

  def jornada_semanal_actual(fecha = Date.today)
    historial_contratos.where('fecha_inicio_vigencia <= ?', fecha)
                       .order(fecha_inicio_vigencia: :desc)
                       .first&.horas_semanales_contratadas || 0.0
  end

  private

  def calcular_jornada_teorica_individual(anio)
    fecha_inicio_anio = Date.new(anio, 1, 1)
    fecha_fin_anio = Date.new(anio, 12, 31)
    horas_convenio_base = ConfiguracionJornada.find_by(anio: anio)&.horas_maximas || 1792.0
    jornada_teorica_individual = 0

    historial_contratos.where("fecha_inicio_vigencia <= ? AND (fecha_fin_vigencia IS NULL OR fecha_fin_vigencia >= ?)", fecha_fin_anio, fecha_inicio_anio).each do |contrato|
      dias_contrato_en_anio = [fecha_fin_anio, contrato.fecha_fin_vigencia || fecha_fin_anio].min - [fecha_inicio_anio, contrato.fecha_inicio_vigencia].max + 1
      jornada_teorica_individual += (contrato.horas_semanales_contratadas / 40.0) * horas_convenio_base * (dias_contrato_en_anio / (anio % 4 == 0 ? 366.0 : 365.0))
  end

    jornada_teorica_individual
  end

  def calcular_ajuste_ausencias_no_retribuidas(anio)
    fecha_inicio_anio = Date.new(anio, 1, 1)
    fecha_fin_anio = Date.new(anio, 12, 31)

    ids_ausencias_no_retribuidas = TipoAusencia.where(es_retribuida: false).pluck(:id)
    ajuste_ausencias_no_retribuidas = 0

    entrada_diarias.where(fecha: fecha_inicio_anio..fecha_fin_anio, tipo_ausencia_id: ids_ausencias_no_retribuidas).each do |entrada|
      ajuste_ausencias_no_retribuidas += horas_teoricas_para(entrada.fecha)
    end

    ajuste_ausencias_no_retribuidas
  end

  def calcular_horas_anuales_realizadas(anio)
    fecha_inicio_anio = Date.new(anio, 1, 1)
    fecha_fin_anio = Date.new(anio, 12, 31)
    horas_trabajadas = entrada_diarias.where(fecha: fecha_inicio_anio..fecha_fin_anio).sum(:horas_trabajadas)
    ids_ausencias_retribuidas = TipoAusencia.where(es_retribuida: true).pluck(:id)
    horas_ausencias = entrada_diarias.where(fecha: fecha_inicio_anio..fecha_fin_anio, tipo_ausencia_id: ids_ausencias_retribuidas).sum(:horas_ausencia)
    horas_trabajadas + horas_ausencias
  end

  # Devuelve el registro de contrato que estaba activo en una fecha específica.
  # Es un método clave para cálculos que dependen del historial.
  #
  # @param fecha [Date] La fecha para la cual se busca el contrato.
  # @return [HistorialContrato, nil] El registro del contrato o nil si no se encuentra.
  def contrato_vigente_en(fecha)
    historial_contratos.where('fecha_inicio_vigencia <= ?', fecha)
                       .order(fecha_inicio_vigencia: :desc)
                       .first
  end

  # Delegamos el cálculo de la jornada anual al service object.
  # Esto aísla la lógica compleja y facilita su testeo y mantenimiento.
  def calculo_jornada_anual(anio) # <-- Cambiado a public
    CalculoJornadaAnualService.call(self, anio) # Asegúrate de que este Service Object exista y esté implementado.
  end
  
  private # Movemos el private al final

  # ... (resto de métodos, incluyendo horas_para_bolsa_libranza) ...
end
