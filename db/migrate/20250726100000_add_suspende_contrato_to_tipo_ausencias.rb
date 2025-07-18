class AddSuspendeContratoToTipoAusencias < ActiveRecord::Migration[7.1]
  def change
    # Añade la columna 'suspende_contrato' con valores por defecto seguros.
    # Por defecto, ninguna ausencia suspenderá el contrato para no alterar
    # el comportamiento existente hasta que se configure explícitamente.
    # La hacemos robusta para evitar errores si se ejecuta dos veces.
    add_column :tipo_ausencias, :suspende_contrato, :boolean, default: false, null: false unless column_exists?(:tipo_ausencias, :suspende_contrato)
  end
end