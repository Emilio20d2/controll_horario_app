# app/controllers/informes_controller.rb
class InformesController < ApplicationController
  def saldos
    @trabajadores = Trabajador.includes(:bolsa_horas_saldo).order(:nombre)
  end
end