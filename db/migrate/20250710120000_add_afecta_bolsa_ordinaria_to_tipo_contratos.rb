class AddAfectaBolsaOrdinariaToTipoContratos < ActiveRecord::Migration[7.1]
  def change
    # Añade la columna solo si no existe para evitar errores de duplicado.
    unless column_exists?(:tipo_contratos, :afecta_bolsa_ordinaria)
      add_column :tipo_contratos, :afecta_bolsa_ordinaria, :boolean, default: true, null: false
    end
  end
end