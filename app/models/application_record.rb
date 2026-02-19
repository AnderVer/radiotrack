# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Subscription plans
  PLAN_GUEST = "guest"
  PLAN_AUTH = "auth"
  PLAN_PAID = "paid"

  # Trial limits
  TRIAL_TUNE_IN_LIMIT = 3
  GUEST_BOOKMARKS_LIMIT = 3
  GUEST_PLAYLISTS_LIMIT = 3
  GUEST_PLAYLIST_ITEMS_LIMIT = 10
  AUTH_PLAYLISTS_LIMIT = 10
  AUTH_PLAYLIST_ITEMS_LIMIT = 50
  PAID_PLAYLISTS_LIMIT = 50
  PAID_PLAYLIST_ITEMS_LIMIT = 100
end
