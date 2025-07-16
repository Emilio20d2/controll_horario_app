# /home/emilio/control_horario_app/app/controllers/admin/historial_contratos_controller.rb

class Admin::HistorialContratosController < ApplicationController
  before_action :set_trabajador

  def new
    @historial_contrato = @trabajador.historial_contratos.new(
      # Pre-rellenamos el campo con el valor por defecto para una mejor UX.
      dias_laborables_semana_contratados: 5
    )
  end

  def create
    @historial_contrato = @trabajador.historial_contratos.new(historial_contrato_params)

    if @historial_contrato.save
      redirect_to admin_trabajador_path(@trabajador), notice: 'La nueva jornada ha sido guardada correctamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_trabajador
    @trabajador = Trabajador.find(params[:trabajador_id])
  end

  # Strong Parameters: Filtramos los atributos permitidos para el modelo
  # HistorialContrato por seguridad.
  def historial_contrato_params
    params.require(:historial_contrato).permit(
      :fecha_inicio_vigencia,
      :horas_semanales_contratadas,
      :dias_laborables_semana_contratados # <-- Añadimos el nuevo campo a la lista segura.
    )
  end
end
