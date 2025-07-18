import { Controller } from "@hotwired/stimulus"

// Conecta a data-controller="password-verification"
export default class extends Controller {

  /**
   * Acción que se ejecuta cuando se hace clic en cualquier botón "Eliminar".
   * Muestra un mensaje de confirmación y, en caso afirmativo,
   * envía la solicitud de borrado directamente.
   */
  setDeleteUrl(event) {
    const confirmationMessage =
      "Este proceso es irreversible. ¿Está seguro de que desea eliminar este elemento?";
    if (!window.confirm(confirmationMessage)) {
      return;
    }
    const deleteUrl = event.currentTarget.dataset.passwordVerificationDeleteUrlValue;
    const csrfToken = document.querySelector("meta[name='csrf-token']").content;
    this.submitDeleteForm(deleteUrl, csrfToken);
  }

  /**
   * Acción que se ejecuta cuando se envía el formulario del modal.
   * Verifica la contraseña y, si es correcta, ejecuta la eliminación.
   */
  // Método antiguo 'verify' eliminado

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