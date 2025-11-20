Rails.application.routes.draw do
  root "home#index"

  get  "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get    "logout", to: "sessions#destroy"

  get 'auth/:provider/callback', to: 'sessions#omniauth'
  post 'auth/:provider/callback', to: 'sessions#omniauth'
  get 'auth/failure', to: 'sessions#auth_failure'

  get 'forgot_password', to: 'password_resets#new'
  post 'forgot_password', to: 'password_resets#create'
  get 'reset_password/:token', to: 'password_resets#edit', as: :reset_password
  patch 'reset_password/:token', to: 'password_resets#update'

  get "dashboard", to: "dashboard#index"

  resource :profile, only: [:edit, :update]

  resource :password, only: [:edit, :update]

  get "/passwords/edit",   to: "passwords#edit"
  get "/passwords/update", to: "passwords#edit"

  resources :recipients

  resources :events do
    member do
      post :add_recipient
      delete :remove_recipient
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
