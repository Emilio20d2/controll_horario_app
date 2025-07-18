# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_07_26_100000) do
  create_table "asignacion_turnos", force: :cascade do |t|
    t.integer "trabajador_id", null: false
    t.integer "plantilla_horario_id", null: false
    t.date "fecha_inicio"
    t.date "fecha_fin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plantilla_horario_id"], name: "index_asignacion_turnos_on_plantilla_horario_id"
    t.index ["trabajador_id"], name: "index_asignacion_turnos_on_trabajador_id"
  end

  create_table "bolsa_horas_saldos", force: :cascade do |t|
    t.integer "trabajador_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "saldo_bolsa_horas", precision: 7, scale: 2, default: "0.0", null: false
    t.decimal "saldo_bolsa_festivos", precision: 7, scale: 2, default: "0.0", null: false
    t.decimal "saldo_bolsa_libranza", precision: 7, scale: 2, default: "0.0", null: false
    t.index ["trabajador_id"], name: "index_bolsa_horas_saldos_on_trabajador_id", unique: true
  end

  create_table "configuracion_jornadas", force: :cascade do |t|
    t.integer "anio", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "horas_maximas", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "jornada_semanal_maxima", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["anio"], name: "index_configuracion_jornadas_on_anio", unique: true
  end

  create_table "entrada_diarias", force: :cascade do |t|
    t.integer "trabajador_id", null: false
    t.date "fecha", null: false
    t.integer "tipo_ausencia_id"
    t.boolean "pago_doble", default: false, null: false
    t.string "comentario"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "motivo"
    t.decimal "horas_trabajadas", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "horas_ausencia", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "horas_comp_pagadas", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["tipo_ausencia_id"], name: "index_entrada_diarias_on_tipo_ausencia_id"
    t.index ["trabajador_id", "fecha"], name: "index_entrada_diarias_on_trabajador_id_and_fecha", unique: true
    t.index ["trabajador_id"], name: "index_entrada_diarias_on_trabajador_id"
  end

  create_table "festivos", force: :cascade do |t|
    t.date "fecha"
    t.string "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "apertura_autorizada", default: false, null: false
  end

  create_table "historial_contratos", force: :cascade do |t|
    t.integer "trabajador_id", null: false
    t.date "fecha_inicio_vigencia", null: false
    t.date "fecha_fin_vigencia"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "dias_laborables_semana_contratados", default: 5, null: false
    t.decimal "horas_semanales_contratadas", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["trabajador_id"], name: "index_historial_contratos_on_trabajador_id"
  end

  create_table "historial_jornada_anuales", force: :cascade do |t|
    t.integer "trabajador_id", null: false
    t.integer "anio"
    t.text "datos_calculo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "jornada_anual_ajustada", precision: 7, scale: 2, default: "0.0", null: false
    t.decimal "horas_anuales_realizadas", precision: 7, scale: 2, default: "0.0", null: false
    t.decimal "balance_final", precision: 7, scale: 2, default: "0.0", null: false
    t.index ["trabajador_id"], name: "index_historial_jornada_anuales_on_trabajador_id"
  end

  create_table "limite_festivo_libranzas", force: :cascade do |t|
    t.integer "trabajador_id", null: false
    t.integer "anio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "horas_acumuladas", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["trabajador_id"], name: "index_limite_festivo_libranzas_on_trabajador_id"
  end

  create_table "movimiento_bolsas", force: :cascade do |t|
    t.integer "trabajador_id", null: false
    t.date "fecha_efectiva", null: false
    t.string "tipo_movimiento", null: false
    t.string "categoria_bolsa_afectada", null: false
    t.string "concepto", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "cantidad_horas", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["trabajador_id"], name: "index_movimiento_bolsas_on_trabajador_id"
  end

  create_table "plantilla_horarios", force: :cascade do |t|
    t.string "nombre"
    t.text "horario"
    t.date "fecha_referencia"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tipo_ausencias", force: :cascade do |t|
    t.string "nombre"
    t.boolean "es_retribuida"
    t.boolean "genera_deuda_en_bolsa"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "es_fraccionable", default: false, null: false
    t.string "categoria_bolsa_afectada", default: "ninguna", null: false
    t.string "abreviatura", limit: 10
    t.decimal "limite_horas_anuales", precision: 5, scale: 2
    t.boolean "suspende_contrato"
    t.index ["categoria_bolsa_afectada"], name: "index_tipo_ausencias_on_categoria_bolsa_afectada"
  end

  create_table "tipo_contratos", force: :cascade do |t|
    t.string "nombre"
    t.boolean "acumula_festivo_trabajado_en_bolsa"
    t.boolean "acumula_festivo_en_libranza"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "afecta_bolsa_horas", default: true, null: false
  end

  create_table "trabajadores", force: :cascade do |t|
    t.string "nombre", null: false
    t.integer "tipo_contrato_id", null: false
    t.date "fecha_alta"
    t.date "fecha_baja"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "jornada_semanal_actual", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["tipo_contrato_id"], name: "index_trabajadores_on_tipo_contrato_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "asignacion_turnos", "plantilla_horarios"
  add_foreign_key "asignacion_turnos", "trabajadores"
  add_foreign_key "bolsa_horas_saldos", "trabajadores"
  add_foreign_key "entrada_diarias", "tipo_ausencias"
  add_foreign_key "entrada_diarias", "trabajadores"
  add_foreign_key "historial_contratos", "trabajadores"
  add_foreign_key "historial_jornada_anuales", "trabajadores"
  add_foreign_key "limite_festivo_libranzas", "trabajadores"
  add_foreign_key "movimiento_bolsas", "trabajadores"
  add_foreign_key "trabajadores", "tipo_contratos"
end
