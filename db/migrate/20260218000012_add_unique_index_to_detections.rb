class AddUniqueIndexToDetections < ActiveRecord::Migration[8.0]
  def up
    # Check if index already exists
    if index_exists?(:detections, [:station_id, :played_at, :artist_title_normalized], name: "index_detections_unique_station_played_artist_title")
      puts "Unique index already exists"
      return
    end

    # Add unique index
    add_index(
      :detections,
      [:station_id, :played_at, :artist_title_normalized],
      unique: true,
      name: "index_detections_unique_station_played_artist_title"
    )

    puts "Unique index added successfully"
  end

  def down
    remove_index(
      :detections,
      name: "index_detections_unique_station_played_artist_title"
    )

    puts "Unique index removed"
  end
end
