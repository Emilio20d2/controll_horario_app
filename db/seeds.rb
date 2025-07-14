# Este archivo debe usarse para poblar la base de datos con datos iniciales.
# Se ejecuta con el comando: rails db:seed

puts "== Poblando Tipos de Contrato =="

tipos_de_contrato = [
  { nombre: "Indefinido", afecta_bolsa_ordinaria: true, acumula_festivo_trabajado_en_bolsa: true, acumula_festivo_en_libranza: true },
  { nombre: "Sustitución", afecta_bolsa_ordinaria: true, acumula_festivo_trabajado_en_bolsa: true, acumula_festivo_en_libranza: true },
  { nombre: "Temporal", afecta_bolsa_ordinaria: true, acumula_festivo_trabajado_en_bolsa: true, acumula_festivo_en_libranza: true },
  { nombre: "Mozo de Almacén", afecta_bolsa_ordinaria: true, acumula_festivo_trabajado_en_bolsa: true, acumula_festivo_en_libranza: false },
  { nombre: "Fin de Semana", afecta_bolsa_ordinaria: false, acumula_festivo_trabajado_en_bolsa: false, acumula_festivo_en_libranza: false }
]

tipos_de_contrato.each do |contrato_attrs|
  tipo_contrato = TipoContrato.find_or_initialize_by(nombre: contrato_attrs[:nombre])
  tipo_contrato.assign_attributes(contrato_attrs)

  if tipo_contrato.changed?
    tipo_contrato.save!
    puts "Procesado (Creado/Actualizado) Tipo de Contrato: #{tipo_contrato.nombre}"
  end
end

puts "\n== Poblando Festivos de Zaragoza para 2025 (incluyendo aperturas autorizadas) =="

festivos_2025 = [
  # Festivos de Cierre General
  { fecha: Date.new(2025, 1, 1), descripcion: "Año Nuevo", apertura_autorizada: false },
  { fecha: Date.new(2025, 1, 29), descripcion: "San Valero (Festivo Local Zaragoza)", apertura_autorizada: false },
  { fecha: Date.new(2025, 3, 5), descripcion: "Cincomarzada (Festivo Local Zaragoza)", apertura_autorizada: false },
  { fecha: Date.new(2025, 4, 18), descripcion: "Viernes Santo", apertura_autorizada: false },
  { fecha: Date.new(2025, 4, 23), descripcion: "San Jorge (Día de Aragón)", apertura_autorizada: false },
  { fecha: Date.new(2025, 5, 1), descripcion: "Fiesta del Trabajo", apertura_autorizada: false },
  { fecha: Date.new(2025, 8, 15), descripcion: "Asunción de la Virgen", apertura_autorizada: false },
  { fecha: Date.new(2025, 10, 13), descripcion: "Fiesta Nacional de España (Traslado del 12)", apertura_autorizada: false },
  { fecha: Date.new(2025, 11, 1), descripcion: "Todos los Santos", apertura_autorizada: false },
  { fecha: Date.new(2025, 12, 6), descripcion: "Día de la Constitución Española", apertura_autorizada: false },
  { fecha: Date.new(2025, 12, 25), descripcion: "Natividad del Señor (Navidad)", apertura_autorizada: false },

  # Festivos de Apertura Autorizada en Aragón 2025
  { fecha: Date.new(2025, 1, 6), descripcion: "Epifanía del Señor (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 4, 17), descripcion: "Jueves Santo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 6, 29), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 11, 2), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 12, 7), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 12, 8), descripcion: "Inmaculada Concepción (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 12, 14), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 12, 21), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true },
  { fecha: Date.new(2025, 12, 28), descripcion: "Domingo (Apertura Autorizada)", apertura_autorizada: true }
]

festivos_2025.each do |festivo_attrs|
  # Usamos find_or_create_by! para no duplicar si ya existen
  Festivo.find_or_create_by!(fecha: festivo_attrs[:fecha]) do |f|
    f.assign_attributes(festivo_attrs)
    puts "Creado/Verificado Festivo: #{f.fecha} - #{f.descripcion}"
  end
end

puts "\n== Poblando Tipos de Ausencia =="

# La nueva estructura se basa en la guía y utiliza 4 campos clave:
# - es_fraccionable: (Modalidad) `false` para Día Completo, `true` para Por Horas.
# - es_retribuida: `true` si cuenta para la jornada anual, `false` si la reduce.
# - categoria_bolsa_afectada: De qué bolsa se restan las horas.
# - genera_deuda_en_bolsa: `true` si la ausencia crea un déficit en la bolsa ordinaria.

tipos_de_ausencia = [
  # --- EJEMPLOS DE LA GUÍA ---
  { nombre: "Vacaciones",
    es_fraccionable: false, es_retribuida: true, categoria_bolsa_afectada: 'ninguna', genera_deuda_en_bolsa: false },

  { nombre: "Permiso sin Sueldo",
    es_fraccionable: true, es_retribuida: false, categoria_bolsa_afectada: 'ninguna', genera_deuda_en_bolsa: false },

  { nombre: "Devolución de Festivo",
    es_fraccionable: true, es_retribuida: true, categoria_bolsa_afectada: 'festivos', genera_deuda_en_bolsa: false },

  # --- OTROS EJEMPLOS COMUNES ---
  { nombre: "Baja Médica",
    es_fraccionable: false, es_retribuida: true, categoria_bolsa_afectada: 'ninguna', genera_deuda_en_bolsa: false },

  { nombre: "Ausencia Injustificada",
    es_fraccionable: false, es_retribuida: false, categoria_bolsa_afectada: 'ninguna', genera_deuda_en_bolsa: true },

  { nombre: "Devolución de Horas",
    es_fraccionable: true, es_retribuida: true, categoria_bolsa_afectada: 'horas', genera_deuda_en_bolsa: false },

  { nombre: "Libranza de Festivo",
    es_fraccionable: true, es_retribuida: true, categoria_bolsa_afectada: 'libranza', genera_deuda_en_bolsa: false },

  { nombre: "Visita Médica",
    es_fraccionable: true, es_retribuida: true, categoria_bolsa_afectada: 'ninguna', genera_deuda_en_bolsa: false },

  { nombre: "Permiso Retribuido",
    es_fraccionable: false, es_retribuida: true, categoria_bolsa_afectada: 'ninguna', genera_deuda_en_bolsa: false },

  { nombre: "Asuntos Propios",
    es_fraccionable: false, es_retribuida: false, categoria_bolsa_afectada: 'ninguna', genera_deuda_en_bolsa: false }
]

tipos_de_ausencia.each do |ausencia_attrs|
  tipo_ausencia = TipoAusencia.find_or_initialize_by(nombre: ausencia_attrs[:nombre])
  # Asignamos todos los atributos del hash directamente.
  tipo_ausencia.assign_attributes(ausencia_attrs)

  if tipo_ausencia.changed?
    tipo_ausencia.save!
    puts "Procesado (Creado/Actualizado) Tipo de Ausencia: #{tipo_ausencia.nombre}"
  end
end

puts "\n== Proceso de carga de datos iniciales finalizado. =="
