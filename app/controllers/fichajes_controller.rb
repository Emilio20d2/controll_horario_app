# /home/emilio/control_horario_app/app/controllers/fichajes_controller.rb
class FichajesController < ApplicationController
  def semanal
    # --- Parte 1: Preparación de Fechas y Datos Base ---
    @fecha_seleccionada = if params[:fecha].present?
                            begin
                              Date.parse(params[:fecha])
                            rescue Date::Error
                              flash.now[:alert] = "Fecha inválida. Mostrando semana actual."
                              Date.today
                            end
                          else
                            Date.today
                          end
    @anio_seleccionado = @fecha_seleccionada.cwyear
    @semana_seleccionada = @fecha_seleccionada.cweek
    @fecha_lunes = @fecha_seleccionada.beginning_of_week(:monday)
    @fecha_fin_semana = @fecha_lunes + 6.days
    @fechas_semana = (@fecha_lunes..@fecha_fin_semana).to_a

    @trabajadores = Trabajador.includes(:tipo_contrato, :bolsa_horas_saldo, asignacion_turnos: :plantilla_horario).order(:nombre)
    @tipos_ausencia = TipoAusencia.order(:nombre)
    @festivos_semana = Festivo.where(fecha: @fechas_semana).index_by(&:fecha)

    # --- Parte 2: Precarga de Datos para Optimizar la Vista ---
    tipos_ausencia_con_limite = @tipos_ausencia.select { |ta| ta.limite_horas_anuales.to_f > 0 }
    @horas_usadas_map = if tipos_ausencia_con_limite.any?
                         EntradaDiaria
                           .where(trabajador: @trabajadores, tipo_ausencia: tipos_ausencia_con_limite, fecha: Date.new(@anio_seleccionado, 1, 1)...@fecha_lunes)
                           .group(:trabajador_id, :tipo_ausencia_id)
                           .sum(:horas_ausencia)
                       else
                         {}
                       end

    @horas_teoricas_map = @trabajadores.each_with_object({}) do |trabajador, map|
      map[trabajador.id] = {}
      # Ordenamos las asignaciones en memoria para encontrar la correcta para cada día.
      # Esto evita una consulta N+1 dentro del bucle de fechas.
      sorted_asignaciones = trabajador.asignacion_turnos.sort_by(&:fecha_inicio).reverse

      dias_semana_map = { 1 => 'lunes', 2 => 'martes', 3 => 'miercoles', 4 => 'jueves', 5 => 'viernes', 6 => 'sabado', 0 => 'domingo' }

      @fechas_semana.each do |fecha|
        # Buscamos la asignación activa para la fecha en la colección ya cargada.
        asignacion = sorted_asignaciones.find { |a| a.fecha_inicio <= fecha }

        if asignacion&.plantilla_horario
          plantilla = asignacion.plantilla_horario
          semanas_desde_referencia = ((fecha - plantilla.fecha_referencia) / 7).to_i
          turno_num = (semanas_desde_referencia % 4) + 1
          dia_semana_key = dias_semana_map[fecha.wday]
          horas = plantilla.horario.dig("turno#{turno_num}", dia_semana_key)
          map[trabajador.id][fecha] = BigDecimal(horas || 0)
        else
          map[trabajador.id][fecha] = BigDecimal("0.0")
        end
      end
    end

    @entradas_diarias_map = EntradaDiaria.where(
      trabajador: @trabajadores,
      fecha: @fechas_semana
    ).group_by(&:trabajador_id).transform_values { |entradas| entradas.index_by(&:fecha) }

    @semanas_procesadas = MovimientoBolsa.where(
      trabajador: @trabajadores,
      tipo_movimiento: 'balance_semanal',
      fecha_efectiva: @fecha_fin_semana
    ).pluck(:trabajador_id)
  end

  # --- Parte 3: La Acción de Guardado (Refactorizada) ---
  def procesar_fila
    set_processing_context

    ActiveRecord::Base.transaction do
      process_daily_entries
      ProcesadorSemanaService.call(@trabajador, @anio, @semana, @datos_dias_trabajador, simulacion: false)
    end

    redirect_to fichajes_semanal_path(fecha: @fecha_lunes), notice: "Semana guardada correctamente para #{@trabajador.nombre}."
  rescue ArgumentError, ActiveRecord::RecordNotFound => e
    redirect_to fichajes_semanal_path, alert: e.message
  rescue => e
    redirect_to fichajes_semanal_path(fecha: @fecha_lunes || params[:fecha]), alert: "Error al guardar: #{e.message}"
  end

  private

  def set_processing_context
    fecha_str = params[:fecha]
    trabajador_id = params[:trabajador_a_procesar]

    raise ArgumentError, "Faltan parámetros para procesar la fila." unless fecha_str.present? && trabajador_id.present?

    @fecha_lunes = Date.parse(fecha_str)
    @fechas_semana = (@fecha_lunes..@fecha_lunes + 6.days).to_a
    @anio = @fecha_lunes.cwyear
    @semana = @fecha_lunes.cweek
    @trabajador = Trabajador.find(trabajador_id)
    @datos_dias_trabajador = daily_data_params
  end

  def daily_data_params
    params.require(:dias).require(@trabajador.id.to_s).permit(
      @fechas_semana.map(&:to_s) => [
        :horas_trabajadas, :tipo_ausencia_id, :horas_ausencia,
        :motivo, :pago_doble, :horas_comp_pagadas
      ]
    ).to_h
  end

  def process_daily_entries
    @datos_dias_trabajador.each do |fecha_str, datos_dia|
      fecha = Date.parse(fecha_str)
      atributos_limpios = datos_dia.transform_values { |v| v.blank? ? nil : v }

      if atributos_limpios.values.all?(&:nil?)
        EntradaDiaria.where(trabajador: @trabajador, fecha: fecha).destroy_all
      else
        entrada = EntradaDiaria.find_or_initialize_by(trabajador: @trabajador, fecha: fecha)
        entrada.update!(atributos_limpios)
      end
    end
  end
end
