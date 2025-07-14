# app/controllers/admin/asignacion_turnos_controller.rb
class Admin::AsignacionTurnosController < ApplicationController
  before_action :set_trabajador

  # La acción `new` ahora también carga las plantillas de horario existentes
  # para que puedan mostrarse en un selector en el formulario.
  def new
    # Preparamos una nueva asignación con la fecha de hoy por defecto.
    @asignacion_turno = @trabajador.asignacion_turnos.new(fecha_inicio: Date.today)

    # Buscamos la asignación activa actual para pre-rellenar la parrilla del formulario.
    asignacion_actual = @trabajador.asignacion_turnos.includes(:plantilla_horario).order(fecha_inicio: :desc).first

    # Si hay una asignación, usamos su horario. Si no, usamos un hash vacío para evitar el error.
    # Esto soluciona el error "undefined method `dig' for nil".
    @horario_actual = asignacion_actual&.plantilla_horario&.horario || {}
  end

  def create
    # Extraemos los datos del horario de la parrilla y la fecha de inicio.
    horario_params = params.fetch(:horario, {}).permit!.to_h
    fecha_inicio = params.dig(:asignacion_turno, :fecha_inicio)

    ActiveRecord::Base.transaction do
      # 1. Crear una nueva Plantilla de Horario, única para este cambio.
      # El nombre es descriptivo para poder identificarla en el futuro si es necesario.
      nueva_plantilla = PlantillaHorario.create!(
        nombre: "Horario para #{@trabajador.nombre} desde #{fecha_inicio}",
        horario: horario_params,
        fecha_referencia: Date.parse(fecha_inicio) # Usamos la fecha de inicio como referencia para la rotación.
      )

      # Buscamos la asignación de horario anterior que esté activa (sin fecha_fin).
      asignacion_anterior = @trabajador.asignacion_turnos
                                       .where("fecha_inicio < ?", fecha_inicio)
                                       .where(fecha_fin: nil)
                                       .order(fecha_inicio: :desc)
                                       .first

      # Si existe, le ponemos una fecha de fin (el día antes de que empiece la nueva).
      asignacion_anterior&.update!(fecha_fin: Date.parse(fecha_inicio) - 1.day)

      # 2. Crear la nueva AsignacionTurno que conecta al trabajador con la nueva plantilla.
      @asignacion_turno = @trabajador.asignacion_turnos.create!(
        plantilla_horario: nueva_plantilla,
        fecha_inicio: fecha_inicio
      )
    end

    redirect_to admin_trabajador_path(@trabajador), notice: 'El nuevo horario ha sido asignado correctamente.'
  rescue ActiveRecord::RecordInvalid => e
    # Si algo falla, preparamos los datos de nuevo y renderizamos el formulario con el error.
    @horario_actual = horario_params
    @asignacion_turno = @trabajador.asignacion_turnos.new(fecha_inicio: fecha_inicio)
    @asignacion_turno.errors.add(:base, "Error al guardar: #{e.message}")
    render :new, status: :unprocessable_entity
  end

  private

  def set_trabajador
    @trabajador = Trabajador.find(params[:trabajador_id])
  end

  def asignacion_turno_params
    # Ahora solo necesitamos la fecha de inicio del formulario principal.
    params.require(:asignacion_turno).permit(:fecha_inicio)
  end
end