class CreateAgentTransactions < ActiveRecord::Migration
  def change
    create_table :agent_transactions do |t|
      t.integer :agent_revision_id, null: false
      t.integer :agent_transaction_id
      t.date    :date
      t.integer :status, null: false, default: 0
      t.integer :amount, null: false
      t.string  :pc_payment_id #["ID счета"],

      t.timestamps
    end

    add_index :agent_transactions, :agent_revision_id
  end
end

