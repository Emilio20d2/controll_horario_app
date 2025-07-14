class ApplicationController < ActionController::Base
  # Esta línea protegerá toda la aplicación por defecto.
  # Cualquier página requerirá que el usuario haya iniciado sesión.
  before_action :require_user

  # Añade estos helpers para que estén disponibles en todas las vistas y controladores.
  helper_method :current_user, :logged_in?

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_user
    redirect_to login_path, alert: "Debes iniciar sesión para acceder a esta página." unless logged_in?
  end
end