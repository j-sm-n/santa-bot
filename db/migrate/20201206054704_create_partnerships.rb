class CreatePartnerships < ActiveRecord::Migration[6.0]
  def change
    create_table :partnerships do |t|
      t.integer :partner_one_id
      t.integer :partner_two_id

      t.timestamps
    end
  end
end
