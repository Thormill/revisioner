class AgentRevision < ActiveRecod::Base
  self.table_name = Config.revision_table_name
  has_many :payment_agent_transactions, dependent: :destroy, class_name: Config.payment_transaction_name

  attr_accessible :agent_code, :date_end, :date_start, :status, :data_file
end