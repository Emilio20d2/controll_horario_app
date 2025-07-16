class AddDiasLaborablesSemanaContratadosToHistorialContratos < ActiveRecord::Migration[7.1]
  def change
    # Hacemos la migración más robusta añadiendo una condición.
    # Esto evita el error "duplicate column" si la migración se ejecuta
    # más de una vez o si la columna ya existe por alguna razón.
    add_column :historial_contratos, :dias_laborables_semana_contratados, :integer, null: false, default: 5 unless column_exists?(:historial_contratos, :dias_laborables_semana_contratados)
  end
end
