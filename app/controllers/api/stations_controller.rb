# frozen_string_literal: true

module Api
  class StationsController < BaseController
    before_action :set_station, only: [:show, :last_track, :playlist, :capture_now_playing]

    # GET /api/stations
    def index
      @stations = Station.active.federal.includes(:last_track)
      render json: @stations.as_json(
        include: {
          last_track: { only: [:artist, :title, :played_at] }
        }
      )
    end

    # GET /api/stations/:id
    def show
      render json: @station.as_json(
        include: {
          last_track: { only: [:artist, :title, :played_at] }
        }
      )
    end

    # GET /api/stations/:id/last_track (Paid only)
    def last_track
      authorize! :last_track, @station
      track = @station.last_track
      if track
        render json: track.as_json(only: [:artist, :title, :played_at])
      else
        render json: { error: "No track data available" }, status: :not_found
      end
    end

    # GET /api/stations/:id/playlist?range=30m (Paid only)
    def playlist
      authorize! :playlist, @station
      range = params[:range] || "30m"
      tracks = @station.playlist(range: range)
      render json: tracks.as_json(only: [:artist, :title, :played_at])
    end

    # POST /api/stations/:id/capture_now_playing (Paid only)
    def capture_now_playing
      authorize! :capture_now_playing, @station
      playlist = current_user.playlists.find_by(id: params[:playlist_id])

      unless playlist
        return render json: { error: "Playlist not found" }, status: :not_found
      end

      item = playlist.add_pending_track(
        captured_station_id: @station.id,
        captured_at: Time.current
      )

      # Schedule resolution job
      PlaylistItemResolutionJob.perform_later(item.id)

      render json: {
        playlist_item_id: item.id,
        status: "pending",
        message: "Track will be resolved shortly"
      }, status: :created
    end

    private

    def set_station
      @station = Station.find_by!(id: params[:id])
    end

    def authorize!(action, station)
      unless current_user.can_access_last_track?
        render json: { error: "Subscription required", feature: action }, status: :forbidden
      end
    end
  end
end
