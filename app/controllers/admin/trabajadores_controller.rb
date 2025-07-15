lass Admin::TrabajadoresController < ApplicationController
  before_action :set_trabajador, only: [:show, :edit, :update, :destroy]

  def index
    @trabajadores = Trabajador.all.order(:nombre)
  end

  def show
    @asignaciones_turno = @trabajador.asignacion_turnos.includes(:plantilla_horario).order(fecha_inicio: :desc)
    @historial_contratos = @trabajador.historial_contratos.order(fecha_inicio_vigencia: :desc)
    @historial_jornada_anual_registros = @trabajador.historial_jornada_anuals.order(anio: :desc)
    
    @anio_actual = Date.today.year
    # La lógica para @calculo_jornada_actual se añadirá cuando el Service Object esté completo.
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
      params.require(:trabajador).permit(:nombre, :tipo_contrato_id, :activo)
    end
end
