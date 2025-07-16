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

  # --- Validaciones de Lógica de Negocio ---
  # Evita configuraciones inconsistentes ("estados imposibles") identificadas en la auditoría.
  validate :consistencia_de_configuracion_de_bolsa

  private

  def consistencia_de_configuracion_de_bolsa
    # ESCENARIO 1: Si una ausencia genera deuda, DEBE tener una bolsa de destino.
    # No puede generar una deuda "fantasma".
    if genera_deuda_en_bolsa? && consume_de_ninguna?
      errors.add(:categoria_bolsa_afectada, "debe seleccionar una bolsa (Horas, Festivos o Libranza) si la ausencia genera deuda")
    end

    # ESCENARIO 2: Si una ausencia NO genera deuda, NO PUEDE tener una bolsa de destino.
    # No tiene sentido que consuma de una bolsa si no genera deuda.
    if !genera_deuda_en_bolsa? && !consume_de_ninguna?
      errors.add(:categoria_bolsa_afectada, "debe ser 'ninguna' si la ausencia no genera deuda")
    end
  end
end