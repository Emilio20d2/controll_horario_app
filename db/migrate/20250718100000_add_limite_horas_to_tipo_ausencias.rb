class AddLimiteHorasToTipoAusencias < ActiveRecord::Migration[7.1]
  def change
    add_column :tipo_ausencias, :limite_horas_anuales, :decimal, precision: 5, scale: 2
  end
end