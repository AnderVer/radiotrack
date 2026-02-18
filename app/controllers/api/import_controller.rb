# frozen_string_literal: true

module Api
  class ImportController < BaseController
    # POST /api/import_local_data
    def import_local_data
      data = params.require(:data)

      # Import bookmarks
      if data[:bookmarks].present?
        import_bookmarks(data[:bookmarks])
      end

      # Import playlists
      if data[:playlists].present?
        import_playlists(data[:playlists])
      end

      render json: { success: true, message: "Data imported successfully" }
    end

    private

    def import_bookmarks(bookmarks_data)
      bookmarks_data.each do |bookmark|
        station = Station.find_by(code: bookmark[:station_code])
        next unless station

        current_user.station_bookmarks.find_or_create_by!(station: station)
      rescue ActiveRecord::RecordNotUnique
        # Skip duplicate bookmarks
      end
    end

    def import_playlists(playlists_data)
      playlists_data.each do |playlist_data|
        playlist = current_user.playlists.build(
          title: playlist_data[:title],
          local_id: playlist_data[:local_id]
        )

        if playlist.save
          playlist_data[:items]&.each do |item|
            playlist.playlist_items.create!(
              track_artist: item[:artist],
              track_title: item[:title],
              position: item[:position] || 0,
              status: "resolved"
            )
          end
        end
      rescue ActiveRecord::RecordInvalid
        # Skip invalid playlists
      end
    end
  end
end
