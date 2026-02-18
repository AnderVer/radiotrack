# frozen_string_literal: true

module Api
  class SubscriptionController < BaseController
    # GET /api/user/subscription_status
    def show
      render json: {
        plan_code: current_user_or_guest.plan_code,
        paid: current_user_or_guest.paid?,
        paid_until: current_user.paid_until,
        trial_tune_in_remaining: current_user_or_guest.trial_tune_in_remaining,
        limits: {
          bookmarks: current_user_or_guest.bookmarks_limit,
          playlists: current_user_or_guest.playlists_limit,
          playlist_items: current_user_or_guest.playlist_items_per_playlist_limit
        },
        features: {
          last_track: current_user_or_guest.can_access_last_track?,
          playlist: current_user_or_guest.can_access_playlist?,
          forecast: current_user_or_guest.can_access_forecast?,
          capture_now_playing: current_user_or_guest.can_capture_now_playing?,
          tune_in: current_user_or_guest.can_tune_in?
        }
      }
    end
  end
end
