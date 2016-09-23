module Revisioner
  class AgentTransaction < ActiveRecord::Base
    self.table_name = Revisioner::Config[:agent_transaction_table_name]
    belongs_to :agent_revision #, class_name: Revisioner::AgentRevision

    attr_accessible :agent_revision_id, :agent_code, :agent_id,
                    :amount, :date, :status, :pc_payment_id
  end
end