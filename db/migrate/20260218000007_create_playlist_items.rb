class CreatePlaylistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :playlist_items do |t|
      t.references :playlist, null: false, foreign_key: true
      t.string :track_artist
      t.string :track_title
      t.integer :position, null: false
      t.string :status, null: false, default: "resolved" # resolved, pending, unresolved
      t.references :captured_station, foreign_key: { to_table: :stations }
      t.datetime :captured_at
      t.references :resolved_detection, foreign_key: { to_table: :detections }
      t.datetime :resolved_at
      t.string :unresolved_reason

      t.timestamps
    end

    add_index :playlist_items, :playlist_id
    add_index :playlist_items, :status
    add_index :playlist_items, [:playlist_id, :position]
  end
end
