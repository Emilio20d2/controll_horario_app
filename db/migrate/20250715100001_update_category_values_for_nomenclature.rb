class UpdateCategoryValuesForNomenclature < ActiveRecord::Migration[7.1]
  # Definimos modelos temporales para que la migración sea autocontenida
  # y no dependa del estado de los modelos de la aplicación en el futuro.
  class TmpMovimientoBolsa < ApplicationRecord
    self.table_name = 'movimiento_bolsas'
  end

  class TmpTipoAusencia < ApplicationRecord
    self.table_name = 'tipo_ausencias'
  end

  # Mapeo de nombres antiguos a nuevos para evitar repetición.
  NAME_MAP = {
    'horas_normales' => 'horas',
    'festivo_trabajado' => 'festivos',
    'festivo_libranza' => 'libranza'
  }.freeze

  def up
    say_with_time "Actualizando valores de categoria_bolsa_afectada a la nueva nomenclatura" do
      NAME_MAP.each do |old_name, new_name|
        TmpMovimientoBolsa.where(categoria_bolsa_afectada: old_name).update_all(categoria_bolsa_afectada: new_name)
        TmpTipoAusencia.where(categoria_bolsa_afectada: old_name).update_all(categoria_bolsa_afectada: new_name)
      end
    end
  end

  def down
    say_with_time "Revirtiendo valores de categoria_bolsa_afectada a la nomenclatura anterior" do
      NAME_MAP.each do |old_name, new_name|
        TmpMovimientoBolsa.where(categoria_bolsa_afectada: new_name).update_all(categoria_bolsa_afectada: old_name)
        TmpTipoAusencia.where(categoria_bolsa_afectada: new_name).update_all(categoria_bolsa_afectada: old_name)
      end
    end
  end
end