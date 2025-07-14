class AddAbreviaturaToTipoAusencias < ActiveRecord::Migration[7.1]
  def change
    add_column :tipo_ausencias, :abreviatura, :string, limit: 10
  end
end