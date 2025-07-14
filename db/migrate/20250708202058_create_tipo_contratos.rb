class CreateTipoContratos < ActiveRecord::Migration[7.1]
  def change
    create_table :tipo_contratos do |t|
      t.string :nombre
      t.boolean :acumula_festivo_trabajado_en_bolsa
      t.boolean :acumula_festivo_en_libranza

      t.timestamps
    end
  end
end
