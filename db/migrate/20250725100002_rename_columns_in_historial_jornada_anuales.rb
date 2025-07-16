class RenameColumnsInHistorialJornadaAnuales < ActiveRecord::Migration[7.1]
  def change
    # Renombramos las columnas para que sus nombres reflejen mejor su contenido
    # y coincidan con la lógica de negocio definida en la auditoría.
    rename_column :historial_jornada_anuales, :horas_teoricas, :jornada_anual_ajustada
    rename_column :historial_jornada_anuales, :horas_reales, :horas_anuales_realizadas
    rename_column :historial_jornada_anuales, :balance, :balance_final
  end
end
