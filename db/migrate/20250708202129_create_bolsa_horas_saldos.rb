class CreateBolsaHorasSaldos < ActiveRecord::Migration[7.1]
  def change
    create_table :bolsa_horas_saldos do |t|
      t.references :trabajador, null: false, foreign_key: true, index: { unique: true }
      t.decimal :horas_trabajadas_acumuladas, precision: 7, scale: 2, default: 0.0, null: false
      t.decimal :horas_festivo_trabajado, precision: 7, scale: 2, default: 0.0, null: false
      t.decimal :horas_festivo_libranza, precision: 7, scale: 2, default: 0.0, null: false

      t.timestamps
    end
  end
end
