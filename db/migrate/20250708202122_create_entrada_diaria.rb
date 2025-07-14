class CreateEntradaDiaria < ActiveRecord::Migration[7.1]
  def change
    # El nombre de la tabla debe ser plural para seguir las convenciones de Rails.
    create_table :entrada_diarias do |t|
      t.references :trabajador, null: false, foreign_key: true
      t.date :fecha, null: false
      t.decimal :horas_trabajadas, precision: 4, scale: 2, default: 0.0, null: false
      t.references :tipo_ausencia, null: true, foreign_key: true
      t.decimal :horas_ausencia, precision: 4, scale: 2, default: 0.0, null: false
      # Renombrado para consistencia con el resto de la app.
      t.boolean :pago_doble, default: false, null: false
      t.decimal :horas_comp_pagadas, precision: 4, scale: 2, default: 0.0, null: false
      t.string :comentario, null: true

      t.timestamps
    end
    add_index :entrada_diarias, [:trabajador_id, :fecha], unique: true
  end
end
