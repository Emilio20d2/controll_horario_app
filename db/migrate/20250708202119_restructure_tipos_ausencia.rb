
class RestructureTiposAusencia < ActiveRecord::Migration[7.0]
  def change
    # La guía redefine el propósito de los campos. Esta migración alinea la tabla
    # `tipo_ausencias` con la nueva lógica de negocio.

    # 1. Renombrar `afecta_bolsa` a `genera_deuda_en_bolsa` para mayor claridad.
    # Este campo ahora representa el checkbox "¿Afecta a la Bolsa?" que genera un déficit.
    rename_column :tipo_ausencias, :afecta_bolsa, :genera_deuda_en_bolsa

    # 2. Añadir `es_fraccionable` para gestionar la "Modalidad" (Día Completo vs. Por Horas).
    # `false` (default) = Día Completo
    # `true` = Por Horas
    add_column :tipo_ausencias, :es_fraccionable, :boolean, null: false, default: false

    # 3. Añadir `categoria_bolsa_afectada` para saber de qué bolsa específica se descuentan horas.
    # Corresponde al menú desplegable "Bolsa de Horas Afectada".
    # El valor 'ninguna' es el default, como se especifica en la guía.
    add_column :tipo_ausencias, :categoria_bolsa_afectada, :string, null: false, default: 'ninguna'

    # 4. Eliminar la antigua columna `modalidad`, que es reemplazada por la nueva lógica.
    remove_column :tipo_ausencias, :modalidad, :string

    # Añadimos un índice para mejorar el rendimiento de las consultas sobre esta nueva columna.
    add_index :tipo_ausencias, :categoria_bolsa_afectada
  end
end