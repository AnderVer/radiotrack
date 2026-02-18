# frozen_string_literal: true

require "test_helper"

class TimezoneConversionTest < ActiveSupport::TestCase
  test "MSK 11:38 converts to UTC 08:38" do
    # 18 February 2026, 11:38 MSK
    msk_time = Time.zone.parse("2026-02-18 11:38:00 Europe/Moscow")
    utc_time = msk_time.utc

    assert_equal 8, utc_time.hour
    assert_equal 38, utc_time.min
    assert_equal 0, utc_time.sec
  end

  test "MSK midnight converts to UTC previous day" do
    # 18 February 2026, 00:00 MSK
    msk_time = Time.zone.parse("2026-02-18 00:00:00 Europe/Moscow")
    utc_time = msk_time.utc

    assert_equal 21, utc_time.hour
    assert_equal 0, utc_time.min
    assert_equal 17, utc_time.day  # Previous day
  end

  test "UTC 08:38 converts to MSK 11:38" do
    # 18 February 2026, 08:38 UTC
    utc_time = Time.utc(2026, 2, 18, 8, 38, 0)
    msk_time = utc_time.in_time_zone("Europe/Moscow")

    assert_equal 11, msk_time.hour
    assert_equal 38, msk_time.min
  end

  test "AvtoradioParser creates detections in UTC" do
    html = <<-HTML
      <html>
        <body>
          <h1>Что за песня звучала 18 февраля 2026 в 11:38?</h1>
          <ul class="what-list">
            <li class="fl pr">
              <span class="time fl">11:38</span>
              <div class="what-name fl"><b>Artist</b><br>Title</div>
            </li>
          </ul>
        </body>
      </html>
    HTML

    parser = AvtoradioPlaylistParser.new
    tracks = parser.parse(html: html)

    assert_equal 1, tracks.count
    track = tracks.first

    # played_at should be in UTC (08:38)
    assert_equal 8, track[:played_at].hour
    assert_equal 38, track[:played_at].min

    # When converted to MSK, should be 11:38
    msk_time = track[:played_at].in_time_zone("Europe/Moscow")
    assert_equal 11, msk_time.hour
    assert_equal 38, msk_time.min
  end

  test "Detection played_at stored in UTC" do
    station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    # Create detection with MSK time
    msk_time = Time.zone.parse("2026-02-18 11:38:00 Europe/Moscow")

    detection = Detection.create!(
      station: station,
      artist: "Artist",
      title: "Title",
      played_at: msk_time.utc,  # Store in UTC
      source: "test"
    )

    # Reload from DB
    detection.reload

    # Should be stored in UTC
    assert_equal "UTC", detection.played_at.time_zone_name

    # When displayed in MSK, should show correct time
    msk_display = detection.played_at.in_time_zone("Europe/Moscow")
    assert_equal 11, msk_display.hour
    assert_equal 38, msk_display.min
  end
end
