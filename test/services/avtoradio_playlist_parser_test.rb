# frozen_string_literal: true

require "test_helper"
require_relative "../../app/services/avtoradio_playlist_parser"

class AvtoradioPlaylistParserTest < ActiveSupport::TestCase
  def setup
    @parser = AvtoradioPlaylistParser.new
    @html_fixture = Rails.root.join("test/fixtures/files/avtoradio_playlist.html").read
  end

  test "should parse tracks from HTML fixture" do
    tracks = @parser.parse(html: @html_fixture)

    assert_equal 4, tracks.count
    assert_equal "11:38", tracks[0][:played_at].strftime("%H:%M")
    assert_equal "30.02", tracks[0][:artist]
    assert_equal "Примером", tracks[0][:title]
  end

  test "should parse all track fields correctly" do
    tracks = @parser.parse(html: @html_fixture)

    # First track
    assert_equal "30.02", tracks[0][:artist]
    assert_equal "Примером", tracks[0][:title]
    assert_equal "avtoradio_playlist", tracks[0][:source]

    # Second track
    assert_equal "Високосный Год", tracks[1][:artist]
    assert_equal "Глупое, Несмешное Кино", tracks[1][:title]

    # Third track
    assert_equal "The Weeknd", tracks[2][:artist]
    assert_equal "Dancing In The Flames", tracks[2][:title]
  end

  test "should extract date from header" do
    tracks = @parser.parse(html: @html_fixture)

    # Date should be 18 February 2026
    assert_equal 18, tracks[0][:played_at].day
    assert_equal 2, tracks[0][:played_at].month
    assert_equal 2026, tracks[0][:played_at].year
  end

  test "should convert MSK time to UTC" do
    tracks = @parser.parse(html: @html_fixture)

    # 11:38 MSK should be 08:38 UTC (MSK = UTC + 3)
    assert_equal 8, tracks[0][:played_at].hour
    assert_equal 38, tracks[0][:played_at].min
  end

  test "should return empty array for blank HTML" do
    tracks = @parser.parse(html: "")
    assert_equal [], tracks

    tracks = @parser.parse(html: nil)
    assert_equal [], tracks
  end

  test "should return empty array when playlist list not found" do
    html = "<html><body><h1>Test</h1></body></html>"
    tracks = @parser.parse(html: html)
    assert_equal [], tracks
  end

  test "should skip items without valid time" do
    html = <<-HTML
      <html>
        <body>
          <h1>Что за песня звучала 18 февраля 2026 в 11:38?</h1>
          <ul class="what-list">
            <li class="fl pr">
              <span class="time fl">invalid</span>
              <div class="what-name fl"><b>Artist</b><br>Title</div>
            </li>
            <li class="fl pr">
              <span class="time fl">11:35</span>
              <div class="what-name fl"><b>Valid</b><br>Track</div>
            </li>
          </ul>
        </body>
      </html>
    HTML

    tracks = @parser.parse(html: html)
    assert_equal 1, tracks.count
    assert_equal "Valid", tracks[0][:artist]
  end

  test "should skip items without artist or title" do
    html = <<-HTML
      <html>
        <body>
          <h1>Что за песня звучала 18 февраля 2026 в 11:38?</h1>
          <ul class="what-list">
            <li class="fl pr">
              <span class="time fl">11:35</span>
              <div class="what-name fl"><b></b><br></div>
            </li>
            <li class="fl pr">
              <span class="time fl">11:30</span>
              <div class="what-name fl"><b>Artist</b><br>Title</div>
            </li>
          </ul>
        </body>
      </html>
    HTML

    tracks = @parser.parse(html: html)
    assert_equal 1, tracks.count
  end

  test "MONTHS constant should have all Russian months" do
    months = AvtoradioPlaylistParser::MONTHS

    assert_equal 12, months.count
    assert_equal 1, months["января"]
    assert_equal 2, months["февраля"]
    assert_equal 12, months["декабря"]
  end

  test "should handle current date if header date not found" do
    html = <<-HTML
      <html>
        <body>
          <ul class="what-list">
            <li class="fl pr">
              <span class="time fl">11:35</span>
              <div class="what-name fl"><b>Artist</b><br>Title</div>
            </li>
          </ul>
        </body>
      </html>
    HTML

    tracks = @parser.parse(html: html)
    assert_equal 1, tracks.count
    # Date should be today in MSK timezone
    assert_equal Date.current.in_time_zone("Europe/Moscow").day, tracks[0][:played_at].in_time_zone("Europe/Moscow").day
  end
end
