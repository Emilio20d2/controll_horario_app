# frozen_string_literal: true

class Admin::FestivosController < ApplicationController
  layout 'admin'
  before_action :set_festivo, only: %i[edit update destroy]

  def index
    @festivos = Festivo.order(fecha: :desc)
  end

  def new
    @festivo = Festivo.new
  end

  def edit
    # El before_action ya ha encontrado el festivo a editar.
  end

  def create
    @festivo = Festivo.new(festivo_params)
    if @festivo.save
      redirect_to admin_festivos_path, notice: 'Festivo creado con éxito.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @festivo.update(festivo_params)
      redirect_to admin_festivos_path, notice: 'Festivo actualizado con éxito.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @festivo.destroy
    redirect_to admin_festivos_path, notice: 'Festivo eliminado con éxito.', status: :see_other
  end

  private

  def set_festivo
    @festivo = Festivo.find(params[:id])
  end

  def festivo_params
    params.require(:festivo).permit(:fecha, :descripcion, :apertura_autorizada)
  end
end