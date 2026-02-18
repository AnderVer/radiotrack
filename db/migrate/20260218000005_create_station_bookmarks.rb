class CreateStationBookmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :station_bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :station, null: false, foreign_key: true

      t.timestamps
    end

    add_index :station_bookmarks, [:user_id, :station_id], unique: true
  end
end
