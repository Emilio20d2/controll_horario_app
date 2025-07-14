class TipoContrato < ApplicationRecord
  has_many :trabajadores
  validates :nombre, presence: true, uniqueness: true
end