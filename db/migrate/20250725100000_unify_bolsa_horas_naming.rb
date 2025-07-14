class UnifyBolsaHorasNaming < ActiveRecord::Migration[7.1]
  # Definimos modelos temporales para que la migración sea autocontenida
  # y no dependa del estado de los modelos de la aplicación en el futuro.
  class TipoAusencia < ApplicationRecord
    self.table_name = 'tipo_ausencias'
  end

  class MovimientoBolsa < ApplicationRecord
    self.table_name = 'movimiento_bolsas'
  end

  def up
    # 1. Renombrar la columna en la tabla de contratos.
    rename_column :tipo_contratos, :afecta_bolsa_ordinaria, :afecta_bolsa_horas

    # 2. Renombrar las columnas en la tabla de saldos para que sean consistentes.
    rename_column :bolsa_horas_saldos, :horas_trabajadas_acumuladas, :saldo_bolsa_horas
    rename_column :bolsa_horas_saldos, :horas_festivo_trabajado, :saldo_bolsa_festivos
    rename_column :bolsa_horas_saldos, :horas_festivo_libranza, :saldo_bolsa_libranza

    # 3. Actualizar los datos existentes para usar el nuevo nombre unificado.
    # Usamos `update_all` para eficiencia.
    TipoAusencia.where(categoria_bolsa_afectada: 'horas_normales').update_all(categoria_bolsa_afectada: 'horas')
    MovimientoBolsa.where(categoria_bolsa_afectada: 'horas_normales').update_all(categoria_bolsa_afectada: 'horas')
  end

  def down
    rename_column :tipo_contratos, :afecta_bolsa_horas, :afecta_bolsa_ordinaria

    rename_column :bolsa_horas_saldos, :saldo_bolsa_horas, :horas_trabajadas_acumuladas
    rename_column :bolsa_horas_saldos, :saldo_bolsa_festivos, :horas_festivo_trabajado
    rename_column :bolsa_horas_saldos, :saldo_bolsa_libranza, :horas_festivo_libranza

    TipoAusencia.where(categoria_bolsa_afectada: 'horas').update_all(categoria_bolsa_afectada: 'horas_normales')
    MovimientoBolsa.where(categoria_bolsa_afectada: 'horas').update_all(categoria_bolsa_afectada: 'horas_normales')
  end
end