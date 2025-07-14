# /home/emilio/control_horario_app/db/migrate/20250725100001_create_historial_jornada_anuals.rb
class CreateHistorialJornadaAnuals < ActiveRecord::Migration[7.1]
  def change
    # Corregimos el nombre de la tabla a la forma plural correcta en español.
    create_table :historial_jornada_anuales do |t|
      t.references :trabajador, null: false, foreign_key: true
      t.integer :anio
      # Añadimos la precisión y escala a los campos decimales.
      t.decimal :horas_teoricas, precision: 7, scale: 2
      t.decimal :horas_reales, precision: 7, scale: 2
      t.decimal :balance, precision: 7, scale: 2
      t.text :datos_calculo

      t.timestamps
    end
  end
end
