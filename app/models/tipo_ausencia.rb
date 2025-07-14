# app/models/tipo_ausencia.rb
class TipoAusencia < ApplicationRecord
  # Un tipo de ausencia no puede ser eliminado si está siendo usado por alguna entrada diaria.
  has_many :entrada_diarias, dependent: :restrict_with_error

  validates :nombre, presence: true, uniqueness: true
  validates :abreviatura, presence: true, uniqueness: true, length: { maximum: 10 }

  # Enum para la categoría de la bolsa afectada, para mayor robustez y claridad.
  enum categoria_bolsa_afectada: {
    ninguna: 'ninguna', # No afecta a ninguna bolsa
    horas: 'horas', # Afecta a la bolsa de horas principal
    festivos: 'festivos', # Afecta a la bolsa de festivos trabajados
    libranza: 'libranza' # Afecta a la bolsa de festivos en libranza
  }, _prefix: :consume_de
end