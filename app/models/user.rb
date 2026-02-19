# frozen_string_literal: true

class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:vk, :yandex, :telegram]

  # Subscription management
  has_many :identities, dependent: :destroy
  has_many :station_bookmarks, dependent: :destroy
  has_many :bookmarked_stations, through: :station_bookmarks, source: :station
  has_many :playlists, dependent: :destroy
  has_many :tune_in_attempts, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, if: :email?

  # Scopes
  scope :active_paid, -> { where("paid_until > ?", Time.current) }
  scope :expired_paid, -> { where("paid_until <= ?", Time.current) }

  # Check if user has active subscription
  def paid?
    paid_until&.future?
  end

  # Get plan code
  def plan_code
    return PLAN_PAID if paid?
    return PLAN_AUTH if authenticated?
    PLAN_GUEST
  end

  # Check if user is authenticated (has email or identities)
  def authenticated?
    email.present? || identities.any?
  end

  def guest?
    !authenticated?
  end

  # Trial attempts remaining for "Where plays" feature
  def trial_tune_in_remaining
    return nil if paid?
    attempts_today = tune_in_attempts.where("created_at >= ?", Time.current.beginning_of_day).count
    [TRIAL_TUNE_IN_LIMIT - attempts_today, 0].max
  end

  def can_tune_in?
    return true if paid?
    (trial_tune_in_remaining || 0) > 0
  end

  def record_tune_in!
    tune_in_attempts.create!
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
