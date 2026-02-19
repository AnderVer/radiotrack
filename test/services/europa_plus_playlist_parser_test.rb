# frozen_string_literal: true

require "test_helper"
require_relative "../../app/services/europa_plus_playlist_parser"

class EuropaPlusPlaylistParserTest < ActiveSupport::TestCase
  def setup
    @parser = EuropaPlusPlaylistParser.new
    @fixture_path = Rails.root.join("test/fixtures/files/europa_plus_playlist.json")
    @json_data = JSON.parse(File.read(@fixture_path))
  end

  test "parse json response with tracks" do
    tracks = @parser.parse(json: @json_data)

    assert_equal 4, tracks.size

    # First track
    assert_equal "The Weeknd", tracks[0][:artist]
    assert_equal "Blinding Lights", tracks[0][:title]
    assert_equal "europaplus_api", tracks[0][:source]
    assert_equal 0.85, tracks[0][:confidence]
    assert tracks[0][:played_at].is_a?(Time)
  end

  test "parse returns empty array for empty tracks" do
    tracks = @parser.parse(json: { "tracks" => [] })
    assert_empty tracks
  end

  test "parse handles missing tracks key" do
    tracks = @parser.parse(json: { "data" => [] })
    assert_empty tracks
  end

  test "parse handles different JSON structures" do
    # Test with "items" key
    json = {
      "items" => [
        { "artist" => "Artist1", "title" => "Title1", "played_at" => "2026-02-19T12:00:00Z" }
      ]
    }
    tracks = @parser.parse(json: json)
    assert_equal 1, tracks.size
    assert_equal "Artist1", tracks[0][:artist]
  end

  test "parse skips tracks with missing artist" do
    json = {
      "tracks" => [
        { "title" => "Title1", "played_at" => "2026-02-19T12:00:00Z" },
        { "artist" => "Artist1", "title" => "Title1", "played_at" => "2026-02-19T12:00:00Z" }
      ]
    }
    tracks = @parser.parse(json: json)
    assert_equal 1, tracks.size
  end

  test "parse skips tracks with missing title" do
    json = {
      "tracks" => [
        { "artist" => "Artist1", "played_at" => "2026-02-19T12:00:00Z" },
        { "artist" => "Artist2", "title" => "Title2", "played_at" => "2026-02-19T12:00:00Z" }
      ]
    }
    tracks = @parser.parse(json: json)
    assert_equal 1, tracks.size
  end

  test "parse handles unix timestamp" do
    timestamp = 1_708_347_400 # 2026-02-19T12:30:00Z
    json = {
      "tracks" => [
        { "artist" => "Artist", "title" => "Title", "played_at" => timestamp }
      ]
    }
    tracks = @parser.parse(json: json)
    assert_equal 1, tracks.size
    assert_equal Time.at(timestamp).utc, tracks[0][:played_at]
  end

  test "parse handles unix timestamp as string" do
    timestamp_str = "1708347400"
    json = {
      "tracks" => [
        { "artist" => "Artist", "title" => "Title", "played_at" => timestamp_str }
      ]
    }
    tracks = @parser.parse(json: json)
    assert_equal 1, tracks.size
  end

  test "parse handles ISO 8601 timestamp" do
    iso_string = "2026-02-19T12:30:00Z"
    json = {
      "tracks" => [
        { "artist" => "Artist", "title" => "Title", "played_at" => iso_string }
      ]
    }
    tracks = @parser.parse(json: json)
    assert_equal 1, tracks.size
    assert tracks[0][:played_at].is_a?(Time)
  end

  test "parse raises ParseError for invalid JSON structure" do
    assert_raises EuropaPlusPlaylistParser::ParseError do
      @parser.parse(json: { "invalid" => "structure" })
    end
  end

  test "playlist_url returns correct API endpoint" do
    url = @parser.playlist_url
    assert_equal "https://europaplus.ru/api/playlist", url
  end

  test "station_name returns correct name" do
    name = @parser.station_name
    assert_equal "EuropaPlus", name
  end

  test "normalize_track_key creates consistent key" do
    key1 = @parser.send(:normalize_track_key, "Artist", "Title")
    key2 = @parser.send(:normalize_track_key, "artist", "title")
    key3 = @parser.send(:normalize_track_key, "  ARTIST  ", "  TITLE  ")

    assert_equal "artist-title", key1
    assert_equal key1, key2
    assert_equal key1, key3
  end

  test "create_track_hash creates correct structure" do
    track = @parser.send(
      :create_track_hash,
      artist: "Artist",
      title: "Title",
      played_at: Time.now.utc,
      source: "test",
      confidence: 0.9
    )

    assert_equal "Artist", track[:artist]
    assert_equal "Title", track[:title]
    assert track[:played_at].is_a?(Time)
    assert_equal "test", track[:source]
    assert_equal 0.9, track[:confidence]
  end
end
