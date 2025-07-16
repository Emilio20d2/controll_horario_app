class CambiarHorasAEnterosParaMinutos < ActiveRecord::Migration[7.1]
  # Mapeo de tablas y columnas para hacer el código más mantenible.
  TABLES_AND_COLUMNS = {
    entrada_diarias: [:horas_trabajadas, :horas_ausencia, :horas_comp_pagadas], # `decimal` en el schema
    movimiento_bolsas: [:cantidad_horas],
    historial_contratos: [:horas_semanales_contratadas], # `decimal` en el schema
    bolsa_horas_saldos: [:saldo_bolsa_horas, :saldo_bolsa_festivos, :saldo_bolsa_libranza],
    limite_festivo_libranzas: [:horas_acumuladas], # `decimal` en el schema
    historial_jornada_anuales: [:jornada_anual_ajustada, :horas_anuales_realizadas, :balance_final], # `decimal`
    configuracion_jornadas: [:horas_maximas, :jornada_semanal_maxima], # `decimal`
    tipo_ausencias: [:limite_horas_anuales], # `decimal`
    trabajadores: [:jornada_semanal_actual] # `decimal`
  }.freeze

  def up
    say_with_time "Convirtiendo columnas de horas a minutos (enteros)..." do
      TABLES_AND_COLUMNS.each do |table, columns|
        columns.each do |column|
          if column_exists?(table, column)
            say "Cambiando #{table}.#{column}..."
            # Usamos SQL puro para máxima compatibilidad (especialmente con SQLite)
            # 1. Renombramos la columna original para tener una copia de seguridad
            rename_column table, column, "#{column}_old"
            # 2. Creamos la nueva columna con el tipo y restricciones correctas
            # Caso especial para columnas que permitían nulos, como se ve en schema.rb
            if table == :tipo_ausencias && column == :limite_horas_anuales
              add_column table, column, :integer, null: true
            else
              add_column table, column, :integer, default: 0, null: false
            end
            # 3. Poblamos la nueva columna, convirtiendo los valores antiguos
            # ROUND() es necesario para evitar errores de conversión de flotantes
            # Usamos COALESCE para manejar los valores NULL y convertirlos a 0 o mantenerlos como NULL
            execute "UPDATE #{table} SET #{column} = ROUND(COALESCE(#{column}_old, 0) * 60) WHERE #{column}_old IS NOT NULL"
            # 4. Eliminamos la columna antigua
            remove_column table, "#{column}_old"
          else
            say "AVISO: La columna #{table}.#{column} no existe, se omite.", true
          end
        end
      end
    end
  end 
  
  def down
    say_with_time "Revirtiendo columnas de minutos a horas (decimal) con SQL puro..." do
      TABLES_AND_COLUMNS.each do |table, columns|
        columns.each do |column|
          if column_exists?(table, column)
            say "Revirtiendo #{table}.#{column}..."
            # Proceso inverso al de 'up'
            rename_column table, column, "#{column}_int_old"

            if table == :tipo_ausencias && column == :limite_horas_anuales
              add_column table, column, :decimal, precision: 5, scale: 2, null: true
            else
              # Recreamos la columna como decimal. La precisión y escala son estimaciones;
              # si el schema original era diferente, habría que ajustarlo.
              add_column table, column, :decimal, precision: 7, scale: 2, default: 0.0, null: false
            end
            execute "UPDATE #{table} SET #{column} = #{column}_int_old / 60.0 WHERE #{column}_int_old IS NOT NULL"
            remove_column table, "#{column}_int_old"
          else
            say "AVISO: La columna #{table}.#{column} no existe, se omite.", true
          end
        end
      end
    end
  end 
end
