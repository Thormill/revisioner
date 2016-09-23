module Revisioner
  class AgentTransaction < ActiveRecord::Base
    self.table_name = Revisioner::Config[:agent_transaction_table_name]

    belongs_to :agent_revision #, class_name: Revisioner::AgentRevision
  end
end