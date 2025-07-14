class FinalizeBolsaHorasNomenclature < ActiveRecord::Migration[7.1]
  # Definimos modelos temporales para que la migración sea autocontenida
  # y no dependa del estado de los modelos de la aplicación en el futuro.
  class TmpMovimientoBolsa < ApplicationRecord
    self.table_name = 'movimiento_bolsas'
  end

  class TmpTipoAusencia < ApplicationRecord
    self.table_name = 'tipo_ausencias'
  end

  def up
    # Esta migración corrige varias inconsistencias para alinear la BD
    # con la nomenclatura oficial: `horas`, `festivos`, `libranza`.

    # 1. Corregir nombres de columna en `bolsa_horas_saldos`
    say_with_time "Renaming columns in bolsa_horas_saldos" do
      rename_column :bolsa_horas_saldos, :saldo_bolsa_horas, :horas if column_exists?(:bolsa_horas_saldos, :saldo_bolsa_horas)
      rename_column :bolsa_horas_saldos, :saldo_bolsa_festivos, :festivos if column_exists?(:bolsa_horas_saldos, :saldo_bolsa_festivos)
      rename_column :bolsa_horas_saldos, :saldo_bolsa_libranza, :libranza if column_exists?(:bolsa_horas_saldos, :saldo_bolsa_libranza)
    end

    # 2. Corregir datos de categorías incorrectas
    say_with_time "Correcting inconsistent category data" do
      TmpMovimientoBolsa.where(categoria_bolsa_afectada: 'bolsa_horas').update_all(categoria_bolsa_afectada: 'horas')
      TmpTipoAusencia.where(categoria_bolsa_afectada: 'bolsa_horas').update_all(categoria_bolsa_afectada: 'horas')
    end
  end

  def down
    say_with_time "Reverting column names in bolsa_horas_saldos" do
      rename_column :bolsa_horas_saldos, :horas, :saldo_bolsa_horas
      rename_column :bolsa_horas_saldos, :festivos, :saldo_bolsa_festivos
      rename_column :bolsa_horas_saldos, :libranza, :saldo_bolsa_libranza
    end

    say_with_time "Reverting category data" do
      TmpMovimientoBolsa.where(categoria_bolsa_afectada: 'horas').update_all(categoria_bolsa_afectada: 'bolsa_horas')
      TmpTipoAusencia.where(categoria_bolsa_afectada: 'horas').update_all(categoria_bolsa_afectada: 'bolsa_horas')
    end
  end
end