# app/controllers/movimientos_controller.rb
class MovimientosController < ApplicationController
  def index
    @trabajador = Trabajador.find(params[:trabajador_id])
    @movimientos = @trabajador.movimiento_bolsas.order(fecha_efectiva: :desc, created_at: :desc)
  end
end