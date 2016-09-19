class CreateAgentRevisions < ActiveRecord::Migration
  def change
    create_table :agent_revisions do |t|
      t.date :date
      t.integer :status
      t.string :agent # integer?
      # t.string :report_file

      t.timestamps
    end

    add_index :agent_revisions, :date #, :desc
  end
end

