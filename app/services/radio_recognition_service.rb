# frozen_string_literal: true

# Service for radio stream recognition using external APIs
# Supports AudD.io and ACRCloud for MVP
class RadioRecognitionService
  class << self
    # Register station for monitoring
    def register_station(station)
      case recognition_provider
      when "audd"
        register_audd_stream(station)
      when "acrcloud"
        register_acrcloud_stream(station)
      else
        Rails.logger.warn "No recognition provider configured"
        false
      end
    end

    # Get recognition results via webhook/callback
    def process_callback(payload)
      # Parse callback from recognition service
      # Create/update Detection records
      case recognition_provider
      when "audd"
        process_audd_callback(payload)
      when "acrcloud"
        process_acrcloud_callback(payload)
      end
    end

    # Manual recognition (fallback)
    def recognize_chunk(audio_chunk, station_id)
      # Send audio chunk to recognition service
      # Return detection result
      nil
    end

    private

    def recognition_provider
      ENV.fetch("RECOGNITION_PROVIDER", nil)
    end

    def register_audd_stream(station)
      return false unless station.stream_url.present?

      response = HTTParty.post(
        "https://api.audd.io/streams/",
        headers: { "X-AUDD-API-Token" => ENV["AUDD_API_TOKEN"] },
        body: {
          url: station.stream_url,
          callback_url: callback_url,
          return_callback_id: "1",
          extended_metadata: "1"
        }
      )

      if response.success?
        station.update(recognition_id: response.parsed_response["id"])
        true
      else
        Rails.logger.error "AudD registration failed: #{response.body}"
        false
      end
    end

    def register_acrcloud_stream(station)
      # ACRCloud uses different API structure
      # Implementation depends on their Broadcast Monitoring API
      Rails.logger.info "ACRCloud registration not yet implemented"
      false
    end

    def process_audd_callback(payload)
      # AudD sends: id, timestamp, artist, title, label, release_date, etc.
      station = Station.find_by(recognition_id: payload["id"])
      return unless station

      Detection.create!(
        station: station,
        artist: payload["artist"] || "Unknown",
        title: payload["title"] || "Unknown",
        played_at: Time.parse(payload["timestamp"] || Time.current.to_s),
        confidence: 1.0,
        source: "audd",
        artist_title_normalized: "#{payload["artist"]&.downcase}-#{payload["title"]&.downcase}"
      )
    end

    def process_acrcloud_callback(payload)
      # ACRCloud callback format
      Rails.logger.info "Processing ACRCloud callback"
    end

    def callback_url
      ENV.fetch("RECOGNITION_CALLBACK_URL", "#{Rails.application.routes.url_helpers.root_url}api/recognition/callback")
    end
  end
end
