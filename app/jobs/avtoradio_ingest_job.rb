# frozen_string_literal: true

# Job for ingesting Avtoradio playlist detections
# Runs every 1-2 minutes via Solid Queue recurring schedule
#
# Usage:
#   AvtoradioIngestJob.perform_now
#   AvtoradioIngestJob.perform_later
class AvtoradioIngestJob < ApplicationJob
  queue_as :default

  # Retry configuration
  retry_on AvtoradioPlaylistParser::FetchError, wait: :polynomially_longer, attempts: 3
  retry_on AvtoradioPlaylistParser::ParseError, wait: 5.minutes, attempts: 2

  # Unique job configuration (prevent concurrent runs)
  # Note: Requires solid_queue with unique constraint

  def perform
    logger.info "[AvtoradioIngest] Starting ingest job"

    # Find or create Avtoradio station
    station = Station.find_or_create_by!(code: "avtoradio") do |s|
      s.title = "Авторадио"
      s.player_url = "https://www.avtoradio.ru/"
      s.playlist_url = "https://www.avtoradio.ru/playlist"
      s.federal = true
      s.active = true
    end

    logger.info "[AvtoradioIngest] Station: #{station.title} (ID: #{station.id})"

    # Fetch and parse playlist
    parser = AvtoradioPlaylistParser.new
    tracks = parser.fetch_and_parse

    logger.info "[AvtoradioIngest] Parsed #{tracks.count} tracks from playlist"

    # Save detections with idempotency
    created_count = 0
    skipped_count = 0

    tracks.each do |track|
      result = save_detection(station, track)
      if result[:created]
        created_count += 1
      else
        skipped_count += 1
      end
    end

    logger.info "[AvtoradioIngest] Completed: #{created_count} created, #{skipped_count} skipped"

    {
      station_id: station.id,
      tracks_parsed: tracks.count,
      tracks_created: created_count,
      tracks_skipped: skipped_count
    }
  end

  private

  def save_detection(station, track)
    # Idempotency check: find existing detection
    existing = Detection.find_by(
      station_id: station.id,
      played_at: track[:played_at],
      artist_title_normalized: normalize_track_key(track[:artist], track[:title])
    )

    if existing
      logger.debug "[AvtoradioIngest] Skipping duplicate: #{track[:artist]} - #{track[:title]} at #{track[:played_at]}"
      return { created: false, detection: existing }
    end

    # Create new detection
    detection = Detection.create!(
      station: station,
      artist: track[:artist] || "Unknown",
      title: track[:title] || "Unknown",
      played_at: track[:played_at],
      artist_title_normalized: normalize_track_key(track[:artist], track[:title]),
      confidence: 0.8,
      source: track[:source] || "avtoradio_playlist"
    )

    logger.debug "[AvtoradioIngest] Created detection: #{detection.artist} - #{detection.title}"
    { created: true, detection: detection }
  end

  def normalize_track_key(artist, title)
    a = artist.to_s.downcase.strip
    t = title.to_s.downcase.strip
    "#{a}-#{t}"
  end
end
