class ConvertHourFieldsToDecimal < ActiveRecord::Migration[7.1]
  def change
    # --- CAMBIO DE COLUMNAS DE INTEGER a DECIMAL ---
    # Usamos una precisión de 5 con 2 decimales para la mayoría de campos (ej: 123.45)
    # y una precisión mayor para los saldos totales que pueden acumular más horas.

    # Tabla: bolsa_horas_saldos
    change_column :bolsa_horas_saldos, :saldo_bolsa_horas, :decimal, precision: 7, scale: 2, default: 0.0, null: false
    change_column :bolsa_horas_saldos, :saldo_bolsa_festivos, :decimal, precision: 7, scale: 2, default: 0.0, null: false
    change_column :bolsa_horas_saldos, :saldo_bolsa_libranza, :decimal, precision: 7, scale: 2, default: 0.0, null: false

    # Tabla: configuracion_jornadas
    change_column :configuracion_jornadas, :horas_maximas, :decimal, precision: 5, scale: 2, default: 0.0, null: false
    change_column :configuracion_jornadas, :jornada_semanal_maxima, :decimal, precision: 5, scale: 2, default: 0.0, null: false

    # Tabla: entrada_diarias
    change_column :entrada_diarias, :horas_trabajadas, :decimal, precision: 5, scale: 2, default: 0.0, null: false
    change_column :entrada_diarias, :horas_ausencia, :decimal, precision: 5, scale: 2, default: 0.0, null: false
    change_column :entrada_diarias, :horas_comp_pagadas, :decimal, precision: 5, scale: 2, default: 0.0, null: false

    # Tabla: historial_contratos
    change_column :historial_contratos, :horas_semanales_contratadas, :decimal, precision: 5, scale: 2, default: 0.0, null: false

    # Tabla: historial_jornada_anuales
    change_column :historial_jornada_anuales, :jornada_anual_ajustada, :decimal, precision: 7, scale: 2, default: 0.0, null: false
    change_column :historial_jornada_anuales, :horas_anuales_realizadas, :decimal, precision: 7, scale: 2, default: 0.0, null: false
    change_column :historial_jornada_anuales, :balance_final, :decimal, precision: 7, scale: 2, default: 0.0, null: false

    # Tabla: limite_festivo_libranzas
    change_column :limite_festivo_libranzas, :horas_acumuladas, :decimal, precision: 5, scale: 2, default: 0.0, null: false

    # Tabla: movimiento_bolsas
    change_column :movimiento_bolsas, :cantidad_horas, :decimal, precision: 5, scale: 2, default: 0.0, null: false

    # Tabla: tipo_ausencias (limite_horas_anuales puede ser nulo)
    change_column :tipo_ausencias, :limite_horas_anuales, :decimal, precision: 5, scale: 2, null: true

    # Tabla: trabajadores
    change_column :trabajadores, :jornada_semanal_actual, :decimal, precision: 5, scale: 2, default: 0.0, null: false
  end
end
