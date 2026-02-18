# frozen_string_literal: true

require "test_helper"

class DetectionTest < ActiveSupport::TestCase
  test "should create detection with required fields" do
    station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    detection = Detection.new(
      station: station,
      artist: "The Weeknd",
      title: "Blinding Lights",
      played_at: Time.current,
      source: "test"
    )

    assert detection.save
    assert detection.artist_title_normalized.present?
  end

  test "should normalize artist and title to lowercase" do
    station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    detection = Detection.create!(
      station: station,
      artist: "THE WEEKND",
      title: "BLINDING LIGHTS",
      played_at: Time.current,
      source: "test"
    )

    assert_equal "the weeknd-blinding lights", detection.artist_title_normalized
  end

  test "should strip whitespace from artist and title" do
    station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    detection = Detection.create!(
      station: station,
      artist: "  The Weeknd  ",
      title: "  Blinding Lights  ",
      played_at: Time.current,
      source: "test"
    )

    assert_equal "the weeknd-blinding lights", detection.artist_title_normalized
  end

  test "should require artist" do
    station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    detection = Detection.new(
      station: station,
      artist: nil,
      title: "Blinding Lights",
      played_at: Time.current
    )

    assert_not detection.valid?
    assert_includes detection.errors[:artist], "can't be blank"
  end

  test "should require title" do
    station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    detection = Detection.new(
      station: station,
      artist: "The Weeknd",
      title: nil,
      played_at: Time.current
    )

    assert_not detection.valid?
    assert_includes detection.errors[:title], "can't be blank"
  end

  test "should require played_at" do
    station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    detection = Detection.new(
      station: station,
      artist: "The Weeknd",
      title: "Blinding Lights",
      played_at: nil
    )

    assert_not detection.valid?
    assert_includes detection.errors[:played_at], "can't be blank"
  end

  test "should require station" do
    detection = Detection.new(
      station: nil,
      artist: "The Weeknd",
      title: "Blinding Lights",
      played_at: Time.current
    )

    assert_not detection.valid?
    assert_includes detection.errors[:station], "must exist"
  end

  test "should have default confidence of 1.0" do
    station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    detection = Detection.create!(
      station: station,
      artist: "The Weeknd",
      title: "Blinding Lights",
      played_at: Time.current,
      source: "test"
    )

    assert_equal 1.0, detection.confidence
  end

  test "should return recent detections in descending order" do
    station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    Detection.create!(
      station: station,
      artist: "Artist 1",
      title: "Title 1",
      played_at: 1.hour.ago,
      source: "test"
    )

    Detection.create!(
      station: station,
      artist: "Artist 2",
      title: "Title 2",
      played_at: 2.hours.ago,
      source: "test"
    )

    recent = Detection.recent.limit(2)

    assert_equal 2, recent.count
    assert_equal "Artist 1", recent.first.artist
  end
end
