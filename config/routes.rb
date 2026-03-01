Rails.application.routes.draw do
  # Authentication
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get  "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  # Vault-scoped resources
  resources :vaults, only: [] do
    resources :folders, except: [ :show ]
    resources :audit_events, only: [ :index ]
  end

  # Secrets (top-level for cleaner URLs)
  resources :secrets do
    member do
      post :copy
    end
  end

  # Search
  get "search", to: "search#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "vaults#show"
end
