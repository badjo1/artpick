Rails.application.routes.draw do
  # Homepage: The Continuum intro
  root "home#index"

  # Exhibition browsing
  resources :exhibitions, only: [:index, :show], param: :slug do
    member do
      get :artworks      # Grid view of all artworks
      get :comparison    # Voting interface
      post :compare      # Submit comparison
      get :preferences   # Top 5 selection
      post :preferences  # Save top 5
      get :media         # Public media gallery (masonry grid)
    end

    resources :artworks, only: [:show]
  end

  # Detail pages
  resources :artists, only: [:index, :show]
  resources :spaces, only: [:index, :show]

  # Legacy routes (backward compatibility - redirect to current exhibition)
  get "vote", to: "voting#index"
  post "vote", to: "voting#vote"
  get "favorites", to: "favorites#index"
  post "favorites", to: "favorites#create"
  get "results", to: "results#index"

  # Authentication
  resource :session
  resources :passwords, param: :token

  # Invites
  get "invite/:token", to: "invites#show", as: :invite

  # Share & Email
  post "share_email", to: "share#email"

  # Admin namespace
  namespace :admin do
    root "dashboard#index"

    resources :exhibitions do
      resources :artworks do
        collection do
          get :bulk_new
          post :bulk_create
        end
      end

      resources :exhibition_media do
        collection do
          post :bulk_create
        end
      end
    end

    resources :artists
    resources :spaces do
      resources :screens
    end
    resources :invite_links, only: [:index, :create, :destroy]
    resources :settings

    get "analytics", to: "analytics#index"
    get "analytics/exhibition/:id", to: "analytics#exhibition", as: :exhibition_analytics

    resources :storage, only: [:index] do
      collection do
        post :upload
        post :create_folder
      end
    end
    delete "storage/*path", to: "storage#destroy", as: :storage_delete
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
