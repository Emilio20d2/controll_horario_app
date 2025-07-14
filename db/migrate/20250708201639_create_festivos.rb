class CreateFestivos < ActiveRecord::Migration[7.1]
  def change
    create_table :festivos do |t|
      t.date :fecha
      t.string :descripcion

      t.timestamps
    end
  end
end
