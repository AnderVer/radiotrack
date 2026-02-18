# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern JSON content types
  protect_from_forgery with: :exception

  # Devise before action
  before_action :authenticate_user!, unless: -> { request.path.start_with?("/api/") }

  # Permit all origins in development
  if Rails.env.development?
    after_action :allow_iframe
  end

  private

  def allow_iframe
    response.headers.delete("X-Frame-Options")
  end

  # Guest user class for unauthenticated requests
  class GuestUser
    def guest?
      true
    end

    def authenticated?
      false
    end

    def paid?
      false
    end

    def plan_code
      "guest"
    end

    def trial_tune_in_remaining
      User::TRIAL_TUNE_IN_LIMIT
    end

    def can_tune_in?
      true
    end

    def bookmarks_limit
      User::GUEST_BOOKMARKS_LIMIT
    end

    def playlists_limit
      User::GUEST_PLAYLISTS_LIMIT
    end

    def playlist_items_per_playlist_limit
      User::GUEST_PLAYLIST_ITEMS_LIMIT
    end

    def can_access_last_track?
      false
    end

    def can_access_playlist?
      false
    end

    def can_access_forecast?
      false
    end

    def can_capture_now_playing?
      false
    end
  end
end
