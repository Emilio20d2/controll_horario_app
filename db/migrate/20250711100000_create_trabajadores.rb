class CreateTrabajadores < ActiveRecord::Migration[7.1]
  def change
    create_table :trabajadores do |t|
      t.string :nombre, null: false
      t.references :tipo_contrato, null: false, foreign_key: true
      t.date :fecha_alta, null: true
      t.date :fecha_baja, null: true
      t.decimal :jornada_semanal_actual, precision: 5, scale: 2, null: true

      t.timestamps
    end
  end
end