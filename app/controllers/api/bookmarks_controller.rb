# frozen_string_literal: true

module Api
  class BookmarksController < BaseController
    # GET /api/user/bookmarks
    def index
      @bookmarks = current_user_or_guest.station_bookmarks.includes(:station)
      render json: @bookmarks.as_json(
        include: {
          station: { only: [:id, :code, :title, :player_url] }
        }
      )
    end

    # POST /api/user/bookmarks
    def create
      station = Station.find_by!(id: params[:station_id])

      # Check limit for guest users
      if current_user_or_guest.guest?
        limit = current_user_or_guest.bookmarks_limit
        if current_user_or_guest.station_bookmarks.count >= limit
          return render json: {
            error: "Bookmark limit reached",
            limit: limit,
            upgrade_required: true
          }, status: :forbidden
        end
      end

      @bookmark = current_user_or_guest.station_bookmarks.find_or_create_by!(station: station)
      render json: @bookmark.as_json(include: { station: { only: [:id, :code, :title] } }),
             status: :created
    end

    # DELETE /api/user/bookmarks/:station_id
    def destroy
      @bookmark = current_user_or_guest.station_bookmarks.find_by!(station_id: params[:station_id])
      @bookmark.destroy
      head :no_content
    end
  end
end
