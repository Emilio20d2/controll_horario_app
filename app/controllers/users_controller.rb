class UsersController < ApplicationController
  # Permitimos que los usuarios no logueados accedan a las páginas de 'new' (registro) y 'create' (crear cuenta).
  skip_before_action :require_user, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # Inicia sesión automáticamente para el nuevo usuario.
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Cuenta creada con éxito. ¡Bienvenido!"
    else
      # Si hay errores de validación, vuelve a mostrar el formulario.
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end