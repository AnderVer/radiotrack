class CreateStations < ActiveRecord::Migration[8.0]
  def change
    create_table :stations do |t|
      t.string :code, null: false
      t.string :title, null: false
      t.string :player_url, null: false
      t.text :description
      t.boolean :active, default: true
      t.boolean :federal, default: true
      t.references :now_playing_track, foreign_key: { to_table: :detections }

      t.timestamps
    end

    add_index :stations, :code, unique: true
    add_index :stations, :active
    add_index :stations, :federal
  end
end
