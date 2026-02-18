class CreateDetections < ActiveRecord::Migration[8.0]
  def change
    create_table :detections do |t|
      t.references :station, null: false, foreign_key: true
      t.string :artist, null: false
      t.string :title, null: false
      t.string :artist_title_normalized, null: false
      t.datetime :played_at, null: false
      t.float :confidence, default: 1.0
      t.string :source

      t.timestamps
    end

    add_index :detections, :station_id
    add_index :detections, :played_at
    add_index :detections, :artist_title_normalized
    add_index :detections, [:station_id, :played_at]
  end
end
