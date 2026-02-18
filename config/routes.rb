Rails.application.routes.draw do
  # Root path
  root "pages#home"

  # Devise routes for User model
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # API routes
  namespace :api do
    # Recognition callback (external service → our app)
    post "recognition/callback", to: "recognition#callback"

    # Stations
    get "stations", to: "stations#index"
    get "stations/:id", to: "stations#show"
    get "stations/:id/last_track", to: "stations#last_track"
    get "stations/:id/playlist", to: "stations#playlist"
    post "stations/:id/capture_now_playing", to: "stations#capture_now_playing"

    # Tracks
    get "tracks/:id/where_now", to: "tracks#where_now"
    get "tracks/:id/where_soon", to: "tracks#where_soon"

    # User data
    get "user/bookmarks", to: "bookmarks#index"
    post "user/bookmarks", to: "bookmarks#create"
    delete "user/bookmarks/:station_id", to: "bookmarks#destroy"

    get "user/subscription_status", to: "subscription#show"

    # Playlists
    resources :playlists, except: [:new, :edit] do
      resources :items, controller: "playlist_items", except: [:new, :edit]
    end

    # Import guest data
    post "import_local_data", to: "import#import_local_data"
  end

  # Telegram webhook
  post "telegram/webhook", to: "telegram/webhook#receive"
end
