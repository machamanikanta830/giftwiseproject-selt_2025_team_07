class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.text :message
      t.boolean :read
      t.datetime :sent_at

      t.timestamps
    end
  end
  def down
    drop_table :notifications
  end
end
