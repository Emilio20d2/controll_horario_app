# app/controllers/admin/historial_contratos_controller.rb
class Admin::HistorialContratosController < ApplicationController
  # Asumo que tienes un before_action para autenticar administradores en tu ApplicationController
  # o en un Admin::ApplicationController si lo tuvieras.
  before_action :set_trabajador

  def new
    # Inicializamos un nuevo registro de historial para el trabajador,
    # pre-rellenando la fecha con el día de hoy para comodidad del usuario.
    @historial_contrato = @trabajador.historial_contratos.new(fecha_inicio_vigencia: Date.today)
  end

  def create
    @historial_contrato = @trabajador.historial_contratos.new(historial_contrato_params)

    # --- Lógica de negocio clave ---
    # Usamos una transacción para asegurar que todas las operaciones se completen
    # con éxito, o ninguna lo haga, manteniendo la consistencia de los datos.
    ActiveRecord::Base.transaction do
      # Buscamos el último contrato activo y le ponemos una fecha de fin.
      contrato_anterior = @trabajador.historial_contratos
                                     .where("fecha_inicio_vigencia < ?", @historial_contrato.fecha_inicio_vigencia)
                                     .where(fecha_fin_vigencia: nil)
                                     .order(fecha_inicio_vigencia: :desc)
                                     .first

      contrato_anterior&.update!(fecha_fin_vigencia: @historial_contrato.fecha_inicio_vigencia - 1.day)

      # Guardamos el nuevo contrato y actualizamos la jornada actual del trabajador.
      @historial_contrato.save!
      @trabajador.update!(jornada_semanal_actual: @historial_contrato.horas_semanales_contratadas)
    end

    redirect_to admin_trabajador_path(@trabajador), notice: 'La nueva jornada ha sido añadida correctamente.'
  rescue ActiveRecord::RecordInvalid
    # Si alguna de las operaciones dentro de la transacción falla (save! o update!),
    # se lanza una excepción, la transacción se revierte y renderizamos el formulario de nuevo.
    render :new, status: :unprocessable_entity
  end

  private

  def set_trabajador
    # El :trabajador_id viene de la ruta anidada /admin/trabajadores/:trabajador_id/...
    @trabajador = Trabajador.find(params[:trabajador_id])
  end

  def historial_contrato_params
    params.require(:historial_contrato).permit(:horas_semanales_contratadas, :fecha_inicio_vigencia)
  end
end