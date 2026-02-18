# frozen_string_literal: true

require "test_helper"

class ApiStationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com",
      stream_url: "https://stream.example.com"
    )
  end

  test "GET /api/stations - returns list of stations" do
    get api_stations_url
    assert_response :success

    stations = JSON.parse(body)
    assert stations.is_a?(Array)
    assert stations.any? { |s| s["code"] == @station.code }
  end

  test "GET /api/stations/:id - returns station details" do
    get api_station_url(@station)
    assert_response :success

    station = JSON.parse(body)
    assert_equal @station.code, station["code"]
    assert_equal @station.title, station["title"]
  end

  test "GET /api/stations/:id - returns 404 for non-existent station" do
    assert_raises ActiveRecord::RecordNotFound do
      get api_station_url(id: 999_999)
    end
  end

  test "GET /api/stations/:id/last_track - requires authentication" do
    get api_station_last_track_url(@station)
    assert_response :unauthorized
  end

  test "GET /api/stations/:id/playlist - requires authentication" do
    get api_station_playlist_url(@station)
    assert_response :unauthorized
  end

  test "POST /api/stations/:id/capture_now_playing - requires authentication" do
    post api_station_capture_now_playing_url(@station)
    assert_response :unauthorized
  end
end
