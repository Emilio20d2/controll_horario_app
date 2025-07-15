import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "totalComputadas", "impactoOrdinaria", "impactoFestivos", "impactoLibranza" ]
  static values = {
    jornadaSemanal: Number,
    acumulaFestivos: Boolean,
    acumulaLibranza: Boolean
  }

  connect() {
    this.recalcular()
  }

  recalcular() {
    let totalTeoricoSemanal = 0
    let totalHorasComputadas = 0
    let impactoBolsaOrdinaria = 0
    let impactoBolsaFestivos = 0
    let impactoBolsaLibranza = 0

    const celdasDia = this.element.querySelectorAll('.day-cell')

    celdasDia.forEach(celda => {
      const teoricasDia = parseFloat(celda.dataset.teoricas || 0)
      const esFestivo = celda.dataset.festivo === 'true'
      const esApertura = celda.dataset.aperturaAutorizada === 'true'
      
      const inputHoras = celda.querySelector('input[name*="[horas_trabajadas]"]')
      const inputComp = celda.querySelector('input[name*="[horas_complementarias_pagadas]"]')
      const checkPagoDoble = celda.querySelector('input[name*="[pago_doble]"]')
      const selectAusencia = celda.querySelector('select[name*="[tipo_ausencia_id]"]')
      const inputHorasAusencia = celda.querySelector('input[name*="[horas_ausencia]"]')
      
      let horasTrabajadas = parseFloat(inputHoras.value || inputHoras.placeholder || 0)
      let horasComp = parseFloat(inputComp.value || 0)
      let pagoDoble = checkPagoDoble ? checkPagoDoble.checked : false
      
      let horasAusencia = 0
      let ausenciaGeneraDeuda = false
      let ausenciaEsRetribuida = false
      let ausenciaAfectaBolsa = "ninguna"
      let esFraccionable = false

      if (selectAusencia && selectAusencia.value !== "") {
        const selectedOption = selectAusencia.options[selectAusencia.selectedIndex]
        esFraccionable = selectedOption.dataset.esFraccionable === 'true'
        
        if (esFraccionable) {
          inputHorasAusencia.style.display = 'block'
          horasAusencia = parseFloat(inputHorasAusencia.value || 0)
        } else {
          inputHorasAusencia.style.display = 'none'
          inputHorasAusencia.value = ''
          horasAusencia = teoricasDia
        }
        
        ausenciaGeneraDeuda = selectedOption.dataset.generaDeuda === 'true'
        ausenciaEsRetribuida = selectedOption.dataset.esRetribuida === 'true'
        ausenciaAfectaBolsa = selectedOption.dataset.afectaBolsa
      } else {
        inputHorasAusencia.style.display = 'none'
        inputHorasAusencia.value = ''
      }

      totalTeoricoSemanal += teoricasDia
      
      // Cálculo 1: Total Horas Computadas
      totalHorasComputadas += horasTrabajadas
      if (ausenciaEsRetribuida) { totalHorasComputadas += horasAusencia }
      if (ausenciaGeneraDeuda) { totalHorasComputadas -= horasAusencia }

      // Cálculo 2, 3, 4: Impacto en Bolsas
      let horasParaBalance = horasTrabajadas - horasComp
      
      if (esFestivo && pagoDoble) { horasParaBalance = 0 } 
      else if (esFestivo && !pagoDoble && this.acumulaFestivosValue) {
        impactoBolsaFestivos += horasTrabajadas
        horasParaBalance = 0
      }
      
      if (ausenciaAfectaBolsa === 'festivo_trabajado') { impactoBolsaFestivos -= horasAusencia }
      else if (ausenciaAfectaBolsa === 'festivo_libranza') { impactoBolsaLibranza -= horasAusencia }
      
      if (esFestivo && !esApertura && teoricasDia === 0 && this.acumulaLibranzaValue) {
        impactoBolsaLibranza += (this.jornadaSemanalValue / 5.0)
      }

      impactoBolsaOrdinaria += (horasParaBalance - teoricasDia)
      if (ausenciaGeneraDeuda) { impactoBolsaOrdinaria -= horasAusencia }
    })

    // Actualizar la interfaz
    this.totalComputadasTarget.textContent = `${totalHorasComputadas.toFixed(2)}h`
    this.impactoOrdinariaTarget.textContent = `${impactoBolsaOrdinaria.toFixed(2)}h`
    this.impactoFestivosTarget.textContent = `${impactoBolsaFestivos.toFixed(2)}h`
    this.impactoLibranzaTarget.textContent = `${impactoBolsaLibranza.toFixed(2)}h`
    
    this.element.classList.add('fila-modificada')
  }
}