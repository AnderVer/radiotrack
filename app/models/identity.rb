# frozen_string_literal: true

class Identity < ApplicationRecord
  belongs_to :user

  validates :provider, :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }

  # Access token for API calls (optional)
  encrypts :access_token, if: -> { Rails.application.credentials.secret_key_base.present? }
end
