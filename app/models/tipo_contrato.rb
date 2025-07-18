class TipoContrato < ApplicationRecord
  has_many :trabajadores
  validates :nombre, presence: true, uniqueness: { case_sensitive: false }
end