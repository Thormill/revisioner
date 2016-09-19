class CreateAgentTransactions < ActiveRecord::Migration
  def change
    create_table :agent_transactions do |t|
      t.integer :agent_revision_id, null: false
      t.datetime :create_time
      t.integer :status, null: false, default: 0
      t.integer :amount, null: false
      # t.string :report_file

      t.timestamps
    end

    add_index :agent_transactions, :agent_revision_id
  end
end

