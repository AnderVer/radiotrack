# frozen_string_literal: true

require "test_helper"

class DetectionUniqueIndexTest < ActiveSupport::TestCase
  setup do
    @station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    @played_at = Time.utc(2026, 2, 18, 8, 38, 0)
    @artist = "The Weeknd"
    @title = "Blinding Lights"
  end

  test "should allow unique detection" do
    detection = Detection.create!(
      station: @station,
      artist: @artist,
      title: @title,
      played_at: @played_at,
      source: "test"
    )

    assert detection.persisted?
  end

  test "should prevent duplicate detection with same station_id, played_at, artist_title_normalized" do
    # Create first detection
    Detection.create!(
      station: @station,
      artist: @artist,
      title: @title,
      played_at: @played_at,
      source: "test"
    )

    # Try to create duplicate with different case (should normalize to same key)
    duplicate = Detection.new(
      station: @station,
      artist: @artist.upcase,
      title: @title.upcase,
      played_at: @played_at,
      source: "test"
    )

    # Should fail validation due to unique index
    assert_raises ActiveRecord::RecordNotUnique do
      duplicate.save!
    end
  end

  test "should allow detections with different played_at" do
    Detection.create!(
      station: @station,
      artist: @artist,
      title: @title,
      played_at: @played_at,
      source: "test"
    )

    # Different time should be allowed
    detection2 = Detection.create!(
      station: @station,
      artist: @artist,
      title: @title,
      played_at: @played_at + 1.minute,
      source: "test"
    )

    assert detection2.persisted?
  end

  test "should allow detections for different stations" do
    station2 = Station.create!(
      code: "test_station_2",
      title: "Test Station 2",
      player_url: "https://example2.com"
    )

    Detection.create!(
      station: @station,
      artist: @artist,
      title: @title,
      played_at: @played_at,
      source: "test"
    )

    # Different station should be allowed
    detection2 = Detection.create!(
      station: station2,
      artist: @artist,
      title: @title,
      played_at: @played_at,
      source: "test"
    )

    assert detection2.persisted?
  end

  test "should allow detections with different track" do
    Detection.create!(
      station: @station,
      artist: @artist,
      title: @title,
      played_at: @played_at,
      source: "test"
    )

    # Different track should be allowed
    detection2 = Detection.create!(
      station: @station,
      artist: "Dua Lipa",
      title: "Levitating",
      played_at: @played_at,
      source: "test"
    )

    assert detection2.persisted?
  end
end
