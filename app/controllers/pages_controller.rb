# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  # GET /
  def home
    @stations = Station.active.federal.limit(10)
  end
end
