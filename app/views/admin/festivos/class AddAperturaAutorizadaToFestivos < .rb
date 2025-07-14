class AddAperturaAutorizadaToFestivos < ActiveRecord::Migration[7.1]
  def change
    # Este campo diferencia entre un festivo tradicional (cierre) y un festivo/domingo de apertura.
    # false (default) = Festivo de Cierre
    # true = Apertura Autorizada
    add_column :festivos, :apertura_autorizada, :boolean, null: false, default: false
  end
end