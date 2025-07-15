import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "totalComputadas", 
    "impactoOrdinaria", 
    "impactoFestivos", 
    "impactoLibranza"
  ]
  static values = {
    jornadaSemanal: Number,
    acumulaFestivos: Boolean,
    acumulaLibranza: Boolean
  }

  connect() {
    // Si el campo de horas está vacío, inicializarlo con el valor teórico
    this.element.querySelectorAll('input[name*="[horas_trabajadas]"]').forEach(input => {
      if (!input.value && input.placeholder) {
        input.value = input.placeholder
      }
    })

    // Realizar el primer cálculo al cargar la página
    this.recalcular()
  }

  recalcular() {
    let totalTeoricoSemanal = 0
    let totalRealComputable = 0
    let totalFestivosTrabajados = 0
    let totalLibranzaFestivos = 0
    let totalHorasComputadas = 0

    const celdasDia = this.element.querySelectorAll('.day-cell')

    celdasDia.forEach(celda => {
      // Leer los valores de cada día desde los inputs y los data-attributes
      const teoricasDia = parseFloat(celda.dataset.teoricas || 0)
      const esFestivo = celda.dataset.festivo === 'true'
      const esApertura = celda.dataset.aperturaAutorizada === 'true'
      
      const inputHoras = celda.querySelector('input[name*="[horas_trabajadas]"]')
      const inputComp = celda.querySelector('input[name*="[horas_comp_pagadas]"]')
      const inputAusenciaHoras = celda.querySelector('input[name*="[horas_ausencia]"]')
      const checkPagoDoble = celda.querySelector('input[name*="[pago_doble]"]')
      const selectAusencia = celda.querySelector('select[name*="[tipo_ausencia_id]"]')
      
      let horasTrabajadas = parseFloat(inputHoras.value || inputHoras.placeholder || 0)
      let horasComp = parseFloat(inputComp.value || 0)
      let pagoDoble = checkPagoDoble ? checkPagoDoble.checked : false
      
      let horasAusencia = 0
      let ausenciaGeneraDeuda = false
      if (selectAusencia && selectAusencia.value !== "") {
        const selectedOption = selectAusencia.options[selectAusencia.selectedIndex]
        const esFraccionable = selectedOption.dataset.fraccionable === 'true'
        horasAusencia = esFraccionable ? parseFloat(inputAusenciaHoras.value || 0) : teoricasDia
        ausenciaGeneraDeuda = selectedOption.dataset.generaDeuda === 'true'
      }

      totalTeoricoSemanal += teoricasDia
      
      // Cálculo para "Total Horas Computadas"
      totalHorasComputadas += horasTrabajadas
      if (!ausenciaGeneraDeuda) {
        totalHorasComputadas += horasAusencia
      } else {
        totalHorasComputadas -= horasAusencia
      }

      // Cálculo para "Impacto Bolsa HORAS"
      let horasParaBalance = horasTrabajadas
      
      if (esFestivo && pagoDoble) {
        horasParaBalance = 0
      } else if (esFestivo && !pagoDoble && this.acumulaFestivosValue) {
        totalFestivosTrabajados += horasTrabajadas
        horasParaBalance = 0
      }
      
      horasParaBalance -= horasComp
      totalRealComputable += horasParaBalance

      // Cálculo para "Impacto Bolsa LIBRANZA"
      if (esFestivo && !esApertura && teoricasDia === 0 && this.acumulaLibranzaValue) {
        totalLibranzaFestivos += (this.jornadaSemanalValue / 5.0)
      }
    })

    const balance = totalRealComputable - totalTeoricoSemanal

    // Actualizar la interfaz con los resultados
    this.totalComputadasTarget.textContent = `${totalHorasComputadas.toFixed(2)}h`
    this.impactoOrdinariaTarget.textContent = `${balance.toFixed(2)}h`
    this.impactoFestivosTarget.textContent = `${totalFestivosTrabajados.toFixed(2)}h`
    this.impactoLibranzaTarget.textContent = `${totalLibranzaFestivos.toFixed(2)}h`
    
    // Resaltar la fila
    this.element.classList.add('fila-modificada')
  }
}
