# app/controllers/admin/movimiento_bolsas_controller.rb
class Admin::MovimientoBolsasController < ApplicationController
  before_action :set_trabajador

  def new
    @movimiento = @trabajador.movimiento_bolsas.new(fecha_efectiva: Date.today)
    # Preparamos las opciones para el desplegable de categorías
    @categorias_bolsa = MovimientoBolsa.categoria_bolsa_afectadas.keys
  end

  def create
    @movimiento = @trabajador.movimiento_bolsas.new(movimiento_params)

    # Determinamos si es un crédito (suma) o un débito (resta)
    cantidad = BigDecimal(params.dig(:movimiento_bolsa, :cantidad_horas) || "0")
    @movimiento.tipo_movimiento = cantidad >= 0 ? :credito : :debito

    ActiveRecord::Base.transaction do
      @movimiento.save!

      # Tras guardar, recalculamos TODOS los saldos para asegurar la consistencia.
      # Esta es la forma más robusta de mantener los datos correctos.
      saldo = @trabajador.bolsa_horas_saldo || @trabajador.create_bolsa_horas_saldo!
      saldo.update!(
        horas: @trabajador.movimiento_bolsas.where(categoria_bolsa_afectada: :horas).sum(:cantidad_horas),
        festivos: @trabajador.movimiento_bolsas.where(categoria_bolsa_afectada: :festivos).sum(:cantidad_horas),
        libranza: @trabajador.movimiento_bolsas.where(categoria_bolsa_afectada: :libranza).sum(:cantidad_horas)
      )
    end

    redirect_to admin_trabajador_path(@trabajador), notice: 'Ajuste manual añadido correctamente.'
  rescue ActiveRecord::RecordInvalid
    @categorias_bolsa = MovimientoBolsa.categoria_bolsa_afectadas.keys
    render :new, status: :unprocessable_entity
  end

  private

  def set_trabajador
    @trabajador = Trabajador.find(params[:trabajador_id])
  end

  def movimiento_params
    params.require(:movimiento_bolsa).permit(:cantidad_horas, :categoria_bolsa_afectada, :fecha_efectiva, :concepto)
  end
end