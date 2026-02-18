# frozen_string_literal: true

require "test_helper"

class ApiTracksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one) || User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @station = stations(:one) || Station.create!(
      code: "test_station",
      title: "Test Station",
      player_url: "https://example.com"
    )

    @detection = Detection.create!(
      station: @station,
      artist: "The Weeknd",
      title: "Blinding Lights",
      played_at: Time.current,
      source: "test"
    )
  end

  test "GET /api/tracks/:id/where_now - requires authentication" do
    get api_track_where_now_url(@detection)
    assert_response :unauthorized
  end

  test "GET /api/tracks/:id/where_now - guest user gets trial limited" do
    sign_in @user
    # Guest user with trial attempts remaining
    @user.update!(paid_until: nil)

    get api_track_where_now_url(@detection)
    assert_response :success

    # Should create a tune_in attempt
    assert @user.tune_in_attempts.any?
  end

  test "GET /api/tracks/:id/where_now - paid user has no limits" do
    sign_in @user
    @user.update!(paid_until: 30.days.from_now)

    5.times do
      get api_track_where_now_url(@detection)
      assert_response :success
    end

    # Paid users don't create tune_in attempts
    assert_equal 0, @user.tune_in_attempts.count
  end

  test "GET /api/tracks/:id/where_soon - requires authentication" do
    get api_track_where_soon_url(@detection)
    assert_response :unauthorized
  end

  test "GET /api/tracks/:id/where_soon - requires paid subscription" do
    sign_in @user
    @user.update!(paid_until: nil)

    get api_track_where_soon_url(@detection)
    assert_response :forbidden
  end

  test "GET /api/tracks/:id/where_soon - paid user can access" do
    sign_in @user
    @user.update!(paid_until: 30.days.from_now)

    get api_track_where_soon_url(@detection, params: { window: "30m" })
    assert_response :success

    response = JSON.parse(body)
    assert response.key?("track")
    assert response.key?("window")
    assert response.key?("predictions")
  end
end
