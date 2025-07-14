# =================================================================
# Archivo 1 (A MODIFICAR): config/routes.rb
# =================================================================
# OBJETIVO: Asegurar que las rutas para la vista semanal, el guardado
# por fila y la previsualización AJAX están correctamente definidas.

Rails.application.routes.draw do
  # La raíz de la aplicación apuntará al menú principal.
  root "paginas#menu"

  # Rutas para la gestión de usuarios y sesiones
  get 'signup', to: 'users#new', as: 'signup'
  post 'users', to: 'users#create'
  get 'login', to: 'sessions#new', as: 'login'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: 'logout'

  # Rutas para la aplicación de Fichajes
  get 'fichajes/semanal', to: 'fichajes#semanal'
  post 'fichajes/procesar_fila', to: 'fichajes#procesar_fila', as: 'procesar_fila_trabajador'
  post 'fichajes/previsualizar', to: 'fichajes#previsualizar', as: 'previsualizar_fila'

  # Ruta para el historial de movimientos de un trabajador (restringido a IDs numéricos)
  get 'trabajadores/:trabajador_id/movimientos', to: 'movimientos#index', as: 'trabajador_movimientos', constraints: { trabajador_id: /\d+/ }

  # Rutas para la sección de configuración/administración
  namespace :admin do
    root 'dashboard#index'
    resources :trabajadores do
      resources :historial_contratos, only: [:new, :create], path: 'jornada', path_names: { new: 'nueva' }
      resources :asignacion_turnos, only: [:new, :create], path: 'horario', path_names: { new: 'cambiar' }
      resources :movimiento_bolsas, only: [:new, :create], path: 'ajuste-manual'
      resources :historial_jornada_anuales, only: [:create], path: 'balance-anual'
    end
    # Habilitamos el CRUD completo para festivos, excepto la vista 'show' que no es necesaria.
    resources :festivos, except: [:show]
    # Habilitamos el CRUD completo para los tipos de ausencia eliminando la restricción 'only'.
    resources :tipo_ausencias
    resources :tipo_contratos, except: [:show, :destroy]
    resources :jornada_anual, as: 'configuracion_jornadas', controller: 'jornada_anual', except: [:show]
  end

  # Ruta para los informes en PDF
  get 'informes/saldos', to: 'informes#saldos', as: 'informe_saldos'

  # Ruta de health check de Rails
  get "up" => "rails/health#show", as: :rails_health_check
end
