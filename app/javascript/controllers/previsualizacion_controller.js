import { Controller } from "@hotwired/stimulus"

/**
 * Controlador para la previsualización en tiempo real de los balances de horas en la fila de un trabajador.
 * Lógica de cálculo reconstruida para máxima robustez, claridad y para evitar fallos silenciosos.
 */
export default class extends Controller {
  static targets = [
    "totalComputadas",
    "impactoOrdinaria",
    "impactoFestivos",
    "impactoLibranza",
    "submitButton"
  ]

  connect() {
    this.recalcular();
  }

  /**
   * Parsea un valor a float de forma segura, manejando comas, vacíos y valores no numéricos.
   * @param {string | number} value - El valor a parsear.
   * @returns {number} - El número parseado, o 0 si es inválido.
   */
  _parseFloat(value) {
    if (typeof value !== 'string' && typeof value !== 'number') return 0;
    const stringValue = String(value).trim().replace(',', '.');
    if (stringValue === '') return 0;
    const number = parseFloat(stringValue);
    return isNaN(number) ? 0 : number;
  }

  recalcular(event) {
    if (event) {
      this.element.classList.add('fila-modificada');
    }
    if (this.hasSubmitButtonTarget) {
      this.resetSubmitButton();
    }

    const celdasDia = this.element.querySelectorAll('.day-cell');
    const datosSemana = Array.from(celdasDia).map(celda => this._leerDatosCelda(celda));
    const config = this._leerConfiguracionContrato();

    const balancesDiarios = datosSemana.map(dia => {
      let horasComputadasDia = dia.trabajadas;
      if (dia.ausencia.id) {
        if (dia.ausencia.esRetribuida) {
          horasComputadasDia += dia.ausencia.horas;
        }
      }

      let horasRealesComputablesDia = dia.trabajadas;
      horasRealesComputablesDia -= dia.compPagadas;
      if (dia.pagoDoble || (dia.esFestivo && config.acumulaFestivoTrabajado && dia.trabajadas > 0)) {
        horasRealesComputablesDia = 0;
      }
      const horasConsumidasBolsaOrdinariaDia = (dia.ausencia.categoriaBolsa === 'horas' ? dia.ausencia.horas : 0);
      const impactoOrdinariaDia = (horasRealesComputablesDia - dia.teoricas) - horasConsumidasBolsaOrdinariaDia;

      let horasGeneradasBolsaFestivosDia = 0;
      if (dia.esFestivo && !dia.pagoDoble && config.acumulaFestivoTrabajado && dia.trabajadas > 0) {
        horasGeneradasBolsaFestivosDia = dia.trabajadas - dia.compPagadas;
      }
      const horasConsumidasBolsaFestivosDia = (dia.ausencia.categoriaBolsa === 'festivos' ? dia.ausencia.horas : 0);
      const impactoFestivosDia = horasGeneradasBolsaFestivosDia - horasConsumidasBolsaFestivosDia;

      let horasGeneradasBolsaLibranzaDia = 0;
      if (dia.esFestivo && dia.teoricas === 0 && config.acumulaFestivoEnLibranza) {
        horasGeneradasBolsaLibranzaDia = config.jornadaSemanal / 5;
      }
      const horasConsumidasBolsaLibranzaDia = (dia.ausencia.categoriaBolsa === 'libranza' ? dia.ausencia.horas : 0);
      const impactoLibranzaDia = horasGeneradasBolsaLibranzaDia - horasConsumidasBolsaLibranzaDia;

      return {
        computadas: horasComputadasDia,
        impactoOrdinaria: impactoOrdinariaDia,
        impactoFestivos: impactoFestivosDia,
        impactoLibranza: impactoLibranzaDia
      };
    });

    const totalComputadoSemana = balancesDiarios.reduce((sum, dia) => sum + dia.computadas, 0);
    const impactoOrdinariaSemana = balancesDiarios.reduce((sum, dia) => sum + dia.impactoOrdinaria, 0);
    const impactoFestivosSemana = balancesDiarios.reduce((sum, dia) => sum + dia.impactoFestivos, 0);
    const impactoLibranzaSemana = balancesDiarios.reduce((sum, dia) => sum + dia.impactoLibranza, 0);

    if (this.hasTotalComputadasTarget) this.totalComputadasTarget.textContent = `${totalComputadoSemana.toFixed(2)}h`;
    if (this.hasImpactoOrdinariaTarget) this.impactoOrdinariaTarget.textContent = `${impactoOrdinariaSemana.toFixed(2)}h`;
    if (this.hasImpactoFestivosTarget) this.impactoFestivosTarget.textContent = `${impactoFestivosSemana.toFixed(2)}h`;
    if (this.hasImpactoLibranzaTarget) this.impactoLibranzaTarget.textContent = `${impactoLibranzaSemana.toFixed(2)}h`;
  }

  /**
   * Lee la configuración del contrato desde los data-attributes de la fila.
   */
  _leerConfiguracionContrato() {
    return {
      jornadaSemanal: this._parseFloat(this.element.dataset.jornadaSemanal),
      acumulaFestivoTrabajado: this.element.dataset.acumulaFestivoTrabajado === 'true',
      acumulaFestivoEnLibranza: this.element.dataset.acumulaFestivoEnLibranza === 'true'
    };
  }

  /**
   * Lee todos los datos relevantes de una celda de día.
   */
  _leerDatosCelda(celda) {
    const teoricas = this._parseFloat(celda.dataset.teoricas);

    const selectAusencia = celda.querySelector('select[name*="[tipo_ausencia_id]"]');
    let ausenciaData = { id: null, horas: 0, categoriaBolsa: null, esRetribuida: false };
    let esAusenciaDiaCompleto = false;

    if (selectAusencia && selectAusencia.value) {
      const selectedOption = selectAusencia.options[selectAusencia.selectedIndex];
      ausenciaData.id = selectAusencia.value;
      ausenciaData.esRetribuida = selectedOption.dataset.esRetribuida === 'true';
      ausenciaData.categoriaBolsa = selectedOption.dataset.categoriaBolsa;

      if (selectedOption.dataset.fraccionable === 'true') {
        const inputHorasAusencia = celda.querySelector('input[name*="[horas_ausencia]"]');
        ausenciaData.horas = this._parseFloat(inputHorasAusencia.value);
      } else {
        ausenciaData.horas = teoricas;
        esAusenciaDiaCompleto = true;
      }
    }

    let trabajadas = 0;
    if (esAusenciaDiaCompleto) {
      trabajadas = 0;
    } else {
      const inputHoras = celda.querySelector('input[name*="[horas_trabajadas]"]');
      const valorHoras = inputHoras.value.trim() !== '' ? inputHoras.value : inputHoras.placeholder;
      trabajadas = this._parseFloat(valorHoras);
    }

    const inputComp = celda.querySelector('input[name*="[horas_comp_pagadas]"]');
    const compPagadas = this._parseFloat(inputComp.value);

    const checkPagoDoble = celda.querySelector('input[name*="[pago_doble]"]');
    const pagoDoble = checkPagoDoble ? checkPagoDoble.checked : false;

    return {
      teoricas,
      trabajadas,
      compPagadas,
      pagoDoble,
      esFestivo: celda.classList.contains('festivo'),
      ausencia: ausenciaData
    };
  }

  /**
   * Resetea el estado del botón de "Confirmar" si estaba como "Procesado".
   */
  resetSubmitButton() {
    const button = this.submitButtonTarget;
    if (button.classList.contains('procesado')) {
      button.classList.remove('procesado', 'btn-success');
      button.classList.add('btn-primary');
      button.textContent = "Confirmar";
    }
  }
}
