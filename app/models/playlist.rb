# frozen_string_literal: true

class Playlist < ApplicationRecord
  belongs_to :user
  has_many :playlist_items, dependent: :destroy
  has_many :items, -> { order(position: :asc) }, class_name: "PlaylistItem"

  validates :title, presence: true
  validates :user_id, uniqueness: { scope: :title }, unless: :local_id?
  validate :check_playlists_limit, on: :create

  before_save :ensure_position

  # Add track to playlist
  def add_track(artist:, title:, position: nil)
    max_position = playlist_items.maximum(:position) || 0
    playlist_items.create!(
      track_artist: artist,
      track_title: title,
      position: position || (max_position + 1),
      status: "resolved"
    )
  end

  # Add pending track (capture now playing)
  def add_pending_track(captured_station_id:, captured_at: Time.current)
    max_position = playlist_items.maximum(:position) || 0
    playlist_items.create!(
      captured_station_id: captured_station_id,
      captured_at: captured_at,
      position: max_position + 1,
      status: "pending"
    )
  end

  private

  def check_playlists_limit
    limit = user.playlists_limit
    return unless limit
    return if user.playlists.count < limit

    errors.add(:base, "Playlists limit reached for #{user.plan_code} plan")
  end

  def ensure_position
    self.position ||= (playlist_items.maximum(:position) || 0) + 1
  end
end
