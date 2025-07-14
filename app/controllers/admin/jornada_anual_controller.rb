# frozen_string_literal: true

class Admin::JornadaAnualController < ApplicationController
  layout 'admin'
  before_action :set_configuracion, only: %i[edit update destroy]

  def index
    @configuraciones = ConfiguracionJornada.order(anio: :desc)
    @configuracion = ConfiguracionJornada.new
  end

  def create
    @configuracion = ConfiguracionJornada.new(configuracion_params)
    if @configuracion.save
      redirect_to admin_configuracion_jornadas_path, notice: 'Configuración de jornada anual creada con éxito.'
    else
      @configuraciones = ConfiguracionJornada.order(anio: :desc)
      flash.now[:alert] = 'No se pudo crear la configuración. Revisa los errores.'
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    # El before_action ya ha encontrado la configuración a editar.
  end

  def update
    if @configuracion.update(configuracion_params)
      redirect_to admin_configuracion_jornadas_path, notice: 'Configuración actualizada con éxito.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @configuracion.destroy
    redirect_to admin_configuracion_jornadas_path, notice: 'Configuración eliminada con éxito.', status: :see_other
  end

  private

  def set_configuracion
    @configuracion = ConfiguracionJornada.find(params[:id])
  end

  def configuracion_params
    params.require(:configuracion_jornada).permit(:anio, :horas_maximas, :jornada_semanal_maxima)
  end
end