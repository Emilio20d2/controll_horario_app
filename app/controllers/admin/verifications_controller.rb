# frozen_string_literal: true

module Admin
  # Este controlador gestiona la verificación de la contraseña del administrador
  # para acciones sensibles, como eliminar registros.
  class VerificationsController < ApplicationController
    # Aseguramos que solo se pueda acceder si hay un usuario logueado.
    before_action :require_user

    # POST /admin/verifications
    def create
      # Usamos el método `authenticate` de `has_secure_password` para verificar la contraseña.
      if current_user.authenticate(params[:password])
        # Si la contraseña es correcta, devolvemos una respuesta HTTP 200 OK sin contenido.
        head :ok
      else
        # Si es incorrecta, devolvemos un error HTTP 401 Unauthorized con un mensaje JSON.
        render json: { error: 'La contraseña proporcionada es incorrecta.' }, status: :unauthorized
      end
    end
  end
end