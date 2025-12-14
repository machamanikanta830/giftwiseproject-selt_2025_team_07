class AddUniqueIndexToRecipientsUserIdEmail < ActiveRecord::Migration[7.1]
  def change
    add_index :recipients, [:user_id, :email], unique: true
  end
end
