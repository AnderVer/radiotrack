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

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:vk, :yandex, :telegram]

  # Associations
  has_many :identities, dependent: :destroy
  has_many :station_bookmarks, dependent: :destroy
  has_many :bookmarked_stations, through: :station_bookmarks, source: :station
  has_many :playlists, dependent: :destroy
  has_many :tune_in_attempts, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Scopes
  scope :active_paid, -> { where("paid_until > ?", Time.current) }
  scope :expired_paid, -> { where("paid_until <= ?", Time.current) }

  # Methods
  def plan_code
    return PLAN_PAID if paid?
    return PLAN_AUTH if authenticated?
    PLAN_GUEST
  end

  def paid?
    paid_until&.future?
  end

  def authenticated?
    identities.any? || email.present?
  end

  def guest?
    !authenticated?
  end

  def trial_tune_in_remaining
    return nil if paid?
    attempts_today = tune_in_attempts.where("created_at >= ?", Time.current.beginning_of_day).count
    [TRIAL_TUNE_IN_LIMIT - attempts_today, 0].max
  end

  def can_tune_in?
    return true if paid?
    (trial_tune_in_remaining || 0) > 0
  end

  def bookmarks_limit
    case plan_code
    when PLAN_PAID then nil
    when PLAN_AUTH then nil
    else GUEST_BOOKMARKS_LIMIT
    end
  end

  def playlists_limit
    case plan_code
    when PLAN_PAID then PAID_PLAYLISTS_LIMIT
    when PLAN_AUTH then AUTH_PLAYLISTS_LIMIT
    else GUEST_PLAYLISTS_LIMIT
    end
  end

  def playlist_items_per_playlist_limit
    case plan_code
    when PLAN_PAID then PAID_PLAYLIST_ITEMS_LIMIT
    when PLAN_AUTH then AUTH_PLAYLIST_ITEMS_LIMIT
    else GUEST_PLAYLIST_ITEMS_LIMIT
    end
  end

  def can_access_last_track?
    paid?
  end

  def can_access_playlist?
    paid?
  end

  def can_access_forecast?
    paid?
  end

  def can_capture_now_playing?
    paid?
  end
end
