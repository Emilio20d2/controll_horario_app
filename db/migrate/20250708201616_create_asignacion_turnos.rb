class CreateAsignacionTurnos < ActiveRecord::Migration[7.1]
  def change
    create_table :asignacion_turnos do |t|
      t.references :trabajador, null: false, foreign_key: true
      t.references :plantilla_horario, null: false, foreign_key: true
      t.date :fecha_inicio
      t.date :fecha_fin

      t.timestamps
    end
  end
end
