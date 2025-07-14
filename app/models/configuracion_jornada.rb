class ConfiguracionJornada < ApplicationRecord
  validates :anio, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :horas_maximas, presence: true, numericality: { greater_than: 0 }
end