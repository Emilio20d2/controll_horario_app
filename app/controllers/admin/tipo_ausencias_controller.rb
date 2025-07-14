# Este controlador gestiona el CRUD (Crear, Leer, Actualizar, Eliminar)
# para los Tipos de Ausencia desde el panel de administración.
class Admin::TipoAusenciasController < ApplicationController
  layout 'admin'
  before_action :set_tipo_ausencia, only: %i[edit update destroy]

  # GET /admin/tipo_ausencias
  def index
    @tipo_ausencias = TipoAusencia.all.order(:nombre)
  end

  # GET /admin/tipo_ausencias/new
  def new
    @tipo_ausencia = TipoAusencia.new
  end

  # POST /admin/tipo_ausencias
  def create
    @tipo_ausencia = TipoAusencia.new(tipo_ausencia_params)
    if @tipo_ausencia.save
      redirect_to admin_tipo_ausencias_path, notice: 'Tipo de ausencia creado con éxito.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/tipo_ausencias/:id/edit
  def edit
  end

  # PATCH/PUT /admin/tipo_ausencias/:id
  def update
    if @tipo_ausencia.update(tipo_ausencia_params)
      redirect_to admin_tipo_ausencias_path, notice: 'Tipo de ausencia actualizado con éxito.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/tipo_ausencias/:id
  def destroy
    if @tipo_ausencia.destroy
      redirect_to admin_tipo_ausencias_path, notice: 'Tipo de ausencia eliminado con éxito.', status: :see_other
    else
      # El `dependent: :restrict_with_error` en el modelo añadirá un error.
      redirect_to admin_tipo_ausencias_path, alert: @tipo_ausencia.errors.full_messages.join(', ')
    end
  end

  private

  def set_tipo_ausencia
    @tipo_ausencia = TipoAusencia.find(params[:id])
  end

  def tipo_ausencia_params
    # Usamos los parámetros definidos en la nueva estructura del modelo.
    params.require(:tipo_ausencia).permit(
      :nombre,
      :abreviatura,
      :es_fraccionable,
      :es_retribuida,
      :categoria_bolsa_afectada,
      :genera_deuda_en_bolsa,
      :limite_horas_anuales
    )
  end
end