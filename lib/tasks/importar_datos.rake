# lib/tasks/importar_excel.rake
#
# Tarea Rake para importar todos los datos desde el archivo HORAS 2025.xlsx
# Se ejecuta con: rails importar:todo_desde_excel

require 'roo'

namespace :importar do
  desc "Importa trabajadores, saldos y horarios desde HORAS 2025.xlsx"
  task todo_desde_excel: :environment do

    # --- MÉTODOS DE AYUDA ---
    def safe_to_decimal(value, default = 0.0)
      return default if value.blank?
      BigDecimal(value.to_s.tr(',', '.'))
    rescue ArgumentError, TypeError
      default
    end

    # --- INICIO DE LA TAREA ---
    puts "== [TAREA RAKE] Iniciando importación completa desde HORAS 2025.xlsx =="
    
    file_path = Rails.root.join('HORAS 2025.xlsx')
    unless File.exist?(file_path)
      abort("ERROR: No se encontró el archivo 'HORAS 2025.xlsx' en la raíz del proyecto.")
    end

    xlsx = Roo::Excelx.new(file_path)

    # --- Parte 1: Importar Empleados y Saldos Iniciales ---
    
    sheet_name_saldos = 'HORAS 2024' 
    unless xlsx.sheets.include?(sheet_name_saldos)
      abort("ERROR: No se encontró la hoja '#{sheet_name_saldos}' en el archivo Excel. Hojas disponibles: #{xlsx.sheets.join(', ')}")
    end
    
    sheet_saldos = xlsx.sheet(sheet_name_saldos)
    puts "\n-- Procesando hoja de saldos: '#{sheet_name_saldos}'..."

    tipo_contrato_defecto = TipoContrato.find_by(nombre: 'Indefinido')
    unless tipo_contrato_defecto
      abort("ERROR: No se encontró el 'Tipo de Contrato' con nombre 'Indefinido'. Ejecuta 'rails db:seed' primero.")
    end

    sheet_saldos.each(
      empleado: 'EMPLEADO',
      saldo_trabajadas: 'HORAS TRABAJAS',
      saldo_festivos: 'FESTIVOS',
      saldo_libranza: 'LIBRANZA'
    ) do |row|
      next if row[:empleado] == 'EMPLEADO'
      
      nombre_trabajador = row[:empleado].to_s.strip
      next if nombre_trabajador.blank?

      ActiveRecord::Base.transaction do
        trabajador = Trabajador.find_or_create_by!(nombre: nombre_trabajador) do |t|
          t.tipo_contrato = tipo_contrato_defecto
        end
        
        fecha_inicio_sistema = Date.new(2024, 12, 16)
        concepto_base = "Saldo inicial (Importación #{Date.today.strftime('%Y-%m-%d')})"

        # Usamos los símbolos de los enums del modelo, que es la forma estándar y más segura en Rails.
        MovimientoBolsa.find_or_create_by!(trabajador: trabajador, tipo_movimiento: :saldo_inicial, categoria_bolsa_afectada: :horas) do |mov|
          mov.cantidad_horas = safe_to_decimal(row[:saldo_trabajadas])
          mov.fecha_efectiva = fecha_inicio_sistema
          mov.concepto = concepto_base
        end
        MovimientoBolsa.find_or_create_by!(trabajador: trabajador, tipo_movimiento: :saldo_inicial, categoria_bolsa_afectada: :festivos) do |mov|
          mov.cantidad_horas = safe_to_decimal(row[:saldo_festivos])
          mov.fecha_efectiva = fecha_inicio_sistema
          mov.concepto = concepto_base
        end
        MovimientoBolsa.find_or_create_by!(trabajador: trabajador, tipo_movimiento: :saldo_inicial, categoria_bolsa_afectada: :libranza) do |mov|
          mov.cantidad_horas = safe_to_decimal(row[:saldo_libranza])
          mov.fecha_efectiva = fecha_inicio_sistema
          mov.concepto = concepto_base
        end

        saldo_obj = BolsaHorasSaldo.find_or_create_by!(trabajador: trabajador)
        # Usamos los nombres de columna correctos del schema.rb
        saldo_obj.saldo_bolsa_horas = trabajador.movimiento_bolsas.where(categoria_bolsa_afectada: :horas).sum(:cantidad_horas)
        saldo_obj.saldo_bolsa_festivos = trabajador.movimiento_bolsas.where(categoria_bolsa_afectada: :festivos).sum(:cantidad_horas)
        saldo_obj.saldo_bolsa_libranza = trabajador.movimiento_bolsas.where(categoria_bolsa_afectada: :libranza).sum(:cantidad_horas)
        saldo_obj.save!
      end
      puts "Procesado saldo para: #{nombre_trabajador}"
    end
    puts "-> Finalizada la importación de saldos."


    # --- Parte 2: Importar Horarios Teóricos y Contratos ---

    sheet_name_turnos = 'TURNOS' 
    unless xlsx.sheets.include?(sheet_name_turnos)
      abort("ERROR: No se encontró la hoja '#{sheet_name_turnos}' en el archivo Excel. Hojas disponibles: #{xlsx.sheets.join(', ')}")
    end
    
    sheet_turnos = xlsx.sheet(sheet_name_turnos)
    puts "\n-- Procesando hoja de horarios y contratos: '#{sheet_name_turnos}'..."

    # Usamos `parse(headers: true)` para que Roo interprete la primera fila como
    # encabezados y nos devuelva un array de hashes, uno por cada fila de datos.
    # Esto soluciona el error `TypeError` al asegurar que `row` es un hash.
    sheet_turnos.parse(headers: true).each do |row|
      # La opción `headers: true` ya omite la fila de encabezado.

      nombre_trabajador = row['EMPLEADO'].to_s.strip
      next if nombre_trabajador.blank?

      trabajador = Trabajador.find_by(nombre: nombre_trabajador)
      unless trabajador
        puts "ADVERTENCIA: Trabajador '#{nombre_trabajador}' de la hoja de turnos no fue encontrado en la hoja de saldos. Saltando..."
        next
      end

      ActiveRecord::Base.transaction do
        # Actualizamos la jornada semanal actual directamente en el trabajador, como has pedido.
        trabajador.update!(jornada_semanal_actual: safe_to_decimal(row['HORAS CONTRATADAS'])) # Guardamos como decimal

        nombre_plantilla = "#{nombre_trabajador} #{Date.today.year}"
        horario_json = {}
        (1..4).each do |turno_num|
          turno_key = "turno#{turno_num}"
          horario_json[turno_key] = {}
          %w[LUNES MARTES MIERCOLES JUEVES VIERNES SABADO DOMINGO].each do |dia_semana|
            col_header = "#{dia_semana} TURNO #{turno_num}"
            dia_key = dia_semana.downcase
            # Accedemos a la fila por el nombre exacto del encabezado en el Excel
            horario_json[turno_key][dia_key] = safe_to_decimal(row[col_header]) # Guardamos como decimal
          end
        end
        
        plantilla = PlantillaHorario.find_or_create_by!(nombre: nombre_plantilla)
        # Usamos la fecha de inicio del sistema como fecha de referencia para el horario
        plantilla.update!(horario: horario_json, fecha_referencia: Date.new(2024, 12, 16))
        
        fecha_ini_horario = Date.new(2024, 12, 16)
        AsignacionTurno.find_or_create_by!(trabajador: trabajador, plantilla_horario: plantilla, fecha_inicio: fecha_ini_horario)
        
        # La lógica para el historial de contratos se gestionará manualmente o en una futura implementación,
        # tal y como has indicado.
        # horas_contratadas = safe_to_decimal(row[:horas_contratadas])
        # HistorialContrato.create!(trabajador: trabajador, fecha_inicio_vigencia: Date.new(2024, 12, 16), horas_semanales_contratadas: horas_contratadas)
      end
      puts "Procesado horario y contrato para: #{nombre_trabajador}"
    end
    puts "-> Finalizada la importación de horarios y contratos."
    puts "\n== [TAREA RAKE] Importación completa desde Excel finalizada. =="
  end
end
