# frozen_string_literal: true

class User < ApplicationRecord
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

  # Check if user has active subscription
  def paid?
    paid_until&.future?
  end

  # Get plan code
  def plan_code
    return "paid" if paid?
    return "auth" if authenticated?
    "guest"
  end

  # Check if user is authenticated (has email or identities)
  def authenticated?
    email.present? || identities.any?
  end

  # Trial attempts remaining for "Where plays" feature
  def trial_tune_in_remaining
    return nil if paid?
    attempts_today = tune_in_attempts.where("created_at >= ?", Time.current.beginning_of_day).count
    [User::TRIAL_TUNE_IN_LIMIT - attempts_today, 0].max
  end

  def can_tune_in?
    return true if paid?
    (trial_tune_in_remaining || 0) > 0
  end

  def record_tune_in!
    tune_in_attempts.create!
  end
end
