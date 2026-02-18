# frozen_string_literal: true

class StationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  # GET /stations/:id
  def show
    @station = Station.find(params[:id])
    @recent_tracks = @station.detections.order(played_at: :desc).limit(20)
  end

  private

  def set_station
    @station = Station.find(params[:id])
  end
end
