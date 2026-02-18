class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      # Devise fields
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      # Subscription fields
      t.datetime :paid_until
      t.string :plan_code, default: "guest"
      t.integer :trial_tune_in_remaining, default: 3

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :paid_until
  end
end
