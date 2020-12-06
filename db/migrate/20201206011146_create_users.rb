class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :slack_id
      t.string :dm_channel_id
      t.string :address

      t.timestamps
    end
  end
end
