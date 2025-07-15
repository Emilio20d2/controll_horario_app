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

  # ... (La acción 'procesar_fila' para el guardado definitivo se mantiene igual) ...
end