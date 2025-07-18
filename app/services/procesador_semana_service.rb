# /home/emilio/control_horario_app/app/services/procesador_semana_service.rb
class ProcesadorSemanaService
  CAT_HORAS = :horas
  CAT_FESTIVOS = :festivos
  CAT_LIBRANZA = :libranza

  TIPO_CREDITO = :credito
  TIPO_DEBITO = :debito
  TIPO_BALANCE = :balance_semanal

  def initialize(trabajador, anio, semana, datos_dias)
    @trabajador = trabajador
    @anio = anio.to_i
    @semana = semana.to_i
    @datos_dias = datos_dias
    @fecha_inicio_semana = Date.commercial(@anio, @semana, 1)
    @fecha_fin_semana = @fecha_inicio_semana + 6.days
  end

  def self.call(*args, simulacion: false)
    new(*args).procesar(simulacion: simulacion)
  end

  def procesar(simulacion: false)
    # 1. PREPARACIÓN DE DATOS
    prepare_context_data

    # 2. CÁLCULO DE BALANCES
    balances = calcular_balances_semanales

    # 3. GUARDADO EN BASE DE DATOS (si no es simulación)
    return { success: true, message: "Simulación completada." } if simulacion

    guardar_movimientos(balances)
    { success: true, message: "Semana procesada y guardada." }
  end

  private

  def prepare_context_data
    @tipo_contrato = @trabajador.tipo_contrato
    @contrato_acumula_festivo_trabajado = @tipo_contrato&.acumula_festivo_trabajado_en_bolsa? || false
    @contrato_acumula_festivo_libranza = @tipo_contrato&.acumula_festivo_en_libranza? || false
    @jornada_semanal_contratada = @trabajador.jornada_semanal_actual || BigDecimal("0.0")

    @mapa_festivos = Festivo.where(fecha: @fecha_inicio_semana..@fecha_fin_semana).index_by(&:fecha)
    ids_ausencias = @datos_dias.values.map { |d| d['tipo_ausencia_id'] }.compact.uniq
    @mapa_ausencias = TipoAusencia.where(id: ids_ausencias).index_by(&:id)
  end

  def calcular_balances_semanales
    # INICIALIZACIÓN DE ACUMULADORES SEMANALES
    total_horas_teoricas = BigDecimal("0.0")
    horas_reales_computables = BigDecimal("0.0")
    impacto_bolsa_festivos = BigDecimal("0.0")
    impacto_bolsa_libranza = BigDecimal("0.0")
    horas_consumidas_bolsa_principal = BigDecimal("0.0")

    # BUCLE DE CÁLCULO DIARIO
    (@fecha_inicio_semana..@fecha_fin_semana).each do |fecha|
      datos_dia = @datos_dias[fecha.to_s] || {}
      h_teo_dia = BigDecimal(@trabajador.horas_teoricas_para(fecha).to_s)
      total_horas_teoricas += h_teo_dia

      # Lógica de Ausencias
      ausencia = @mapa_ausencias[datos_dia['tipo_ausencia_id'].to_i] if datos_dia['tipo_ausencia_id'].present?
      horas_ausencia_dia = BigDecimal("0.0")
      es_ausencia_dia_completo = false
      if ausencia
        if ausencia.es_fraccionable?
          horas_ausencia_dia = BigDecimal(datos_dia['horas_ausencia'].presence || "0.0")
        else
          horas_ausencia_dia = h_teo_dia
          es_ausencia_dia_completo = true
        end
      end

      # Leer datos del día
      h_trab_dia = es_ausencia_dia_completo ? BigDecimal("0.0") : BigDecimal(datos_dia['horas_trabajadas'].presence || h_teo_dia.to_s)
      h_comp_pagadas = BigDecimal(datos_dia['horas_comp_pagadas'].presence || "0.0")
      pago_doble = datos_dia['pago_doble'] == 'on'
      es_festivo = @mapa_festivos.key?(fecha)

      # --- Aplicar las 4 fórmulas ---

      # Impacto Bolsa HORAS (parcial)
      horas_para_bolsa_principal = pago_doble ? BigDecimal("0.0") : (h_trab_dia - h_comp_pagadas)
      va_a_bolsa_festivos = es_festivo && !pago_doble && @contrato_acumula_festivo_trabajado && h_trab_dia > 0
      horas_reales_computables += horas_para_bolsa_principal unless va_a_bolsa_festivos

      # Impacto Bolsa FESTIVOS
      impacto_bolsa_festivos += (h_trab_dia - h_comp_pagadas) if va_a_bolsa_festivos
      impacto_bolsa_festivos -= horas_ausencia_dia if ausencia&.categoria_bolsa_afectada == 'festivos'

      # Impacto Bolsa LIBRANZA
      impacto_bolsa_libranza += @trabajador.horas_para_bolsa_libranza(fecha) if es_festivo && h_teo_dia.zero? && @contrato_acumula_festivo_libranza
      impacto_bolsa_libranza -= horas_ausencia_dia if ausencia&.categoria_bolsa_afectada == 'libranza'

      # Consumo de bolsa principal
      horas_consumidas_bolsa_principal += horas_ausencia_dia if ausencia&.categoria_bolsa_afectada == 'horas'
    end

    # CÁLCULO FINAL
    impacto_bolsa_horas = horas_reales_computables - total_horas_teoricas - horas_consumidas_bolsa_principal

    {
      horas: impacto_bolsa_horas,
      festivos: impacto_bolsa_festivos,
      libranza: impacto_bolsa_libranza
    }
  end

  def guardar_movimientos(balances)
    movimientos_generados = []

    # Generamos los movimientos que se guardarán en la BD
    if @tipo_contrato&.afecta_bolsa_horas? && balances[:horas].nonzero?
      movimientos_generados << { tipo: TIPO_BALANCE, cat: CAT_HORAS, horas: balances[:horas], fecha: @fecha_fin_semana, concepto: "Balance semana #{@semana}/#{@anio}" }
    end

    if balances[:festivos].nonzero?
      tipo_mov = balances[:festivos] > 0 ? TIPO_CREDITO : TIPO_DEBITO
      concepto = balances[:festivos] > 0 ? "Acum. festivos trabajados S.#{@semana}" : "Uso bolsa festivos S.#{@semana}"
      movimientos_generados << { tipo: tipo_mov, cat: CAT_FESTIVOS, horas: balances[:festivos], fecha: @fecha_fin_semana, concepto: concepto }
    end

    if balances[:libranza].nonzero?
      tipo_mov = balances[:libranza] > 0 ? TIPO_CREDITO : TIPO_DEBITO
      concepto = balances[:libranza] > 0 ? "Acum. festivos en libranza S.#{@semana}" : "Uso bolsa libranza S.#{@semana}"
      movimientos_generados << { tipo: tipo_mov, cat: CAT_LIBRANZA, horas: balances[:libranza], fecha: @fecha_fin_semana, concepto: concepto }
    end

    ActiveRecord::Base.transaction do
      # Idempotencia: Borrar movimientos antiguos de esta semana
      @trabajador.movimiento_bolsas
                 .where(fecha_efectiva: @fecha_fin_semana, tipo_movimiento: [TIPO_BALANCE, TIPO_CREDITO, TIPO_DEBITO])
                 .delete_all

      movimientos_generados.each do |mov_data|
        MovimientoBolsa.create!(
          trabajador: @trabajador,
          fecha_efectiva: mov_data[:fecha],
          cantidad_horas: mov_data[:horas],
          tipo_movimiento: mov_data[:tipo],
          categoria_bolsa_afectada: mov_data[:cat],
          concepto: mov_data[:concepto]
        )
      end

      # Recalcular saldos totales
      saldos_calculados = @trabajador.movimiento_bolsas
                                     .group(:categoria_bolsa_afectada)
                                     .sum(:cantidad_horas)

      saldo_obj = BolsaHorasSaldo.find_or_create_by!(trabajador: @trabajador)
      saldo_obj.update!(
        saldo_bolsa_horas: saldos_calculados[CAT_HORAS.to_s] || 0,
        saldo_bolsa_festivos: saldos_calculados[CAT_FESTIVOS.to_s] || 0,
        saldo_bolsa_libranza: saldos_calculados[CAT_LIBRANZA.to_s] || 0
      )

      # Actualizar historial anual
      ActualizadorHistorialAnualService.call(@trabajador, @anio)
    end
  end
end
