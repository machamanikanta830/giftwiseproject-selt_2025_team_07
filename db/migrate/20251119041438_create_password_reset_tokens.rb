class CreatePasswordResetTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :password_reset_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token
      t.datetime :expires_at
      t.boolean :used

      t.timestamps
    end
  end
  def down
    drop_table :password_reset_tokens
  end
end
