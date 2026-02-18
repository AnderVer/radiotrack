class CreateTuneInAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :tune_in_attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: { to_table: :detections }

      t.timestamps
    end

    add_index :tune_in_attempts, :user_id
    add_index :tune_in_attempts, :created_at
  end
end
