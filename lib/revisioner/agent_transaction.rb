class AgentTransaction < ActiveRecord::Base
  self.table_name = Config.agent_transaction_table_name
end