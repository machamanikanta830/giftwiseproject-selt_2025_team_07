class CreateWishlists < ActiveRecord::Migration[7.1]
  def change
    create_table :wishlists do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: true
      t.string :item_name
      t.text :notes
      t.integer :priority

      t.timestamps
    end
  end
  def down
    drop_table :wishlists
  end
end
