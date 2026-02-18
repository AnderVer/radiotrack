# frozen_string_literal: true

class BookmarksController < ApplicationController
  before_action :authenticate_user!

  # GET /bookmarks
  def index
    @bookmarks = current_user.station_bookmarks.includes(:station).order(created_at: :desc)
  end

  # POST /bookmarks
  def create
    station = Station.find_by(id: params[:station_id])

    unless station
      redirect_to root_path, alert: "Станция не найдена"
      return
    end

    # Check limit
    limit = current_user.bookmarks_limit
    if limit && current_user.station_bookmarks.count >= limit
      redirect_to bookmarks_path, alert: "Достигнут лимит закладок (#{limit})"
      return
    end

    bookmark = current_user.station_bookmarks.find_or_create_by(station: station)

    if bookmark.persisted?
      redirect_to bookmarks_path, notice: "Станция добавлена в закладки"
    else
      redirect_to root_path, alert: "Ошибка при добавлении в закладки"
    end
  end

  # DELETE /bookmarks/:station_id
  def destroy
    bookmark = current_user.station_bookmarks.find_by(station_id: params[:station_id])

    if bookmark&.destroy
      redirect_to bookmarks_path, notice: "Станция удалена из закладок"
    else
      redirect_to bookmarks_path, alert: "Ошибка при удалении из закладок"
    end
  end
end
