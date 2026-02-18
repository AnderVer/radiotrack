# frozen_string_literal: true

class Detection < ApplicationRecord
  belongs_to :station
  has_many :playlist_items, foreign_key: "resolved_detection_id", dependent: :nullify
  has_many :stations_as_now_playing, class_name: "Station", foreign_key: "now_playing_track_id", dependent: :nullify

  validates :artist, :title, :played_at, presence: true

  # Normalized artist-title for matching
  before_save :normalize_artist_title

  # Scopes
  scope :recent, -> { order(played_at: :desc) }
  scope :for_window, ->(window) { where("played_at >= ?", window.ago) }

  # Find detections matching artist/title in time window
  scope :matching, ->(artist, title, window: 2.minutes) do
    normalized = normalize_for_search(artist, title)
    where("artist_title_normalized = ?", normalized)
      .where("played_at >= ?", window.ago)
  end

  class << self
    def normalize_for_search(artist, title)
      "#{artist.to_s.downcase.strip}-#{title.to_s.downcase.strip}"
    end
  end

  private

  def normalize_artist_title
    self.artist_title_normalized = "#{artist.to_s.downcase.strip}-#{title.to_s.downcase.strip}"
  end
end
