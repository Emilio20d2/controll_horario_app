class CreateTipoAusencia < ActiveRecord::Migration[7.1]
  def change
    # El nombre de la tabla debe ser plural para seguir las convenciones de Rails.
    create_table :tipo_ausencias do |t|
      t.string :nombre
      t.boolean :es_retribuida
      t.boolean :afecta_bolsa
      t.string :modalidad

      t.timestamps
    end
  end
end
