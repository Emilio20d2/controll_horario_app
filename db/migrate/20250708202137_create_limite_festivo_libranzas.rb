class CreateLimiteFestivoLibranzas < ActiveRecord::Migration[7.1]
  def change
    create_table :limite_festivo_libranzas do |t|
      t.references :trabajador, null: false, foreign_key: true
      t.integer :anio
      t.decimal :horas_acumuladas

      t.timestamps
    end
  end
end
