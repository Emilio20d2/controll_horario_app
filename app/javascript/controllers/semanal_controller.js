import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="semanal"
export default class extends Controller {
  // Definimos los 'values' que esperamos recibir desde los atributos data-
  // en el HTML. Stimulus se encarga de convertir 'data-semanal-year-value' a 'yearValue'.
  static values = {
    year: Number,
    weekNum: Number
  }

  connect() {
    this.fetchData(); // Carga los datos al conectar el controlador
  }

  async fetchData() {
    // Construimos la URL del endpoint usando los values.
    // **IMPORTANTE**: El backend ahora SIEMPRE envía las horas como decimales.
    const url = `/fichajes/semana_data?year=${this.yearValue}&week_num=${this.weekNumValue}`;

    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Error en la petición: ${response.statusText}`);
      }
      const data = await response.json();

      // Almacenamos los datos en propiedades del controlador.
      this.fechasSemana = data.fechas_semana;
      this.trabajadores = data.trabajadores;
      this.tiposAusencia = data.tipos_ausencia;
      this.festivosSemana = data.festivos_semana;
      this.horasTeoricas = data.horas_teoricas;
      this.entradasDiarias = data.entradas_diarias; // Horas vienen en decimal
      this.semanasProcesadasIds = data.semanas_procesadas_ids;

      // Calcular todos los totales al cargar la página.
      this.element.querySelectorAll('.trabajador-row').forEach(fila => {
        this._calcularYActualizarFila(fila);
      });

    } catch (error) {
      console.error("No se pudieron cargar los datos de la semana:", error);
      // Opcional: Mostrar un mensaje de error al usuario.
      this.element.innerHTML = "<p class='text-danger text-center'>Error al cargar los datos. Por favor, intente recargar la página.</p>";
    }
  }

  /**
   * Disparador principal para recalcular los totales de una fila.
   * Se llamará cada vez que un input cambie dentro de una fila de trabajador.
   * @param {Event} event El evento que disparó la acción (ej. input, change).
   */
  recalcularFila(event) {
    // Fila completa (<tr>) que contiene el input que cambió.
    const fila = event.target.closest('.trabajador-row');
    if (!fila) return;

    this._calcularYActualizarFila(fila);
  }

  /**
   * Lógica central de cálculo y actualización para una fila.
   * Esta función es interna y puede ser llamada al cargar o al cambiar un input.
   * @param {HTMLElement} fila El elemento <tr> de la fila a procesar.
   */
  _calcularYActualizarFila(fila) {
    // Extraemos el ID del trabajador desde el id del elemento <tr>
    const trabajadorId = fila.id.split('_').pop();

    // Almacenar los datos de la semana leídos desde los inputs.
    const datosSemana = [];
    const celdas = fila.querySelectorAll('.day-cell');

    celdas.forEach((celda, index) => {
      const fecha = this.fechasSemana[index];
      const horasTrabajadasInput = celda.querySelector('input[name*="[horas_trabajadas]"]');
      const tipoAusenciaSelect = celda.querySelector('select[name*="[tipo_ausencia_id]"]');
      const horasAusenciaInput = celda.querySelector('input[name*="[horas_ausencia]"]');
      const hCompPagadasInput = celda.querySelector('input[name*="[horas_complementarias_pagadas]"]');
      const pagoDobleCheckbox = celda.querySelector('input[name*="[pago_doble]"]');

      // Leer los valores, convirtiendo a número y manejando valores por defecto.
      const horasTrabajadas = parseFloat(horasTrabajadasInput.value) || parseFloat(horasTrabajadasInput.placeholder) || 0;
      const tipoAusenciaId = tipoAusenciaSelect.value ? parseInt(tipoAusenciaSelect.value, 10) : null;
      const horasAusencia = parseFloat(horasAusenciaInput.value) || 0;
      const hCompPagadas = parseFloat(hCompPagadasInput.value) || 0;
      const pagoDoble = pagoDobleCheckbox ? pagoDobleCheckbox.checked : false;

      datosSemana.push({
        fecha: fecha,
        horasTrabajadas,
        tipoAusenciaId,
        hCompPagadas,
        horasAusencia,
        pagoDoble
      });
    });
    
    // Info del trabajador desde los datos cargados, usando el ID.
    const trabajador = this.trabajadores.find(t => t.id == trabajadorId);
    if (!trabajador) {
      console.error(`Trabajador con ID ${trabajadorId} no encontrado en los datos.`);
      return;
    }  
    
    // Inicializamos los acumuladores para los cálculos.
    let totalHorasComputadas = 0;
    let impactoBolsaOrdinaria = 0;
    let impactoBolsaFestivos = 0;
    let impactoBolsaLibranza = 0;
    
    // Recorremos los datos de cada día para calcular los acumulados.
    datosSemana.forEach((dia, index) => {
      const horasTeoricasDelDia = this.horasTeoricas[trabajadorId]?.[dia.fecha] || 0;
      const esFestivo = !!this.festivosSemana[dia.fecha];
      const esDiaLibre = horasTeoricasDelDia === 0;

      // 1. Total Horas Computadas (reutilizando la lógica de previsualizacion_controller.js)
      let computadasDelDia = dia.horasTrabajadas;
      let horasAusenciaDelDia = 0; // Necesitamos esta variable para los cálculos de bolsa.
      
      if (dia.tipoAusenciaId) {
        const tipoAusencia = this.tiposAusencia.find(ta => ta.id === dia.tipoAusenciaId);
        if (tipoAusencia) {
          // Horas de ausencia según si es fraccionable o no.
          horasAusenciaDelDia = tipoAusencia.es_fraccionable ? dia.horasAusencia : horasTeoricasDelDia;

          if (tipoAusencia.es_retribuida) { computadasDelDia += horasAusenciaDelDia; }
          if (tipoAusencia.genera_deuda) { computadasDelDia -= horasAusenciaDelDia; }
        }
      }
      totalHorasComputadas += computadasDelDia; // Acumulamos
      
      // 2. Bolsa FESTIVOS y LIBRANZA (Un día no puede generar para ambas bolsas a la vez)

      if (esFestivo && dia.horasTrabajadas > 0 && !dia.pagoDoble && trabajador.reglas_contrato.acumula_festivo_trabajado) {
        // Festivo trabajado sin pago doble -> a bolsa de festivos (si contrato lo permite)
        impactoBolsaFestivos += dia.horasTrabajadas;
      } else if (esFestivo && esDiaLibre && trabajador.reglas_contrato.acumula_festivo_libranza) {
        // Festivo en libranza -> genera bolsa de libranza (si contrato lo permite)
        const contrato = trabajador.contrato_vigente;
        // **CORRECCIÓN CLAVE**: Usamos los días laborables del contrato, no el número mágico 5.
        if (contrato.dias_laborables_semana > 0) {
          impactoBolsaLibranza += contrato.horas_semanales / contrato.dias_laborables_semana;
        }
      }
      
      // 3. Disfrute de bolsas (resta de horas)
      if (dia.tipoAusenciaId) {
        const tipoAusencia = this.tiposAusencia.find(ta => ta.id === dia.tipoAusenciaId);
        if (tipoAusencia?.bolsa_afectada === 'festivos') { impactoBolsaFestivos -= horasAusenciaDelDia; }
        if (tipoAusencia?.bolsa_afectada === 'libranza') { impactoBolsaLibranza -= horasAusenciaDelDia; }
      }

      // 4. Bolsa HORAS (Ordinaria) - Horas que cuentan para el balance diario.
      let horasParaBalanceDiario = dia.horasTrabajadas - dia.hCompPagadas;

      if (esFestivo && dia.horasTrabajadas > 0 && !dia.pagoDoble && trabajador.reglas_contrato.acumula_festivo_trabajado) {
        // Si las horas ya fueron a festivos, no cuentan para el ordinario.
        horasParaBalanceDiario = 0;
      }

      // El impacto es la diferencia entre las horas computables y las teóricas.
      impactoBolsaOrdinaria += (horasParaBalanceDiario - horasTeoricasDelDia);

      // Ausencia que genera deuda -> resta de la bolsa de horas.
      if (dia.tipoAusenciaId) {
        const tipoAusencia = this.tiposAusencia.find(ta => ta.id === dia.tipoAusenciaId);
        if (tipoAusencia?.genera_deuda) {
          impactoBolsaOrdinaria -= horasAusenciaDelDia;
        }
      }
    });

    // 5. Actualizar la interfaz con los resultados.
    this.actualizarVistaFila(fila, {
      totalComputadas: totalHorasComputadas,
      impactoOrdinaria: impactoBolsaOrdinaria,
      impactoFestivos: impactoBolsaFestivos,
      impactoLibranza: impactoBolsaLibranza,
    });
  }

  /**
   * Actualiza la previsualización en la fila especificada.
   * @param {HTMLElement} fila El elemento <tr> de la fila a actualizar.
   * @param {Object} resultados Un objeto con los valores calculados.
   */
  actualizarVistaFila(fila, resultados) {
    fila.querySelector('[data-previsualizacion-target="totalComputadas"]').textContent = `${resultados.totalComputadas.toFixed(2)}h`; // Formato: 0.00h
    fila.querySelector('[data-previsualizacion-target="impactoOrdinaria"]').textContent = `${resultados.impactoOrdinaria.toFixed(2)}h`;
    fila.querySelector('[data-previsualizacion-target="impactoFestivos"]').textContent = `${resultados.impactoFestivos.toFixed(2)}h`;
    fila.querySelector('[data-previsualizacion-target="impactoLibranza"]').textContent = `${resultados.impactoLibranza.toFixed(2)}h`;

    // Añadimos una clase para dar feedback visual de que la fila ha cambiado.
    fila.classList.add('fila-modificada');
  }
}
