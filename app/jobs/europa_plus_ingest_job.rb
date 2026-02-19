# frozen_string_literal: true

# Job to ingest playlist from Europa Plus
#
# Fetches playlist from Europa Plus API, parses it, and creates Detection records.
# Idempotent: skips existing records (app-level dedup).
#
# Usage:
#   EuropaPlusIngestJob.perform_now
#
#   # or async
#   EuropaPlusIngestJob.perform_later
class EuropaPlusIngestJob < ApplicationJob
  queue_as :default

  # Retry configuration
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Station code for Europa Plus
  STATION_CODE = "europe_plus"

  # Source identifier
  SOURCE = "europaplus_api"

  def perform
    logger.info "[EuropaPlusIngest] Starting playlist ingest"

    # Find Europa Plus station
    station = Station.find_by(code: STATION_CODE)
    unless station
      logger.error "[EuropaPlusIngest] Station '#{STATION_CODE}' not found"
      raise "Station '#{STATION_CODE}' not found. Please run: bin/rails db:seed"
    end

    logger.info "[EuropaPlusIngest] Found station: #{station.title} (ID: #{station.id})"

    # Parse playlist
    parser = EuropaPlusPlaylistParser.new
    tracks = parser.fetch_and_parse

    logger.info "[EuropaPlusIngest] Parsed #{tracks.size} tracks"

    # Process tracks
    created_count = 0
    skipped_count = 0

    tracks.each do |track|
      begin
        if create_detection(station, track)
          created_count += 1
        else
          skipped_count += 1
        end
      rescue ActiveRecord::RecordNotUnique => e
        # Unique index violation (DB-level dedup)
        logger.info "[EuropaPlusIngest] Duplicate detected (DB level): #{track[:artist]} - #{track[:title]} at #{track[:played_at]}"
        skipped_count += 1
      rescue => e
        logger.error "[EuropaPlusIngest] Error creating detection: #{e.message}"
        logger.error "[EuropaPlusIngest] Backtrace: #{e.backtrace.first(3)}"
      end
    end

    logger.info "[EuropaPlusIngest] Completed: #{created_count} created, #{skipped_count} skipped"

    {
      created: created_count,
      skipped: skipped_count,
      total: tracks.size
    }
  end

  private

  # Create Detection record (with app-level dedup)
  # @param station [Station] Station record
  # @param track [Hash] Track data from parser
  # @return [Boolean] True if created, false if skipped
  def create_detection(station, track)
    # Normalize track key for deduplication
    key = normalize_track_key(track[:artist], track[:title])

    # Check for existing record (app-level dedup)
    existing = Detection.find_by(
      station_id: station.id,
      played_at: track[:played_at],
      artist_title_normalized: key
    )

    if existing
      logger.info "[EuropaPlusIngest] Skipping duplicate: #{track[:artist]} - #{track[:title]} at #{track[:played_at].utc}"
      return false
    end

    # Create new detection
    Detection.create!(
      station_id: station.id,
      artist: track[:artist],
      title: track[:title],
      played_at: track[:played_at],
      artist_title_normalized: key,
      source: SOURCE,
      confidence: track[:confidence] || 0.8
    )

    logger.info "[EuropaPlusIngest] Created detection: #{track[:artist]} - #{track[:title]} at #{track[:played_at].utc}"
    true
  end

  # Normalize track key for deduplication
  # @param artist [String] Artist name
  # @param title [String] Track title
  # @return [String] Normalized key
  def normalize_track_key(artist, title)
    a = artist.to_s.downcase.strip
    t = title.to_s.downcase.strip
    "#{a}-#{t}"
  end
end
