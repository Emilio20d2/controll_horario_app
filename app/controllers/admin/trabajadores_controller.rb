class Admin::TrabajadoresController < ApplicationController
  before_action :set_trabajador, only: [:show, :edit, :update, :destroy]

  def index
    @trabajadores = Trabajador.all.order(:nombre)
  end

  def show
    @asignaciones_turno = @trabajador.asignacion_turnos.includes(:plantilla_horario).order(fecha_inicio: :desc)
    @historial_contratos = @trabajador.historial_contratos.order(fecha_inicio_vigencia: :desc)
    @resumen_jornadas = @trabajador.resumen_jornadas_anuales
    
    @anio_actual = Date.today.year
    # Calculamos la jornada anual para el año actual y la pasamos a la vista.
    @calculo_jornada_actual = @trabajador.calculo_jornada_anual(@anio_actual)
  end

  def new
    @trabajador = Trabajador.new
  end

  def edit
  end

  def create
    @trabajador = Trabajador.new(trabajador_params)
    if @trabajador.save
      redirect_to admin_trabajador_path(@trabajador), notice: 'Trabajador creado con éxito.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @trabajador.update(trabajador_params)
      redirect_to admin_trabajador_path(@trabajador), notice: 'Trabajador actualizado con éxito.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trabajador.destroy
    redirect_to admin_trabajadores_url, notice: 'Trabajador eliminado con éxito.'
  end

  private
    def set_trabajador
      @trabajador = Trabajador.find(params[:id])
    end

    def trabajador_params
      params.require(:trabajador).permit(
        :nombre,
        :tipo_contrato_id,
        :jornada_semanal_actual
      )
    end
end
