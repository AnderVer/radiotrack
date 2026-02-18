# frozen_string_literal: true

require "nokogiri"
require "open-uri"

# Service for parsing Avtoradio playlist page
# URL: https://www.avtoradio.ru/playlist
#
# HTML structure:
#   <ul class="what-list mb20">
#     <li class="fl pr">
#       <span class="time fl">11:38</span>
#       <div class="what-name fl">
#         <b>Artist</b><br>
#         Title
#       </div>
#     </li>
#   </ul>
#
# Date from header:
#   <h1 class="mb40">Что за песня звучала 18 февраля 2026 в 11:38?</h1>
class AvtoradioPlaylistParser
  BASE_URL = "https://www.avtoradio.ru"
  PLAYLIST_URL = "#{BASE_URL}/playlist"

  # Russian month names mapping
  MONTHS = {
    "января" => 1, "февраля" => 2, "марта" => 3, "апреля" => 4,
    "мая" => 5, "июня" => 6, "июля" => 7, "августа" => 8,
    "сентября" => 9, "октября" => 10, "ноября" => 11, "декабря" => 12
  }.freeze

  # Regex for date extraction from header
  DATE_REGEX = /Что за песня звучала\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+в\s+(\d{2}):(\d{2})/

  # CSS selectors
  SELECTORS = {
    playlist_list: "ul.what-list",
    track_item: "li.fl.pr",
    track_time: "span.time.fl",
    track_name_block: "div.what-name.fl",
    track_artist: "b",
    track_title_text: :text_after_br
  }.freeze

  class ParseError < StandardError; end
  class FetchError < StandardError; end

  # Main entry point
  # @param html [String] HTML content to parse
  # @return [Array<Hash>] Array of parsed tracks
  def self.parse(html:)
    new.parse(html: html)
  end

  # Fetch and parse playlist from URL
  # @param url [String] Override default URL
  # @return [Array<Hash>] Array of parsed tracks
  def self.fetch_and_parse(url: nil)
    new.fetch_and_parse(url: url)
  end

  def initialize
    @logger = Rails.logger
  end

  def parse(html:)
    return [] if html.blank?

    doc = Nokogiri::HTML(html)

    # Try to extract date from header first
    playlist_date = extract_date_from_header(doc)
    playlist_date ||= Date.current.in_time_zone("Europe/Moscow")

    @logger.info "[AvtoradioParser] Playlist date: #{playlist_date}"

    # Find playlist list
    playlist_list = doc.css(SELECTORS[:playlist_list]).first
    unless playlist_list
      @logger.warn "[AvtoradioParser] Playlist list not found"
      return []
    end

    # Parse each track
    tracks = []
    playlist_list.css(SELECTORS[:track_item]).each do |item|
      track = parse_track_item(item, playlist_date)
      tracks << track if track
    end

    @logger.info "[AvtoradioParser] Parsed #{tracks.count} tracks"
    tracks
  rescue => e
    @logger.error "[AvtoradioParser] Parse error: #{e.message}"
    raise ParseError, "Failed to parse HTML: #{e.message}"
  end

  def fetch_and_parse(url: nil)
    fetch_url = url || PLAYLIST_URL

    @logger.info "[AvtoradioParser] Fetching #{fetch_url}"

    begin
      uri = URI.parse(fetch_url)
      html = uri.open(
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
      ).read

      parse(html: html)
    rescue OpenURI::HTTPError => e
      @logger.error "[AvtoradioParser] Fetch error: #{e.message}"
      raise FetchError, "Failed to fetch playlist: #{e.message}"
    rescue => e
      @logger.error "[AvtoradioParser] Unexpected error: #{e.message}"
      raise FetchError, "Unexpected error: #{e.message}"
    end
  end

  private

  def parse_track_item(item, playlist_date)
    time_str = item.css(SELECTORS[:track_time]).text.strip
    return unless time_str.present? && looks_like_time?(time_str)

    name_block = item.css(SELECTORS[:track_name_block]).first
    return unless name_block

    artist = name_block.css(SELECTORS[:track_artist]).text.strip
    title = extract_title_from_text_node(name_block)

    return if artist.blank? && title.blank?

    # Convert MSK time to UTC
    played_at = msk_time_to_utc(playlist_date, time_str)

    {
      artist: artist.presence,
      title: title.presence,
      played_at: played_at,
      source: "avtoradio_playlist"
    }
  end

  def extract_title_from_text_node(name_block)
    # Get the text node after <br>
    br = name_block.css("br").first
    return "" unless br

    # Get the next sibling text node
    br.next&.to_s&.strip || ""
  end

  def extract_date_from_header(doc)
    # Look for header like "Что за песня звучала 18 февраля 2026 в 11:38?"
    header = doc.css("h1").find { |h| h.text.include?("Что за песня звучала") }
    return unless header

    match = header.text.match(DATE_REGEX)
    return unless match

    day = match[1].to_i
    month_name = match[2].downcase
    year = match[3].to_i

    month = MONTHS[month_name]
    return unless month

    Date.new(year, month, day)
  rescue => e
    @logger.warn "[AvtoradioParser] Failed to extract date from header: #{e.message}"
    nil
  end

  def looks_like_time?(str)
    str.match?(/^\d{2}:\d{2}$/)
  end

  def msk_time_to_utc(date, time_str)
    # Create MSK time from date and time string
    hour, minute = time_str.split(":").map(&:to_i)

    msk_time = Time.zone.parse("#{date.strftime('%Y-%m-%d')} #{hour}:#{minute}:00")

    # Convert MSK to UTC (MSK = UTC + 3)
    # ActiveSupport::TimeZone handles DST automatically
    msk_time.utc
  end
end
