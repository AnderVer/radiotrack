class AddStreamUrlToStations < ActiveRecord::Migration[8.0]
  def change
    add_column :stations, :stream_url, :string
    add_column :stations, :contest_enabled, :boolean, default: true
    add_column :stations, :contest_page_url, :string
    
    # Migrate existing player_url to stream_url
    reversible do |dir|
      dir.up do
        execute "UPDATE stations SET stream_url = player_url WHERE stream_url IS NULL"
      end
    end
  end
end
