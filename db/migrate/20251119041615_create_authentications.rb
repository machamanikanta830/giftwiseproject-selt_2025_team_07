class CreateAuthentications < ActiveRecord::Migration[7.1]
  def change
    create_table :authentications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider
      t.string :uid
      t.string :email
      t.string :name
      t.string :avatar_url

      t.timestamps
    end
  end
  def down
    drop_table :authentications
  end
end
