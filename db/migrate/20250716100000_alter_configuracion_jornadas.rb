class AlterConfiguracionJornadas < ActiveRecord::Migration[7.1]
  def change
    # Añadimos la nueva columna para la jornada semanal máxima de referencia.
    # Por defecto, asumimos 40 horas, que es el estándar.
    add_column :configuracion_jornadas, :jornada_semanal_maxima, :decimal, precision: 4, scale: 2, default: 40.0, null: false

    # Eliminamos la columna 'convenio' que ya no se necesita.
    remove_column :configuracion_jornadas, :convenio, :string
  end
end