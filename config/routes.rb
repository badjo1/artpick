Rails.application.routes.draw do
  # Authentication (existing)
  resource :session
  resources :passwords, param: :token

  # Public voting flow
  root "voting#index"
  get "vote", to: "voting#index"
  post "vote", to: "voting#vote"

  # Favorites selection
  get "favorites", to: "favorites#index"
  post "favorites", to: "favorites#create"

  # Results page
  get "results", to: "results#index"

  # Invite links
  get "invite/:token", to: "invites#show", as: :invite

  # Share & Email invites
  post "share_email", to: "share#email"

  # Admin namespace
  namespace :admin do
    root "dashboard#index"

    resources :images do
      collection do
        get :bulk_new
        post :bulk_create
      end
    end
    resources :invite_links, only: [:index, :create, :destroy]
    resource :settings, only: [:edit, :update]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
