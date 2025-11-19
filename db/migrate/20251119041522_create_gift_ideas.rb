class CreateGiftIdeas < ActiveRecord::Migration[7.1]
  def change
    create_table :gift_ideas do |t|
      t.references :event_recipient, null: false, foreign_key: true
      t.string :idea
      t.text :description
      t.decimal :price_estimate
      t.string :link

      t.timestamps
    end
  end
  def down
    drop_table :gift_ideas
  end
end
