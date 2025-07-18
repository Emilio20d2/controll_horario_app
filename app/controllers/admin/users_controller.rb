class Admin::UsersController < ApplicationController
  layout 'admin'
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = User.all.order(:email)
  end

  def show
    # Esta acción podría usarse en el futuro para ver detalles del usuario.
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: 'Usuario creado con éxito.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # Hacemos una copia de los parámetros para poder modificarlos de forma segura.
    update_params = user_params.dup

    # Si el campo de contraseña y su confirmación están en blanco,
    # los eliminamos de los parámetros para evitar actualizar la contraseña.
    if update_params[:password].blank? && update_params[:password_confirmation].blank?
      update_params.delete(:password)
      update_params.delete(:password_confirmation)
    end

    if @user.update(update_params)
      redirect_to admin_users_path, notice: 'Usuario actualizado con éxito.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Añadimos una comprobación de seguridad para evitar que un usuario se elimine a sí mismo.
    if @user == current_user
      redirect_to admin_users_path, alert: 'No puedes eliminar tu propio usuario.'
    else
      @user.destroy
      redirect_to admin_users_path, notice: 'Usuario eliminado con éxito.', status: :see_other
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :email,
      :password,
      :password_confirmation
    )
  end
end
