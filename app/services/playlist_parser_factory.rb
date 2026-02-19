# frozen_string_literal: true

# Factory for playlist parsers
#
# Usage:
#   parser = PlaylistParserFactory.for_station("avtoradio")
#   tracks = parser.fetch_and_parse
#
#   parser = PlaylistParserFactory.for_station("europe_plus")
#   tracks = parser.fetch_and_parse
class PlaylistParserFactory
  # Map station codes to parser classes
  PARSER_MAP = {
    "avtoradio" => AvtoradioPlaylistParser,
    "europe_plus" => EuropaPlusPlaylistParser
  }.freeze

  # Get parser instance for station
  # @param station_code [String] Station code (e.g., "avtoradio")
  # @return [BasePlaylistParser] Parser instance
  # @raise [ArgumentError] If parser not available
  def self.for_station(station_code)
    parser_class = PARSER_MAP[station_code.to_s]

    unless parser_class
      available = PARSER_MAP.keys.join(", ")
      raise ArgumentError, "Parser not available for '#{station_code}'. Available: #{available}"
    end

    parser_class.new
  end

  # Check if parser exists for station
  # @param station_code [String] Station code
  # @return [Boolean] True if parser exists
  def self.parser_exists?(station_code)
    PARSER_MAP.key?(station_code.to_s)
  end

  # Get list of supported station codes
  # @return [Array<String>] Station codes
  def self.supported_stations
    PARSER_MAP.keys
  end
end
