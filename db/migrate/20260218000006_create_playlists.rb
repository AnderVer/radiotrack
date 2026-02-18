class CreatePlaylists < ActiveRecord::Migration[8.0]
  def change
    create_table :playlists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :local_id  # For guest playlist import
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :playlists, :user_id
    add_index :playlists, [:user_id, :local_id]
  end
end
