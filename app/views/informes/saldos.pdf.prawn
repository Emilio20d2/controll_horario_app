# app/views/informes/saldos.pdf.prawn

# --- Encabezado (se repite en todas las páginas) ---
repeat(:all) do
  bounding_box([bounds.left, bounds.top], width: bounds.width) do
    text "Nombre de la Empresa S.L.", size: 10, style: :italic
    stroke_horizontal_rule
  end
end

# --- Título ---
move_down 30 # Espacio para el encabezado
font "Helvetica", style: :bold
font_size 20
text "Informe de Saldos de Horas", align: :center
move_down 10
font_size 12
text "Generado el: #{l(Date.today, format: :long)}", align: :center
move_down 20

# --- Preparación de Datos para la Tabla ---
font "Helvetica"
font_size 10

table_data = [
  # Cabecera de la tabla
  [
    { content: "Trabajador", font_style: :bold },
    { content: "H. Acumuladas", font_style: :bold },
    { content: "H. Fest. Trabajado", font_style: :bold },
    { content: "H. Fest. Libranza", font_style: :bold }
  ]
]

# Filas de la tabla
@trabajadores.each do |trabajador|
  saldo = trabajador.bolsa_horas_saldo
  table_data << [
    trabajador.nombre,
    saldo ? "%.2f" % saldo.horas_trabajadas_acumuladas : "0.00",
    saldo ? "%.2f" % saldo.horas_festivo_trabajado : "0.00",
    saldo ? "%.2f" % saldo.horas_festivo_libranza : "0.00"
  ]
end

# --- Renderizado de la Tabla ---
table(table_data, header: true, width: bounds.width) do
  row(0).background_color = '5F9EA0' # Color corporativo
  row(0).text_color = 'FFFFFF'
  cells.padding = [5, 10]
  cells.border_width = 0.5
  cells.border_color = 'AAAAAA'
  column(0).align = :left
  column(1..3).align = :right
end

# --- Pie de Página ---
page_number_string = "Página <page> de <total>"
number_pages page_number_string, at: [bounds.right - 150, 0], width: 150, align: :right, size: 9
