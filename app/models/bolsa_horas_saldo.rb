# app/models/bolsa_horas_saldo.rb
class BolsaHorasSaldo < ApplicationRecord
  # Define que un registro de saldo pertenece a un único trabajador.
  belongs_to :trabajador

  # Asegura que cada trabajador solo pueda tener un registro de saldo.
  validates :trabajador_id, uniqueness: true, presence: true
end