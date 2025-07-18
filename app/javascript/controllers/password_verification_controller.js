import { Controller } from "@hotwired/stimulus"
// Importamos la clase Modal de Bootstrap para poder controlarlo desde JS.
import { Modal } from "bootstrap"

// Conecta a data-controller="password-verification"
export default class extends Controller {
  // Definimos los elementos con los que vamos a interactuar dentro del modal.
  static targets = ["deleteUrl", "passwordField", "errorContainer", "submitButton"]

  connect() {
    // Obtenemos la instancia del modal de Bootstrap al conectar el controlador.
    this.modal = new Modal(this.element)
  }

  /**
   * Acción que se ejecuta cuando se hace clic en cualquier botón "Eliminar".
   * Su trabajo es capturar la URL de borrado específica de ese botón y
   * prepararla en el modal para su uso posterior.
   */
  setDeleteUrl(event) {
    // Obtenemos la URL desde el atributo 'data-password-verification-delete-url-value' del botón.
    const deleteUrl = event.currentTarget.dataset.passwordVerificationDeleteUrlValue;

    // La guardamos en el campo oculto del formulario del modal.
    this.deleteUrlTarget.value = deleteUrl;

    // Limpiamos cualquier estado anterior del modal.
    this.passwordFieldTarget.value = "";
    this.errorContainerTarget.textContent = "";
    this.submitButtonTarget.disabled = false;
    this.submitButtonTarget.textContent = "Verificar y Continuar";

    // Abrimos el modal de forma programática para garantizar su visualización.
    this.modal.show();
  }

  /**
   * Acción que se ejecuta cuando se envía el formulario del modal.
   * Verifica la contraseña y, si es correcta, ejecuta la eliminación.
   */
  async verify(event) {
    event.preventDefault(); // Evitamos que el formulario se envíe de la forma tradicional.

    const password = this.passwordFieldTarget.value;
    const deleteUrl = this.deleteUrlTarget.value;
    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    // Deshabilitamos el botón para evitar múltiples clics.
    this.submitButtonTarget.disabled = true;
    this.submitButtonTarget.textContent = "Verificando...";
    this.errorContainerTarget.textContent = "";

    try {
      // 1. Verificamos la contraseña contra nuestro endpoint en Rails.
      const verificationResponse = await fetch('/admin/verifications', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ password: password })
      });

      if (!verificationResponse.ok) {
        // Si la contraseña es incorrecta, el servidor responderá con un error (ej. 401 Unauthorized).
        const errorData = await verificationResponse.json();
        throw new Error(errorData.error || 'Contraseña incorrecta');
      }

      // 2. Si la contraseña es correcta, procedemos con la eliminación.
      this.submitButtonTarget.textContent = "Eliminando...";

      // Ocultamos el modal inmediatamente para una mejor experiencia de usuario.
      this.modal.hide();

      // **CORRECCIÓN CLAVE:** Usamos `requestSubmit()` en lugar de `submit()`.
      // Este método dispara todos los eventos de envío de formulario,
      // lo que permite que Turbo lo intercepte y gestione la redirección.
      this.submitDeleteForm(deleteUrl, csrfToken);

    } catch (error) {
      // Si algo falla (verificación o borrado), mostramos el error y reactivamos el botón.
      this.errorContainerTarget.textContent = error.message;
      this.submitButtonTarget.disabled = false;
      this.submitButtonTarget.textContent = "Verificar y Continuar";
    }
  }

  /**
   * Crea un formulario oculto y lo envía usando requestSubmit() para que Turbo lo intercepte.
   */
  submitDeleteForm(url, csrfToken) {
    const form = document.createElement('form');
    form.method = 'post';
    form.action = url;
    form.innerHTML = `<input name="_method" value="delete" type="hidden"><input name="authenticity_token" value="${csrfToken}" type="hidden">`;
    form.style.display = 'none'; // Aseguramos que el formulario no sea visible.
    document.body.appendChild(form);
    form.requestSubmit();
  }
}