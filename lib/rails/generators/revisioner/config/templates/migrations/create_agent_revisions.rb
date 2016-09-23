class CreateAgentRevisions < ActiveRecord::Migration
  def change
    create_table :agent_revisions do |t|
      t.integer :agent_code
      t.date :date_start
      t.date :date_end
      t.integer :status
      t.string :data_file

      t.timestamps
    end

    add_index :agent_revisions, [:date_start, :date_end] #, :desc
  end
end

