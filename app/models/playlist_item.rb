# frozen_string_literal: true

class PlaylistItem < ApplicationRecord
  belongs_to :playlist
  belongs_to :captured_station, class_name: "Station", optional: true
  belongs_to :resolved_detection, class_name: "Detection", optional: true

  validates :status, inclusion: { in: %w[resolved pending unresolved] }
  validates :position, presence: true, numericality: { only_integer: true }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :resolved, -> { where(status: "resolved") }
  scope :unresolved, -> { where(status: "unresolved") }
  scope :ordered, -> { order(position: :asc) }

  # Resolve pending item
  def resolve!
    return unless pending? && captured_station && captured_at

    # Find matching detection within time window (±90 seconds)
    detection = Detection
      .where(station: captured_station)
      .where("played_at BETWEEN ? AND ?", captured_at - 90.seconds, captured_at + 90.seconds)
      .order("ABS(EXTRACT(EPOCH FROM (played_at - ?)))", captured_at)
      .first

    if detection
      update!(
        status: "resolved",
        track_artist: detection.artist,
        track_title: detection.title,
        resolved_detection: detection,
        resolved_at: Time.current
      )
    else
      update!(
        status: "unresolved",
        unresolved_reason: "No matching detection found"
      )
    end
  end

  def pending?
    status == "pending"
  end

  def resolved?
    status == "resolved"
  end

  def unresolved?
    status == "unresolved"
  end

  def display_artist
    track_artist || "Определяем..."
  end

  def display_title
    track_title || "Определяем..."
  end
end
