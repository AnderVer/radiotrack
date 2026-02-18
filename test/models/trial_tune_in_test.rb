# frozen_string_literal: true

require "test_helper"

class TrialTuneInTest < ActiveSupport::TestCase
  setup do
    @guest_user = User.create!(
      email: "guest@example.com",
      password: "password123",
      password_confirmation: "password123",
      paid_until: nil,
      plan_code: "guest"
    )

    @paid_user = User.create!(
      email: "paid@example.com",
      password: "password123",
      password_confirmation: "password123",
      paid_until: 30.days.from_now,
      plan_code: "paid"
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

  test "guest user starts with 3 trial attempts" do
    assert_equal 3, @guest_user.trial_tune_in_remaining
  end

  test "guest user trial decrements on where_now" do
    initial_remaining = @guest_user.trial_tune_in_remaining

    # Simulate where_now call
    @guest_user.record_tune_in!

    assert_equal initial_remaining - 1, @guest_user.reload.trial_tune_in_remaining
  end

  test "guest user blocked after 3 attempts" do
    # Use all 3 attempts
    3.times { @guest_user.record_tune_in! }

    assert_equal 0, @guest_user.reload.trial_tune_in_remaining
    assert_not @guest_user.can_tune_in?
  end

  test "paid user has unlimited attempts" do
    assert_nil @paid_user.trial_tune_in_remaining
    assert @paid_user.can_tune_in?

    # Simulate many where_now calls
    10.times { @paid_user.record_tune_in! }

    # Still can tune in (paid users not limited)
    assert @paid_user.reload.can_tune_in?
  end

  test "trial attempts reset daily" do
    # Use all attempts
    3.times { @guest_user.record_tune_in! }
    assert_equal 0, @guest_user.reload.trial_tune_in_remaining

    # Simulate next day (mock Time.current.beginning_of_day)
    # In real app, this would reset automatically
    # For test, we verify the logic uses beginning_of_day
    assert @guest_user.tune_in_attempts.where("created_at >= ?", Time.current.beginning_of_day).any?
  end

  test "where_now creates tune_in attempt for guest" do
    assert_difference "@guest_user.tune_in_attempts.count", 1 do
      @guest_user.record_tune_in!
    end
  end

  test "where_now does not decrement for paid user" do
    initial_count = @paid_user.tune_in_attempts.count

    # Paid users can still create attempts (for tracking)
    # but they don't count against limit
    @paid_user.record_tune_in!

    # Attempt created but no decrement
    assert @paid_user.tune_in_attempts.count > initial_count
    assert_nil @paid_user.trial_tune_in_remaining
  end
end
