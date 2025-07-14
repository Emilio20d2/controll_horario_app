import { Controller } from "@hotwired/stimulus"

/**
 * Controlador para la lógica de una celda individual en la tabla semanal.
 * Gestiona la visibilidad de campos y la visualización de nombres de ausencia.
 */
export default class extends Controller {
  static targets = ["tipoAusenciaSelect", "horasAusenciaWrapper"]

  connect() {
    // Al conectar, nos aseguramos de que el estado inicial del texto de las opciones
    // sea la abreviatura, por si la página se recarga con un valor ya seleccionado.
    this.showAbbreviations();
    // También ajustamos la visibilidad del campo de horas de ausencia al cargar.
    this.toggleAusenciaHoras();
  }

  /**
   * Muestra los nombres completos de las ausencias en el desplegable.
   * Se activa cuando el usuario hace focus en el select.
   */
  showFullNames() {
    const options = this.tipoAusenciaSelectTarget.options;
    for (let i = 0; i < options.length; i++) {
      const option = options[i];
      if (option.dataset.nombre) {
        option.textContent = option.dataset.nombre;
      }
    }
  }

  /**
   * Muestra las abreviaturas de las ausencias en el desplegable.
   * Se activa cuando el usuario quita el focus del select (blur).
   */
  showAbbreviations() {
    const options = this.tipoAusenciaSelectTarget.options;
    for (let i = 0; i < options.length; i++) {
      const option = options[i];
      if (option.dataset.abreviatura) {
        option.textContent = option.dataset.abreviatura;
      }
    }
  }

  /**
   * Muestra u oculta el campo de "Horas Ausencia" dependiendo de si la
   * ausencia seleccionada es fraccionable.
   */
  toggleAusenciaHoras() {
    const selectedOption = this.tipoAusenciaSelectTarget.options[this.tipoAusenciaSelectTarget.selectedIndex];
    const esFraccionable = selectedOption && selectedOption.dataset.fraccionable === 'true';

    if (this.hasHorasAusenciaWrapperTarget) {
      this.horasAusenciaWrapperTarget.classList.toggle('d-none', !esFraccionable);
    }
  }
}
