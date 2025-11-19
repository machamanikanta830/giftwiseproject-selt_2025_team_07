class CreateGiftGivenBacklogs < ActiveRecord::Migration[7.1]
  def change
    create_table :gift_given_backlogs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: true
      t.string :gift_name
      t.text :description
      t.decimal :price
      t.string :category
      t.string :purchase_link
      t.date :given_on
      t.integer :created_from_idea_id

      t.timestamps
    end
  end
  def down
    drop_table :gift_given_backlogs
  end
end
