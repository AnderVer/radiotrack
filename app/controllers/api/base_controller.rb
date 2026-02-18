# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    protect_from_forgery with: :null_session

    before_action :authenticate_user!

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    private

    def user_not_authorized
      render json: { error: "Not authorized" }, status: :forbidden
    end

    def current_user_or_guest
      current_user || GuestUser.new
    end
  end
end
