class AddFieldsToEntradaDiarias < ActiveRecord::Migration[7.1]
  def change
    add_column :entrada_diarias, :pago_doble, :boolean, default: false, null: false unless column_exists?(:entrada_diarias, :pago_doble)
    add_column :entrada_diarias, :comentario, :string unless column_exists?(:entrada_diarias, :comentario)
  end
end