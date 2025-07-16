class FichajesController < ApplicationController
  def semanal
    @anio_actual = Date.today.year
    @semana_actual = Date.today.cweek

    @anio_seleccionado = params.fetch(:fecha, Date.today.to_s).to_date.year rescue @anio_actual
    @semana_seleccionada = params.fetch(:fecha, Date.today.to_s).to_date.cweek rescue @semana_actual

    begin
      @fecha_lunes = Date.commercial(@anio_seleccionado, @semana_seleccionada, 1)
    rescue Date::Error
      @fecha_lunes = Date.commercial(@anio_actual, @semana_actual, 1)
      flash.now[:alert] = "Fecha inválida. Mostrando semana actual."
    end
    
    @fechas_semana = (@fecha_lunes..(@fecha_lunes + 6.days)).to_a
    @params_semana_anterior = { fecha: (@fecha_lunes - 1.week).to_s }
    @params_semana_siguiente = { fecha: (@fecha_lunes + 1.week).to_s }

    @trabajadores = Trabajador.includes(
      :tipo_contrato, 
      :bolsa_horas_saldo,
      :historial_contratos,
      asignacion_turnos: :plantilla_horario
    ).order(:nombre)
    
    # Pasamos los tipos de ausencia con sus reglas a la vista
    @tipos_ausencia_options = TipoAusencia.order(:nombre).map do |ta|
      [
        ta.nombre, 
        ta.id, { 
          'data-abreviatura' => ta.abreviatura,
          'data-genera-deuda' => ta.genera_deuda_en_bolsa, 
          'data-es-retribuida' => ta.es_retribuida,
          'data-es-fraccionable' => ta.es_fraccionable,
          'data-afecta-bolsa' => ta.categoria_bolsa_afectada
        }
      ]
    end

    @festivos_semana_map = Festivo.where(fecha: @fechas_semana).index_by(&:fecha)

    @horas_teoricas_map = @trabajadores.each_with_object({}) do |trabajador, hash|
      hash[trabajador.id] = {}
      @fechas_semana.each do |fecha|
        hash[trabajador.id][fecha] = trabajador.horas_teoricas_para(fecha)
      end
    end

    @entradas_diarias_map = EntradaDiaria.where(
      trabajador_id: @trabajadores.map(&:id),
      fecha: @fechas_semana
    ).group_by(&:trabajador_id).transform_values { |entradas| entradas.index_by(&:fecha) }

    @semanas_procesadas = MovimientoBolsa.where(
      trabajador_id: @trabajadores.map(&:id),
      tipo_movimiento: 'BALANCE_SEMANAL',
      fecha_efectiva: @fecha_lunes + 6.days
    ).pluck(:trabajador_id)
  end

  # =================================================================
  # FASE 3: ENDPOINT DE API JSON
  # =================================================================
  # OBJETIVO: Proveer todos los datos y reglas necesarios para la vista
  # semanal en un único endpoint JSON, desacoplando el backend del frontend.
  #
  # @route GET /fichajes/semana_data
  # @params
  #   - year [String] - El año para el cual se solicitan los datos.
  #   - week_num [String] - El número de la semana para la cual se solicitan los datos.
  # @returns [JSON]
  def semana_data
    # Paso 3.1.a: Obtener y validar los parámetros de entrada y fechas.
    # Reutilizamos la lógica robusta de la acción 'semanal'.
    anio_seleccionado = params[:year].to_i
    semana_seleccionada = params[:week_num].to_i

    begin
      fecha_lunes = Date.commercial(anio_seleccionado, semana_seleccionada, 1)
    rescue Date::Error
      # Si la fecha es inválida, devolvemos un error claro en formato JSON.
      return render json: { error: "Fecha inválida. Proporcione un año y semana válidos." }, status: :bad_request
    end
    
    fechas_semana = (fecha_lunes..(fecha_lunes + 6.days)).to_a

    # Cargamos los trabajadores con todas sus asociaciones para evitar N+1 queries.
    trabajadores = Trabajador.includes(
      :tipo_contrato,
      :bolsa_horas_saldo,
      historial_contratos: :tipo_contrato,
      asignacion_turnos: :plantilla_horario # Necesario para horas_teoricas_para
    ).order(:nombre)

    # Paso 3.1.b: Serializar los datos de los trabajadores y sus reglas.
    # Transformamos el array de objetos Trabajador en un array de hashes JSON.
    trabajadores_data = trabajadores.map do |trabajador|
      contrato_vigente = trabajador.contrato_vigente_en(fecha_lunes)
      tipo_contrato = trabajador.tipo_contrato # Ya está pre-cargado

      {
        id: trabajador.id,
        nombre: trabajador.nombre,
        saldo_bolsa_horas: trabajador.bolsa_horas_saldo&.total_horas&.to_f || 0.0,
        reglas_contrato: {
          acumula_festivo_trabajado: tipo_contrato.acumula_festivo_trabajado_en_bolsa,
          acumula_festivo_libranza: tipo_contrato.acumula_festivo_en_libranza
        },
        contrato_vigente: {
          # Usamos un valor por defecto de 5 si el dato no existiera,
          # pero este campo debería ser obligatorio en el formulario de contratos.
          dias_laborables_semana: contrato_vigente&.dias_laborables_semana_contratados || 5,
          horas_semanales: contrato_vigente&.horas_semanales_contratadas&.to_f || 0.0
        }
      }
    end

    # Paso 3.1.c: Serializar las reglas globales (Tipos de Ausencia y Festivos).
    # Serializamos los tipos de ausencia de una forma limpia para el frontend.
    tipos_ausencia_data = TipoAusencia.order(:nombre).map do |ta|
      {
        id: ta.id,
        nombre: ta.nombre,
        abreviatura: ta.abreviatura,
        genera_deuda: ta.genera_deuda_en_bolsa,
        es_retribuida: ta.es_retribuida,
        es_fraccionable: ta.es_fraccionable,
        bolsa_afectada: ta.categoria_bolsa_afectada
      }
    end

    # Creamos un hash de festivos, donde la clave es la fecha (YYYY-MM-DD).
    festivos_semana_data = Festivo.where(fecha: fechas_semana).each_with_object({}) do |festivo, hash|
      hash[festivo.fecha.to_s] = {
        descripcion: festivo.descripcion,
        apertura_autorizada: festivo.apertura_autorizada
      }
    end

    # Paso 3.1.d: Serializar los datos pre-calculados (horas teóricas y entradas guardadas).
    # Replicamos la lógica de la acción 'semanal' para generar los mapas de datos.

    # Mapa de horas teóricas: { trabajador_id => { "YYYY-MM-DD" => horas, ... } }
    horas_teoricas_map = trabajadores.each_with_object({}) do |trabajador, hash|
      hash[trabajador.id] = {}
      fechas_semana.each do |fecha|
        hash[trabajador.id][fecha.to_s] = trabajador.horas_teoricas_para(fecha)
      end
    end

    # Mapa de entradas diarias guardadas: { trabajador_id => { "YYYY-MM-DD" => { ...datos... }, ... } }
    entradas_diarias_map = EntradaDiaria.where(
      trabajador_id: trabajadores.map(&:id),
      fecha: fechas_semana
    ).group_by(&:trabajador_id).transform_values do |entradas|
      entradas.index_by(&:fecha).transform_keys(&:to_s).transform_values do |entrada|
        {
          horas_trabajadas: entrada.horas_trabajadas&.to_f,
          horas_ausencia: entrada.horas_ausencia&.to_f,
          horas_comp_pagadas: entrada.horas_comp_pagadas&.to_f,
          tipo_ausencia_id: entrada.tipo_ausencia_id,
          pago_doble: entrada.pago_doble
        }
      end
    end

    # Array con los IDs de los trabajadores cuya semana ya ha sido procesada y guardada.
    semanas_procesadas_ids = MovimientoBolsa.where(
      trabajador_id: trabajadores.map(&:id),
      tipo_movimiento: 'balance_semanal',
      fecha_efectiva: fecha_lunes + 6.days
    ).pluck(:trabajador_id)

    render json: {
      fechas_semana: fechas_semana.map(&:to_s),
      trabajadores: trabajadores_data,
      tipos_ausencia: tipos_ausencia_data,
      festivos_semana: festivos_semana_data,
      horas_teoricas: horas_teoricas_map,
      entradas_diarias: entradas_diarias_map,
      semanas_procesadas_ids: semanas_procesadas_ids
    }
  end

  # ... (La acción 'procesar_fila' para el guardado definitivo se mantiene igual) ...
end