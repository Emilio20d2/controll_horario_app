class SessionsController < ApplicationController
  # Saltamos la comprobación de login para las acciones de este controlador,
  # ya que es aquí donde el usuario inicia sesión.
  skip_before_action :require_user, only: [:new, :create]

  def new
    # Esta acción simplemente renderizará el formulario de login.
    # Si el usuario ya está logueado, lo redirigimos al menú principal.
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user&.authenticate(params[:session][:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Has iniciado sesión correctamente."
    else
      flash.now[:alert] = "El email o la contraseña son incorrectos."
      render 'new', status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Has cerrado la sesión."
  end
end