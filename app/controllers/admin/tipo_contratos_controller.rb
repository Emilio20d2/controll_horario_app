# frozen_string_literal: true

class Admin::TipoContratosController < ApplicationController
  layout 'admin'
  before_action :set_tipo_contrato, only: %i[edit update]

  def index
    @tipos_contrato = TipoContrato.order(:nombre)
  end

  def new
    @tipo_contrato = TipoContrato.new
  end

  def create
    @tipo_contrato = TipoContrato.new(tipo_contrato_params)
    if @tipo_contrato.save
      redirect_to admin_tipo_contratos_path, notice: 'Tipo de contrato creado con éxito.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @tipo_contrato es asignado por el before_action
  end

  def update
    if @tipo_contrato.update(tipo_contrato_params)
      redirect_to admin_tipo_contratos_path, notice: 'Tipo de contrato actualizado con éxito.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_tipo_contrato
    @tipo_contrato = TipoContrato.find(params[:id])
  end

  def tipo_contrato_params
    params.require(:tipo_contrato).permit(:nombre, :afecta_bolsa_ordinaria,
                                          :acumula_festivo_trabajado_en_bolsa,
                                          :acumula_festivo_en_libranza)
  end
end