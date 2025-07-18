# app/controllers/admin/base_controller.rb

# Este será el controlador base para toda la sección de administración.
# Su propósito es centralizar la configuración común, como la autenticación
# y, en este caso, forzar el uso del layout 'admin'.
class Admin::BaseController < ApplicationController
  layout 'admin'
end