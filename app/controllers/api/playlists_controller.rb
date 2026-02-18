# frozen_string_literal: true

module Api
  class PlaylistsController < BaseController
    before_action :set_playlist, only: [:show, :update, :destroy]

    # GET /api/playlists
    def index
      @playlists = current_user.playlists.includes(:items).order(:position)
      render json: @playlists.as_json(
        include: {
          items: {
            only: [:id, :track_artist, :track_title, :position, :status]
          }
        }
      )
    end

    # GET /api/playlists/:id
    def show
      render json: @playlist.as_json(
        include: {
          items: {
            only: [:id, :track_artist, :track_title, :position, :status,
                   :captured_station_id, :resolved_at, :unresolved_reason],
            methods: [:display_artist, :display_title]
          }
        }
      )
    end

    # POST /api/playlists
    def create
      limit = current_user.playlists_limit
      if current_user.playlists.count >= limit
        return render json: {
          error: "Playlists limit reached",
          limit: limit
        }, status: :forbidden
      end

      @playlist = current_user.playlists.build(playlist_params)
      if @playlist.save
        render json: @playlist.as_json, status: :created
      else
        render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH /api/playlists/:id
    def update
      if @playlist.update(playlist_params)
        render json: @playlist.as_json
      else
        render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/playlists/:id
    def destroy
      @playlist.destroy
      head :no_content
    end

    private

    def set_playlist
      @playlist = current_user.playlists.find_by!(id: params[:id])
    end

    def playlist_params
      params.require(:playlist).permit(:title, :local_id)
    end
  end
end
