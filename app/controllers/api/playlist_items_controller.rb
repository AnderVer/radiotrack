# frozen_string_literal: true

module Api
  class PlaylistItemsController < BaseController
    before_action :set_playlist
    before_action :set_item, only: [:show, :update, :destroy, :resolve]

    # GET /api/playlists/:playlist_id/items
    def index
      @items = @playlist.items.ordered
      render json: @items.as_json(
        only: [:id, :track_artist, :track_title, :position, :status,
               :captured_station_id, :resolved_at, :unresolved_reason],
        methods: [:display_artist, :display_title]
      )
    end

    # GET /api/playlists/:playlist_id/items/:id
    def show
      render json: @item.as_json(
        only: [:id, :track_artist, :track_title, :position, :status,
               :captured_station_id, :resolved_at, :unresolved_reason],
        methods: [:display_artist, :display_title]
      )
    end

    # POST /api/playlists/:playlist_id/items
    def create
      limit = current_user.playlist_items_per_playlist_limit
      if @playlist.playlist_items.count >= limit
        return render json: {
          error: "Items limit reached for this playlist",
          limit: limit
        }, status: :forbidden
      end

      @item = @playlist.playlist_items.build(item_params)
      @item.position = (@playlist.playlist_items.maximum(:position) || 0) + 1

      if @item.save
        render json: @item.as_json, status: :created
      else
        render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH /api/playlists/:playlist_id/items/:id
    def update
      if @item.update(item_params)
        render json: @item.as_json
      else
        render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/playlists/:playlist_id/items/:id
    def destroy
      @item.destroy
      head :no_content
    end

    # POST /api/playlists/:playlist_id/items/:id/resolve
    def resolve
      @item.resolve!
      render json: @item.as_json(
        only: [:id, :track_artist, :track_title, :position, :status,
               :resolved_at, :unresolved_reason],
        methods: [:display_artist, :display_title]
      )
    end

    private

    def set_playlist
      @playlist = current_user.playlists.find_by!(id: params[:playlist_id])
    end

    def set_item
      @item = @playlist.playlist_items.find_by!(id: params[:id])
    end

    def item_params
      params.require(:item).permit(:track_artist, :track_title, :position)
    end
  end
end
