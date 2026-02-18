# frozen_string_literal: true

class Station < ApplicationRecord
  has_many :detections, dependent: :destroy
  has_many :station_bookmarks, dependent: :destroy
  has_many :bookmarked_by_users, through: :station_bookmarks, source: :user

  # Current playing track (optional real-time tracking)
  belongs_to :now_playing_track, class_name: "Detection", optional: true

  validates :code, :title, :player_url, presence: true
  validates :code, uniqueness: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :federal, -> { where(federal: true) }
  scope :for_contests, -> { where(contest_enabled: true) }

  # Get last played track
  def last_track
    detections.order(played_at: :desc).first
  end

  # Get playlist for time range (e.g., "30m", "1h")
  def playlist(range: "30m")
    duration = parse_duration(range)
    detections.where("played_at >= ?", duration.ago).order(played_at: :desc)
  end

  # Find stations where track is playing now
  def self.where_track_playing_now(artist:, title:)
    joins(:now_playing_track)
      .where(detections: { artist: artist, title: title })
  end

  private

  def parse_duration(duration_str)
    value, unit = duration_str.match(/(\d+)([mhd])/)&.captures
    return 30.minutes unless value

    value = value.to_i
    case unit
    when "m" then value.minutes
    when "h" then value.hours
    when "d" then value.days
    else 30.minutes
    end
  end
end
