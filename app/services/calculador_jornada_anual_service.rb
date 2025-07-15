class CalculadorJornadaAnualService
  def initialize(trabajador, anio)
    @trabajador = trabajador
    @anio = anio
    @fecha_inicio_anio = Date.new(anio, 1, 1)
    @fecha_fin_anio = Date.new(anio, 12, 31)
  end

  def self.call(trabajador:, anio:)
    new(trabajador, anio).calcular
  end

  def calcular
    # Lógica basada en la guía "Lógica de Cálculo de la Jornada Anual"
    
    # 1. Obtener horas de convenio (asumimos que existe un modelo ConfiguracionAnual)
    # TODO: Crear el modelo ConfiguracionAnual para almacenar las horas base por año.
    horas_convenio_base = 1792.0 # Valor por defecto

    # 2. Calcular Jornada Anual Teórica Individual (prorrateada)
    jornada_teorica_individual = 0
    @trabajador.historial_contratos.where("fecha_inicio_vigencia <= ? AND (fecha_fin_vigencia IS NULL OR fecha_fin_vigencia >= ?)", @fecha_fin_anio, @fecha_inicio_anio).each do |contrato|
      # Lógica de prorrateo por jornada parcial y duración...
      jornada_teorica_individual += (contrato.horas_semanales_contratadas / 40.0) * horas_convenio_base
    end

    # 3. Calcular Ajuste por Ausencias NO Retribuidas
    ids_ausencias_no_retribuidas = TipoAusencia.where(es_retribuida: false).pluck(:id)
    ajuste_ausencias_no_retribuidas = 0
    entradas_no_retribuidas = @trabajador.entrada_diarias.where(fecha: @fecha_inicio_anio..@fecha_fin_anio, tipo_ausencia_id: ids_ausencias_no_retribuidas)
    entradas_no_retribuidas.each do |entrada|
      ajuste_ausencias_no_retribuidas += @trabajador.horas_teoricas_para(entrada.fecha)
    end

    # 4. Calcular Horas Anuales Realizadas
    horas_trabajadas_totales = @trabajador.entrada_diarias.where(fecha: @fecha_inicio_anio..@fecha_fin_anio).sum(:horas_trabajadas)
    
    ids_ausencias_retribuidas = TipoAusencia.where(es_retribuida: true).pluck(:id)
    horas_ausencias_retribuidas = @trabajador.entrada_diarias.where(fecha: @fecha_inicio_anio..@fecha_fin_anio, tipo_ausencia_id: ids_ausencias_retribuidas).sum(:horas_ausencia)
    
    horas_anuales_realizadas = horas_trabajadas_totales + horas_ausencias_retribuidas

    # 5. Calcular el balance final
    jornada_anual_ajustada = jornada_teorica_individual - ajuste_ausencias_no_retribuidas
    balance_final = horas_anuales_realizadas - jornada_anual_ajustada

    # Devolver un hash con todos los resultados
    {
      horas_convenio: horas_convenio_base,
      jornada_anual_ajustada: jornada_anual_ajustada,
      horas_anuales_realizadas: horas_anuales_realizadas,
      balance_final: balance_final
    }
  end
end