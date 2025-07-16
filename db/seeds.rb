# Este archivo debe usarse para poblar la base de datos con datos iniciales.
# Se ejecuta con el comando: rails db:seed

puts "== Iniciando proceso de carga de datos iniciales... =="

# --- Método Auxiliar ---
# Método para crear o actualizar registros de forma unificada y evitar duplicados.
def crear_o_actualizar(modelo, atributos, clave_busqueda = :nombre)
  registro = modelo.find_or_initialize_by(clave_busqueda => atributos[clave_busqueda])
  registro.assign_attributes(atributos)
  if registro.changed? # Solo guardamos si hay cambios
    if registro.save
      puts "Procesado (Creado/Actualizado) #{modelo}: #{registro.send(clave_busqueda)}"
    else
      puts "ERROR al procesar #{modelo}: #{registro.send(clave_busqueda)}"
      registro.errors.full_messages.each { |msg| puts "  - #{msg}" }
    end
  end
end


# --- Poblando Tipos de Contrato ---
puts "\n== Poblando Tipos de Contrato =="
tipos_de_contrato = [
  { nombre: "Indefinido", afecta_bolsa_horas: true, acumula_festivo_trabajado_en_bolsa: true, acumula_festivo_en_libranza: true },
  { nombre: "Sustitución", afecta_bolsa_horas: true, acumula_festivo_trabajado_en_bolsa: true, acumula_festivo_en_libranza: true },
  { nombre: "Temporal", afecta_bolsa_horas: true, acumula_festivo_trabajado_en_bolsa: true, acumula_festivo_en_libranza: true },
  { nombre: "Mozo de Almacén", afecta_bolsa_horas: true, acumula_festivo_trabajado_en_bolsa: true, acumula_festivo_en_libranza: false },
  { nombre: "Fin de Semana", afecta_bolsa_horas: false, acumula_festivo_trabajado_en_bolsa: false, acumula_festivo_en_libranza: false }
]
tipos_de_contrato.each do |atributos|
  crear_o_actualizar(TipoContrato, atributos)
end


# --- Poblando Festivos ---
puts "\n== Poblando Festivos de Zaragoza para 2025 (incluyendo aperturas autorizadas) =="
festivos_2025 = [
  { fecha: Date.new(2025, 1, 1), descripcion: "Año Nuevo", apertura_autorizada: false },
  { fecha: Date.new(2025, 1, 6), descripcion: "Epifanía del Señor (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 1, 29), descripcion: "San Valero", apertura_autorizada: false },
  { fecha: Date.new(2025, 3, 5), descripcion: "Cincomarzada", apertura_autorizada: false },
  { fecha: Date.new(2025, 4, 17), descripcion: "Jueves Santo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 4, 18), descripcion: "Viernes Santo", apertura_autorizada: false },
  { fecha: Date.new(2025, 4, 23), descripcion: "San Jorge (Día de Aragón)", apertura_autorizada: false },
  { fecha: Date.new(2025, 5, 1), descripcion: "Fiesta del Trabajo", apertura_autorizada: false },
  { fecha: Date.new(2025, 6, 29), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 8, 15), descripcion: "Asunción de la Virgen", apertura_autorizada: false },
  { fecha: Date.new(2025, 10, 13), descripcion: "Fiesta Nacional de España (Traslado del 12)", apertura_autorizada: false },
  { fecha: Date.new(2025, 11, 1), descripcion: "Todos los Santos", apertura_autorizada: false },
  { fecha: Date.new(2025, 11, 2), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 12, 6), descripcion: "Día de la Constitución Española", apertura_autorizada: false },
  { fecha: Date.new(2025, 12, 7), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 12, 8), descripcion: "Inmaculada Concepción (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 12, 14), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 12, 21), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 12, 25), descripcion: "Natividad del Señor (Navidad)", apertura_autorizada: false },
  { fecha: Date.new(2025, 12, 28), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true }
]
festivos_2025.each do |atributos|
  crear_o_actualizar(Festivo, atributos, :fecha)
end


# --- Poblando Tipos de Ausencia ---
puts "\n== Poblando Tipos de Ausencia =="
# Interpretación de la tabla de ausencias proporcionada:
# "Computa la jornada completa." -> es_retribuida: true
# "Descuenta la jornada." -> es_retribuida: false (salvo devoluciones de bolsa)
# "Puede descontar de la bolsa ordinaria" -> genera_deuda_en_bolsa: true
# "Descuenta de la bolsa de..." -> categoria_bolsa_afectada
tipos_de_ausencia = [
  { nombre: "Accidente de Trabajo", abreviatura: "AT", es_retribuida: true, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Asuntos Propios", abreviatura: "AP", es_retribuida: false, es_fraccionable: true, genera_deuda_en_bolsa: true, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Ausencia Injustificada", abreviatura: "AI", es_retribuida: false, es_fraccionable: false, genera_deuda_en_bolsa: true, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Ausencia Justificada", abreviatura: "AJ", es_retribuida: false, es_fraccionable: true, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Baja Médica (IT)", abreviatura: "B", es_retribuida: true, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Deber Público / Legal", abreviatura: "DS", es_retribuida: false, es_fraccionable: true, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Devolución Festivo", abreviatura: "DF", es_retribuida: true, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'festivos' },
  { nombre: "Devolución Horas", abreviatura: "DH", es_retribuida: true, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'horas' },
  { nombre: "Enfermedad Grave", abreviatura: "EG", es_retribuida: false, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Excedencia", abreviatura: "EX", es_retribuida: false, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Exámenes Oficiales", abreviatura: "EO", es_retribuida: false, es_fraccionable: true, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Fallecimiento Familiar", abreviatura: "FF", es_retribuida: false, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Formación", abreviatura: "FR", es_retribuida: false, es_fraccionable: true, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Horas Médicas (Personal)", abreviatura: "HM", es_retribuida: false, es_fraccionable: true, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna', limite_horas_anuales: 12.0 },
  { nombre: "Horas Médicas (Acompañar Menor)", abreviatura: "HMM", es_retribuida: false, es_fraccionable: true, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna', limite_horas_anuales: 16.0 },
  { nombre: "Horas Sindicales", abreviatura: "HS", es_retribuida: false, es_fraccionable: true, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Lactancia", abreviatura: "LAC", es_retribuida: true, es_fraccionable: true, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Libranza Festivo", abreviatura: "LF", es_retribuida: true, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'libranza' },
  { nombre: "Maternidad / Paternidad", abreviatura: "MA", es_retribuida: true, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Matrimonio", abreviatura: "MAT", es_retribuida: false, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Permiso No Retribuido", abreviatura: "PNR", es_retribuida: false, es_fraccionable: true, genera_deuda_en_bolsa: true, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Reducción Jornada Senior", abreviatura: "RJS", es_retribuida: true, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' },
  { nombre: "Vacaciones", abreviatura: "V", es_retribuida: true, es_fraccionable: false, genera_deuda_en_bolsa: false, categoria_bolsa_afectada: 'ninguna' }
]
tipos_de_ausencia.each do |atributos|
  crear_o_actualizar(TipoAusencia, atributos)
end


# --- Creando Usuario ---
puts "\n== Creando usuario de producción =="
User.find_or_create_by!(email: 'emiliogp@inditex.com') do |user|
  user.password = '456123'
  user.password_confirmation = '456123'
  puts "Usuario de producción creado:"
  puts "  Email: #{user.email}"
  puts "  Contraseña: (la que has especificado)"
end

puts "\n== Proceso de carga de datos iniciales finalizado. =="
