class CreateAiGiftSuggestions < ActiveRecord::Migration[7.1]
  def up
    create_table :ai_gift_suggestions do |t|
      # Required ownership context
      t.references :user,            null: false, foreign_key: true
      t.references :event,           null: false, foreign_key: true
      t.references :recipient,       null: false, foreign_key: true
      t.references :event_recipient, null: false, foreign_key: true

      # Which AI round created this suggestion
      t.string :round_type, default: "initial"

      # Suggestion content
      t.string :title, null: false
      t.text   :description
      t.string :estimated_price
      t.string :category
      t.string :special_notes
      t.string :image_url

      # Whether the user saved this suggestion
      t.boolean :saved_to_wishlist, default: false

      t.timestamps
    end

    # Indexes
    add_index :ai_gift_suggestions, [:event_recipient_id, :round_type]
  end

  def down
    drop_table :ai_gift_suggestions
  end
end
