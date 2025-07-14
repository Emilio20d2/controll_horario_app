class CreateConfiguracionJornadas < ActiveRecord::Migration[7.1]
  def change
    create_table :configuracion_jornadas do |t|
      t.integer :anio, null: false
      t.decimal :horas_maximas, precision: 7, scale: 2, null: false
      t.string :convenio

      t.timestamps
    end
    add_index :configuracion_jornadas, :anio, unique: true
  end
end