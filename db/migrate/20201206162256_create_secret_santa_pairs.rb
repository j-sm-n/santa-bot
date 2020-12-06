class CreateSecretSantaPairs < ActiveRecord::Migration[6.0]
  def change
    create_table :secret_santa_pairs do |t|
      t.integer :secret_santa_id
      t.integer :recipient_id

      t.timestamps
    end
  end
end
