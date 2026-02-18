class AddPlaylistUrlToStations < ActiveRecord::Migration[8.0]
  def change
    add_column :stations, :playlist_url, :string
    add_comment :stations, :playlist_url, "URL to the station's public playlist page (e.g., Avtoradio)"
  end
end
