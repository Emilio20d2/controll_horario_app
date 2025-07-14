# Almacena los días festivos oficiales.
class Festivo < ApplicationRecord
  validates :fecha, presence: true, uniqueness: true
  validates :descripcion, presence: true
end
