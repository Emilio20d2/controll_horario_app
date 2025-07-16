# Estándares de Codificación y Decisiones Arquitectónicas

Este documento resume las decisiones técnicas y los patrones de codificación clave adoptados en este proyecto para garantizar su consistencia, mantenibilidad y precisión.

## 1. Unidad de Medida para el Tiempo

**Toda magnitud temporal en la aplicación se almacena y calcula en MINUTOS usando números ENTEROS (`integer`).**

*   **Motivación:** Eliminar por completo los errores de redondeo asociados a la aritmética de punto flotante (`float` o `decimal`), tal como se identificó en la auditoría inicial. Esto garantiza la máxima precisión en todos los cálculos de balance de horas.
*   **Implementación:**
    *   **Base de Datos:** Todas las columnas que antes eran `decimal` o `float` para almacenar horas (ej. `horas_trabajadas`, `saldo_bolsa_horas`, etc.) son ahora de tipo `integer`.
    *   **Backend (Ruby on Rails):**
        *   Toda la lógica de negocio en modelos y controladores opera directamente con minutos.
        *   La conversión de horas a minutos (multiplicando por 60) se realiza únicamente al recibir datos desde una fuente externa (ej. formularios de administrador).
        *   La conversión de minutos a horas (dividiendo por 60.0) se realiza únicamente al enviar datos a una API (`semana_data`) o al renderizar una vista que requiera formato de horas.
    *   **Frontend (Stimulus JS):**
        *   El controlador `semanal_controller.js` espera recibir todas las unidades de tiempo en **horas decimales** desde la API `semana_data`.
        *   Todos los cálculos internos para la previsualización se realizan utilizando estas horas decimales. El formato final (`.toFixed(2)`) se aplica solo al actualizar el texto en la interfaz.

## 2. Flujo de Datos en la Vista Semanal

La vista de confirmación semanal (`fichajes#semanal`) opera bajo un patrón moderno para desacoplar el frontend del backend.

1.  **Carga Inicial:** La página Rails renderiza la estructura HTML inicial y los `data-attributes` para el controlador Stimulus (`semanal_controller.js`).
2.  **Petición de Datos (API):** Inmediatamente, `semanal_controller.js` realiza una petición `fetch` al endpoint `fichajes#semana_data`.
3.  **Respuesta JSON:** Este endpoint es la **única fuente de verdad**. Devuelve un objeto JSON que contiene todos los datos necesarios: trabajadores, reglas, festivos, horas teóricas y entradas guardadas.
4.  **Previsualización en Cliente:** Todos los cálculos de previsualización (impacto en bolsas, etc.) se realizan en tiempo real en el navegador dentro de `semanal_controller.js`, proporcionando una experiencia de usuario fluida sin necesidad de recargar la página.
5.  **Guardado Final:** La acción `procesarFila` del controlador envía los datos finales de una fila al backend para su persistencia definitiva.