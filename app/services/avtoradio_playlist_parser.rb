# frozen_string_literal: true

# Parser for Avtoradio playlist page
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
class AvtoradioPlaylistParser < BasePlaylistParser
  BASE_URL = "https://www.avtoradio.ru"
  PLAYLIST_URL = "#{BASE_URL}/playlist"

  # CSS selectors
  SELECTORS = {
    playlist_list: "ul.what-list",
    track_item: "li.fl.pr",
    track_time: "span.time.fl",
    track_name_block: "div.what-name.fl",
    track_artist: "b",
    track_title_text: :text_after_br
  }.freeze

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

  def playlist_url
    PLAYLIST_URL
  end

  def parse(html:)
    return [] if html.blank?

    doc = Nokogiri::HTML(html)

    # Try to extract date from header first
    header = doc.css("h1").find { |h| h.text.include?("Что за песня звучала") }
    playlist_date = header ? extract_date_from_russian_header(header.text) : nil
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

    create_track_hash(
      artist: artist,
      title: title,
      played_at: played_at,
      source: "avtoradio_playlist"
    )
  end

  def extract_title_from_text_node(name_block)
    # Get the text node after <br>
    br = name_block.css("br").first
    return "" unless br

    # Get the next sibling text node
    br.next&.to_s&.strip || ""
  end

  def looks_like_time?(str)
    str.match?(/^\d{2}:\d{2}$/)
  end
end
