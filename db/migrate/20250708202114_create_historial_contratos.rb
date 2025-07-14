class CreateHistorialContratos < ActiveRecord::Migration[7.1]
  def change
    create_table :historial_contratos do |t|
      t.references :trabajador, null: false, foreign_key: true
      t.decimal :horas_semanales_contratadas, precision: 4, scale: 2, null: false
      t.date :fecha_inicio_vigencia, null: false
      t.date :fecha_fin_vigencia

      t.timestamps
    end
  end
end
