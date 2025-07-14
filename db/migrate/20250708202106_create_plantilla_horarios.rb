class CreatePlantillaHorarios < ActiveRecord::Migration[7.1]
  def change
    create_table :plantilla_horarios do |t|
      t.string :nombre
      t.text :horario
      t.date :fecha_referencia

      t.timestamps
    end
  end
end
