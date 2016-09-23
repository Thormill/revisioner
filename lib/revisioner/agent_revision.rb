module Revisioner
    class AgentRevision < ActiveRecord::Base
    self.table_name = Revisioner::Config.revision_table_name
    has_many :agent_transactions, dependent: :destroy, class_name: Revisioner::AgentTransaction

    attr_accessible :agent_code, :date_end, :date_start, :status, :data_file
  end
end