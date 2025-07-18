# app/models/tipo_ausencia.rb
# Define los diferentes tipos de ausencias que un trabajador puede tener.
class TipoAusencia < ApplicationRecord
  # --- ASOCIACIONES ---
  # Si un tipo de ausencia está en uso, no se puede borrar.
  has_many :entrada_diarias, dependent: :restrict_with_error

  # --- ENUMS ---
  # Para estandarizar los valores posibles del campo.
  enum categoria_bolsa_afectada: {
    ninguna: 'ninguna',
    horas: 'horas',
    festivos: 'festivos',
    libranza: 'libranza'
  }

  # --- VALIDACIONES ---
  validates :nombre, presence: true, uniqueness: { case_sensitive: false }
  validates :abreviatura, presence: true, uniqueness: { case_sensitive: false }
  validates :es_fraccionable, :es_retribuida, :genera_deuda_en_bolsa, inclusion: { in: [true, false] }
  validates :limite_horas_anuales, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validate :deuda_implica_bolsa_de_horas

  private

  def deuda_implica_bolsa_de_horas
    # Si una ausencia genera deuda, debe afectar a alguna bolsa (no puede ser 'ninguna').
    if genera_deuda_en_bolsa && categoria_bolsa_afectada == 'ninguna'
      errors.add(:categoria_bolsa_afectada, "debe seleccionar una bolsa (Horas, Festivos o Libranza) si la ausencia genera deuda")
    end
  end
end