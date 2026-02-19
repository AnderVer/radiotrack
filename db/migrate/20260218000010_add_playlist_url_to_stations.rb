class AddPlaylistUrlToStations < ActiveRecord::Migration[8.0]
  def change
    add_column :stations, :playlist_url, :string
  end
end
