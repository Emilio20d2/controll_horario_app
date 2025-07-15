class FichajesController < ApplicationController
  def semanal
    @anio_actual = Date.today.year
    @semana_actual = Date.today.cweek

    if params[:fecha].present?
      fecha = Date.parse(params[:fecha]) rescue Date.today
      @anio_seleccionado = fecha.cwyear
      @semana_seleccionada = fecha.cweek
    else
      @anio_seleccionado = params.fetch(:anio, @anio_actual).to_i
      @semana_seleccionada = params.fetch(:semana, @semana_actual).to_i
    end

    begin
      @fecha_lunes = Date.commercial(@anio_seleccionado, @semana_seleccionada, 1)
    rescue Date::Error
      @fecha_lunes = Date.commercial(@anio_actual, @semana_actual, 1)
      flash.now[:alert] = "Fecha inválida. Mostrando semana actual."
    end
    
    @fechas_semana = (@fecha_lunes..(@fecha_lunes + 6.days)).to_a

    @trabajadores = Trabajador.includes(
      :tipo_contrato, 
      :bolsa_horas_saldo,
      :historial_contratos,
      asignacion_turnos: :plantilla_horario
    ).order(:nombre)
    
    @tipos_ausencia = TipoAusencia.all.map do |ta|
      [ta.nombre, ta.id, {
        'data-genera-deuda' => ta.genera_deuda_en_bolsa,
        'data-es-retribuida' => ta.es_retribuida,
        'data-fraccionable' => ta.es_fraccionable,
        'data-abreviatura' => ta.abreviatura,
        'data-nombre' => ta.nombre
      }]
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

  def procesar_fila
    redirect_to confirmacion_semanal_path(anio: params[:anio], semana: params[:semana]), notice: "Fila procesada."
  end
end
