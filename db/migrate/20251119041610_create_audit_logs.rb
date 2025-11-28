class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :resource_type
      t.integer :resource_id
      t.string :action
      t.text :old_value
      t.text :new_value

      t.timestamps
    end
  end
  def down
    drop_table :audit_logs
  end
end
