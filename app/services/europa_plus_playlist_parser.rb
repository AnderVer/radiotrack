# frozen_string_literal: true

require "nokogiri"
require "open-uri"
require "net/http"
require "json"

# Europa Plus playlist parser
#
# API endpoint: https://europaplus.ru/api/playlist
# Returns JSON with track history
#
# Usage:
#   parser = EuropaPlusPlaylistParser.new
#   tracks = parser.fetch_and_parse
#
# Response format (expected):
#   {
#     "tracks": [
#       {
#         "artist": "Artist Name",
#         "title": "Track Title",
#         "played_at": "2026-02-19T15:30:00Z" or timestamp,
#         "duration": 180
#       }
#     ]
#   }
class EuropaPlusPlaylistParser < BasePlaylistParser
  # Base URL for Europa Plus API
  API_BASE_URL = "https://europaplus.ru/api"

  # Playlist endpoint
  PLAYLIST_ENDPOINT = "/playlist"

  # Max tracks to fetch (last 30 minutes)
  MAX_TRACKS = 30

  # Parse playlist from JSON API
  # @return [Array<Hash>] Array of track hashes
  def parse(html: nil, json: nil)
    begin
      # If HTML is provided, try to extract JSON from it
      if html
        parse_from_html(html)
      elsif json
        parse_json_response(json)
      else
        logger.error "[#{station_name}] No data provided for parsing"
        []
      end
    rescue => e
      logger.error "[#{station_name}] Parse error: #{e.message}"
      logger.error "[#{station_name}] Backtrace: #{e.backtrace.first(5)}"
      raise ParseError, "Failed to parse playlist: #{e.message}"
    end
  end

  # Fetch and parse JSON from API
  # @return [Array<Hash>] Array of track hashes
  def fetch_and_parse(url: nil)
    api_url = url || playlist_url

    logger.info "[#{station_name}] Fetching #{api_url}"

    begin
      uri = URI.parse(api_url)
      
      # Use Net::HTTP for JSON API
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = user_agent_headers["User-Agent"]
      request["Accept"] = "application/json"
      
      response = http.request(request)
      
      if response.code == "200"
        json_data = JSON.parse(response.body)
        parse_json_response(json_data)
      else
        logger.error "[#{station_name}] API error: #{response.code} - #{response.message}"
        raise FetchError, "API returned #{response.code}: #{response.message}"
      end
    rescue JSON::ParserError => e
      logger.error "[#{station_name}] JSON parse error: #{e.message}"
      raise ParseError, "Invalid JSON response: #{e.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      logger.error "[#{station_name}] Timeout: #{e.message}"
      raise FetchError, "Timeout fetching playlist: #{e.message}"
    rescue => e
      logger.error "[#{station_name}] Unexpected error: #{e.message}"
      raise FetchError, "Unexpected error: #{e.message}"
    end
  end

  # Default playlist URL (API endpoint)
  def playlist_url
    "#{API_BASE_URL}#{PLAYLIST_ENDPOINT}"
  end

  private

  # Parse JSON response from API
  # @param json_data [Hash] Parsed JSON data
  # @return [Array<Hash>] Array of track hashes
  def parse_json_response(json_data)
    tracks = []

    # Try different JSON structures
    track_list = extract_tracks_from_json(json_data)

    track_list.each do |track|
      begin
        parsed = parse_track_item(track)
        tracks << parsed if parsed
      rescue => e
        logger.warn "[#{station_name}] Failed to parse track: #{e.message}"
        next
      end
    end

    logger.info "[#{station_name}] Parsed #{tracks.size} tracks"
    tracks
  end

  # Extract tracks array from JSON (handles different structures)
  # @param json_data [Hash] Raw JSON data
  # @return [Array] Array of track items
  def extract_tracks_from_json(json_data)
    # Try common structures
    return json_data["tracks"] if json_data["tracks"].is_a?(Array)
    return json_data["items"] if json_data["items"].is_a?(Array)
    return json_data["data"] if json_data["data"].is_a?(Array)
    return json_data["playlist"] if json_data["playlist"].is_a?(Array)
    return json_data["result"] if json_data["result"].is_a?(Array)
    
    # If the root is an array, use it directly
    return json_data if json_data.is_a?(Array)
    
    logger.warn "[#{station_name}] Unknown JSON structure, returning empty array"
    []
  end

  # Parse individual track item from JSON
  # @param track [Hash] Track data from API
  # @return [Hash] Normalized track hash
  def parse_track_item(track)
    # Extract fields with fallbacks for different naming conventions
    artist = extract_field(track, %w[artist artist_name performer artistName])
    title = extract_field(track, %w[title track_name track trackName song])
    played_at_raw = extract_field(track, %w[played_at playedAt timestamp time played time_utc])
    duration = extract_field(track, %w[duration length])

    # Skip if essential fields are missing
    return nil if artist.blank? || title.blank?

    # Parse played_at to UTC time
    played_at = parse_played_at(played_at_raw)
    return nil unless played_at

    create_track_hash(
      artist: artist,
      title: title,
      played_at: played_at,
      source: "europaplus_api",
      confidence: 0.85
    )
  end

  # Extract field from hash with multiple possible keys
  # @param hash [Hash] Data hash
  # @param keys [Array<String>] Possible key names
  # @return [Object, nil] Field value or nil
  def extract_field(hash, keys)
    keys.each do |key|
      return hash[key] if hash.key?(key) && hash[key].present?
      return hash[key.to_sym] if hash.key?(key.to_sym) && hash[key.to_sym].present?
    end
    nil
  end

  # Parse played_at timestamp to UTC time
  # @param raw_value [String, Integer, nil] Raw timestamp value
  # @return [Time, nil] UTC time or nil
  def parse_played_at(raw_value)
    return nil unless raw_value.present?

    # Unix timestamp (integer)
    if raw_value.is_a?(Integer)
      return Time.at(raw_value).utc
    end

    # String timestamp
    case raw_value.to_s
    when /^\d{10}$/
      # Unix timestamp as string
      Time.at(raw_value.to_i).utc
    when /^\d{4}-\d{2}-\d{2}/
      # ISO 8601 format
      Time.parse(raw_value.to_s).utc
    else
      # Try generic parsing
      Time.parse(raw_value.to_s).utc
    end
  rescue => e
    logger.warn "[#{station_name}] Failed to parse timestamp #{raw_value}: #{e.message}"
    nil
  end

  # Fallback: parse from HTML if API returns HTML
  # @param html [String] HTML content
  # @return [Array<Hash>] Array of track hashes
  def parse_from_html(html)
    logger.warn "[#{station_name}] Received HTML instead of JSON, attempting HTML parse"
    
    doc = Nokogiri::HTML(html)
    tracks = []

    # Try to find playlist container (common selectors)
    playlist_containers = doc.css(".playlist-item, .track-item, .playlist li, [data-track]")

    playlist_containers.each do |container|
      begin
        artist = container.css(".artist, [data-artist]")&.text&.strip
        title = container.css(".title, [data-title]")&.text&.strip
        time_str = container.css(".time, .timestamp, [data-time]")&.text&.strip

        next if artist.blank? || title.blank?

        # Try to parse time
        played_at = if time_str.present?
                      parse_time_string(time_str)
                    else
                      Time.now.utc
                    end

        tracks << create_track_hash(
          artist: artist,
          title: title,
          played_at: played_at,
          source: "europaplus_html",
          confidence: 0.7
        )
      rescue => e
        logger.warn "[#{station_name}] Failed to parse HTML track: #{e.message}"
        next
      end
    end

    tracks
  end

  # Parse time string to UTC time
  # @param time_str [String] Time string (e.g., "15:30", "15:30 MSK")
  # @return [Time] UTC time
  def parse_time_string(time_str)
    # Extract time (HH:MM)
    if time_str =~ /(\d{2}):(\d{2})/
      hour = Regexp.last_match(1).to_i
      minute = Regexp.last_match(2).to_i
      
      # Assume current date in MSK timezone
      now_msk = Time.zone.now
      msk_time = Time.zone.local(now_msk.year, now_msk.month, now_msk.day, hour, minute)
      
      # Convert to UTC
      return msk_time.utc
    end

    Time.now.utc
  end
end
