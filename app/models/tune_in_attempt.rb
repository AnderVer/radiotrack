# frozen_string_literal: true

class TuneInAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :track, class_name: "Detection"

  validates :user_id, presence: true
  validates :track_id, presence: true

  # Scope for today's attempts
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }
end
