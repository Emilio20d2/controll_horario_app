class AddMotivoToEntradaDiarias < ActiveRecord::Migration[7.0]
  def change
    # Añadimos la columna 'motivo' de tipo string a la tabla.
    add_column :entrada_diarias, :motivo, :string
  end
end