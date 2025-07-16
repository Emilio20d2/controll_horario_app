# app/controllers/admin/historiales_jornada_anual_controller.rb
class Admin::HistorialJornadaAnualesController < ApplicationController
  before_action :set_trabajador

  # POST /admin/trabajadores/:trabajador_id/historiales_jornada_anual
  def create
    anio = params[:anio].to_i

    # 1. Calcular el balance anual usando el método del modelo.
    calculo = @trabajador.calculo_jornada_anual(anio)

    # 2. Buscar si ya existe un registro para ese año y trabajador, o inicializar uno nuevo.
    historial = @trabajador.historial_jornada_anuales.find_or_initialize_by(anio: anio)

    # 3. Asignar los valores calculados y guardar.
    historial.assign_attributes(
      jornada_anual_ajustada: calculo[:horas_teoricas] * 60,
      horas_anuales_realizadas: (calculo[:horas_reales] * 60).round,
      balance_final: calculo[:balance]
    )

    if historial.save
      redirect_to admin_trabajador_path(@trabajador), notice: "Balance anual para el año #{anio} guardado correctamente."
    else
      redirect_to admin_trabajador_path(@trabajador), alert: "No se pudo guardar el balance: #{historial.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_trabajador
    @trabajador = Trabajador.find(params[:trabajador_id])
  end
end