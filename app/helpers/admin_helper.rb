module AdminHelper
  # Crea un enlace de navegación para el menú de admin.
  # Añade la clase 'active' de Bootstrap si la ruta actual
  # pertenece al controlador que se le pasa como argumento.
  def admin_nav_link(text, path, active_controller_name)
    active_class = controller.controller_name == active_controller_name ? 'active' : ''
    link_to text, path, class: "nav-link #{active_class}"
  end
end