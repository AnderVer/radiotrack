# frozen_string_literal: true

class StationBookmark < ApplicationRecord
  belongs_to :user
  belongs_to :station

  validates :user_id, uniqueness: { scope: :station_id }
  validate :check_bookmark_limit, on: :create

  private

  def check_bookmark_limit
    return if user.guest?

    limit = user.bookmarks_limit
    return unless limit
    return if user.station_bookmarks.count < limit

    errors.add(:base, "Bookmark limit reached for #{user.plan_code} plan")
  end
end
