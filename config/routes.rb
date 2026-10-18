Rails.application.routes.draw do
  root "boards#index"

  resources :boards do
    resources :lists, only: %i[ create update destroy ] do
      resources :cards, only: :create
    end
    resources :members, only: %i[ create destroy ]
    resource :escalation, only: :create
  end

  resources :cards, only: %i[ show update destroy ] do
    member do
      patch :move
    end
    resources :checklist_items, only: %i[ create update destroy ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
