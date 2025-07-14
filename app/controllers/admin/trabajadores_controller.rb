class Admin::TrabajadoresController < ApplicationController
  layout 'admin'

  before_action :set_trabajador, only: [:show, :edit, :update, :destroy]
  before_action :load_select_collections, only: [:new, :create, :edit, :update]

  def index
    @trabajadores = Trabajador.includes(:tipo_contrato, :bolsa_horas_saldo).order(:nombre)
  end

  # Esta es la acción que renderizará la "Ficha de Empleado" completa.
   def show
    @trabajador = Trabajador.find(params[:id])
    @asignaciones_turno = @trabajador.asignacion_turnos.includes(:plantilla_horario).order(fecha_inicio: :desc)
    @movimientos_bolsa = @trabajador.movimiento_bolsas.order(fecha_efectiva: :desc)
    @historial_jornada_anual_registros = @trabajador.historial_jornada_anuales.order(anio: :desc)

    # Añadimos la carga del historial de contratos, que faltaba y causaba el error en la vista.
    # Lo ordenamos por fecha de inicio descendente para mostrar el más reciente primero.
    @historial_contratos = @trabajador.historial_contratos.order(fecha_inicio_vigencia: :desc)
  end

  def new
    @trabajador = Trabajador.new
    # Preparamos un hash vacío para el formulario de la parrilla de horarios.
    @horario_actual = {}
  end

  def edit
  end

  def create
    # Extraemos los parámetros que no son atributos directos del trabajador.
    horario_params = params.fetch(:horario, {}).permit!.to_h
    saldos_params = params.fetch(:saldos, {}).permit(:horas, :festivos, :libranza).to_h

    # `fecha_implantacion` es un campo virtual que no está en el modelo Trabajador.
    strong_params = trabajador_params
    fecha_implantacion_str = strong_params.delete(:fecha_implantacion)

    @trabajador = Trabajador.new(strong_params)

    # Usamos una transacción para asegurar la integridad de los datos.
    # Si algo falla, se revierte toda la operación.
    ActiveRecord::Base.transaction do
      # Validamos la fecha de implantación antes de usarla.
      fecha_implantacion = Date.parse(fecha_implantacion_str)

      # 1. Guardar el trabajador
      @trabajador.save!

      # 2. Crear el horario (si se proporcionó)
      # `any?(&:present?)` comprueba si se ha rellenado al menos una hora en la parrilla.
      if horario_params.values.any? { |turno| turno.values.any?(&:present?) }
        plantilla = PlantillaHorario.create!(
          nombre: "Horario inicial para #{@trabajador.nombre}",
          horario: horario_params,
          fecha_referencia: fecha_implantacion
        )
        AsignacionTurno.create!(
          trabajador: @trabajador,
          plantilla_horario: plantilla,
          fecha_inicio: fecha_implantacion
        )
      end

      # 3. Crear el primer registro en el historial de contratos
      if @trabajador.jornada_semanal_actual.present?
        HistorialContrato.create!(
          trabajador: @trabajador,
          fecha_inicio_vigencia: fecha_implantacion,
          horas_semanales_contratadas: @trabajador.jornada_semanal_actual
        )
      end

      # 4. Crear los movimientos de saldo inicial
      crear_movimientos_de_saldo_inicial(saldos_params, fecha_implantacion)

      # 5. Crear y calcular la bolsa de saldos totales
      saldo_obj = BolsaHorasSaldo.create!(trabajador: @trabajador)
      saldo_obj.update!(
        horas: @trabajador.movimiento_bolsas.where(categoria_bolsa_afectada: :horas).sum(:cantidad_horas),
        festivos: @trabajador.movimiento_bolsas.where(categoria_bolsa_afectada: :festivos).sum(:cantidad_horas),
        libranza: @trabajador.movimiento_bolsas.where(categoria_bolsa_afectada: :libranza).sum(:cantidad_horas)
      )

      redirect_to admin_trabajadores_path, notice: 'Trabajador creado con éxito.'
    end
  rescue ActiveRecord::RecordInvalid => e
    # Si algo falla en la transacción, se llega aquí.
    # Preparamos las variables que la vista `new` necesita para renderizarse de nuevo.
    @horario_actual = horario_params
    # Añadimos el error de la transacción al objeto trabajador para que se muestre en el formulario.
    @trabajador.errors.add(:base, "Error al crear el trabajador: #{e.message}")
    render :new, status: :unprocessable_entity
  rescue ArgumentError => e
    # Capturamos errores como una fecha inválida.
    @horario_actual = horario_params
    @trabajador.errors.add(:fecha_implantacion, "no es válida: #{e.message}")
    render :new, status: :unprocessable_entity
  end

  def update
    if @trabajador.update(trabajador_params)
      redirect_to admin_trabajadores_path, notice: 'Trabajador actualizado con éxito.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Leemos la contraseña del formulario. La vista deberá enviar este parámetro.
    password = params[:current_password]

    # Verificamos que el usuario actual esté autenticado y que la contraseña sea correcta.
    # Asumimos que tienes un método `current_user` disponible en ApplicationController.
    if current_user&.authenticate(password)
      @trabajador.destroy
      redirect_to admin_trabajadores_path, notice: 'Trabajador eliminado con éxito.', status: :see_other
    else
      redirect_to admin_trabajador_path(@trabajador), alert: 'Contraseña incorrecta. No se ha podido eliminar al trabajador.'
    end
  end

  private

  def set_trabajador
    @trabajador = Trabajador.find(params[:id])
  end

  def load_select_collections
    @tipos_contrato = TipoContrato.all
  end

  def trabajador_params
    # Permitimos el nuevo campo virtual :fecha_implantacion
    params.require(:trabajador).permit(:nombre, :tipo_contrato_id, :jornada_semanal_actual, :fecha_implantacion)
  end

  # Nuevo método privado para encapsular la lógica de creación de saldos iniciales.
  def crear_movimientos_de_saldo_inicial(saldos, fecha)
    concepto_base = "Saldo inicial (Alta #{fecha.strftime('%Y-%m-%d')})"

    # Mapeamos los nombres del formulario a las categorías del modelo.
    mapa_saldos = {
      horas: :horas,
      festivos: :festivos,
      libranza: :libranza
    }

    mapa_saldos.each do |param_key, categoria_bolsa|
      cantidad = BigDecimal(saldos[param_key] || "0")
      if cantidad.nonzero?
        MovimientoBolsa.create!(
          trabajador: @trabajador,
          tipo_movimiento: :saldo_inicial,
          categoria_bolsa_afectada: categoria_bolsa,
          cantidad_horas: cantidad,
          fecha_efectiva: fecha,
          concepto: concepto_base
        )
      end
    end
  end
end