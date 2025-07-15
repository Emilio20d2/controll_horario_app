class Admin::TrabajadoresController < ApplicationController
  before_action :set_trabajador, only: [:show, :edit, :update, :destroy]

  # GET /admin/trabajadores
  def index
    @trabajadores = Trabajador.all.order(:nombre)
  end

  # GET /admin/trabajadores/1
  def show
    # Preparamos las colecciones de datos para la vista de la ficha
    @asignaciones_turno = @trabajador.asignacion_turnos.includes(:plantilla_horario).order(fecha_inicio: :desc)
    @historial_contratos = @trabajador.historial_contratos.order(fecha_inicio_vigencia: :desc)
    @historial_jornada_anual_registros = @trabajador.historial_jornada_anuals.order(anio: :desc)
    
    # Usamos el Service Object para obtener el cálculo de la jornada anual
    @anio_actual = Date.today.year
    # Asumimos que el Service Object existe y funciona.
    # @calculo_jornada_actual = CalculadorJornadaAnualService.call(trabajador: @trabajador, anio: @anio_actual)
  end

  # GET /admin/trabajadores/new
  def new
    @trabajador = Trabajador.new
  end

  # GET /admin/trabajadores/1/edit
  def edit
    # El before_action :set_trabajador ya ha encontrado el trabajador
  end

  # POST /admin/trabajadores
  def create
    @trabajador = Trabajador.new(trabajador_params)

    if @trabajador.save
      redirect_to admin_trabajador_path(@trabajador), notice: 'Trabajador creado con éxito.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/trabajadores/1
  def update
    if @trabajador.update(trabajador_params)
      redirect_to admin_trabajador_path(@trabajador), notice: 'Trabajador actualizado con éxito.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/trabajadores/1
  def destroy
    @trabajador.destroy
    redirect_to admin_trabajadores_url, notice: 'Trabajador eliminado con éxito.'
  end

  private
    # Usa callbacks para compartir configuración común o restricciones entre acciones.
    def set_trabajador
      @trabajador = Trabajador.find(params[:id])
    end

    # Permite solo una lista de parámetros de confianza.
    def trabajador_params
      params.require(:trabajador).permit(:nombre, :tipo_contrato_id, :activo) # Ajustar según los campos del formulario
    end
end
