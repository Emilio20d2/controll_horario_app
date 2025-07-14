class CreateMovimientoBolsas < ActiveRecord::Migration[7.1]
  def change
    create_table :movimiento_bolsas do |t|
      t.references :trabajador, null: false, foreign_key: true
      t.date :fecha_efectiva, null: false
      t.decimal :cantidad_horas, precision: 5, scale: 2, null: false
      t.string :tipo_movimiento, null: false
      t.string :categoria_bolsa_afectada, null: false
      t.string :concepto, null: false

      t.timestamps
    end
  end
end
