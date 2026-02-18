# frozen_string_literal: true

require "nokogiri"
require "open-uri"

# Base class for all playlist parsers
#
# Usage:
#   class MyStationParser < BasePlaylistParser
#     def parse(html:)
#       # Implement parsing logic
#       # Return array of track hashes
#     end
#   end
class BasePlaylistParser
  class ParseError < StandardError; end
  class FetchError < StandardError; end

  attr_reader :logger

  def initialize
    @logger = Rails.logger
  end

  # Fetch HTML from URL and parse
  # @param url [String] Override default URL
  # @return [Array<Hash>] Array of parsed tracks
  def fetch_and_parse(url: nil)
    fetch_url = url || playlist_url

    logger.info "[#{station_name}] Fetching #{fetch_url}"

    begin
      uri = URI.parse(fetch_url)
      html = uri.open(headers: user_agent_headers).read
      parse(html: html)
    rescue OpenURI::HTTPError => e
      logger.error "[#{station_name}] Fetch error: #{e.message}"
      raise FetchError, "Failed to fetch playlist: #{e.message}"
    rescue => e
      logger.error "[#{station_name}] Unexpected error: #{e.message}"
      raise FetchError, "Unexpected error: #{e.message}"
    end
  end

  # Parse HTML content
  # @param html [String] HTML content to parse
  # @return [Array<Hash>] Array of parsed tracks
  def parse(html:)
    raise NotImplementedError, "Subclasses must implement parse(html:)"
  end

  # Station name for logging
  def station_name
    self.class.name.demodulize.gsub("Parser", "")
  end

  # Default playlist URL (override in subclass)
  def playlist_url
    raise NotImplementedError, "Subclasses must implement playlist_url"
  end

  # Convert MSK time to UTC
  # @param date [Date] Date in MSK timezone
  # @param time_str [String] Time string "HH:MM"
  # @return [Time] Time in UTC
  def msk_time_to_utc(date, time_str)
    hour, minute = time_str.split(":").map(&:to_i)

    msk_time = Time.zone.parse("#{date.strftime('%Y-%m-%d')} #{hour}:#{minute}:00")
    msk_time.utc
  end

  # Extract date from header text (Russian format)
  # @param text [String] Header text like "Что за песня звучала 18 февраля 2026 в 11:38?"
  # @return [Date, nil] Parsed date or nil
  def extract_date_from_russian_header(text)
    match = text.match(/(\d{1,2})\s+(\w+)\s+(\d{4})\s+в\s+(\d{2}):(\d{2})/)
    return unless match

    day = match[1].to_i
    month_name = match[2].downcase
    year = match[3].to_i

    month = RUSSIAN_MONTHS[month_name]
    return unless month

    Date.new(year, month, day)
  rescue => e
    logger.warn "[#{station_name}] Failed to parse date: #{e.message}"
    nil
  end

  # Russian month names mapping
  RUSSIAN_MONTHS = {
    "января" => 1, "февраля" => 2, "марта" => 3, "апреля" => 4,
    "мая" => 5, "июня" => 6, "июля" => 7, "августа" => 8,
    "сентября" => 9, "октября" => 10, "ноября" => 11, "декабря" => 12
  }.freeze

  # Default user agent headers
  def user_agent_headers
    {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
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

  # Create track hash with consistent structure
  # @param artist [String] Artist name
  # @param title [String] Track title
  # @param played_at [Time] Play time in UTC
  # @param source [String] Source identifier
  # @param confidence [Float] Confidence score (0.0-1.0)
  # @return [Hash] Track hash
  def create_track_hash(artist:, title:, played_at:, source:, confidence: 0.8)
    {
      artist: artist.presence,
      title: title.presence,
      played_at: played_at,
      source: source,
      confidence: confidence
    }
  end
end
