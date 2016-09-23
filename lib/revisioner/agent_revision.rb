module Revisioner
  class AgentRevision < ActiveRecord::Base
    self.table_name = Revisioner::Config[:revision_table_name]
    has_many :agent_transactions, dependent: :destroy #, class_name: AgentTransaction
    attr_accessible :agent_code, :date_end, :date_start, :status, :data_file

    STATUS_COMPLETED = 2
    STATUS_PAID = 2


    def get_differences
    end

    def get_differences
      case agent_code
      when Revisioner::Parser::AGENT_QIWI
        get_agent_differences("pc_payment_id", "qiwi", Revisioner::Parser::STATUS_QIWI)
      when Revisioner::Parser::AGENT_WEBMONEY
        get_agent_differences("pc_payment_id", "ebmoney")
      when Revisioner::Parser::AGENT_MOBI
        get_agent_differences("agent_id", "mobi")
      when Revisioner::Parser::AGENT_YANDEX
        get_agent_differences("agent_id", "yandex")
      end
    end

    def get_agent_differences(compare, agent, status = "")
      payments_column = case compare
      when "pc_payment_id"
        payments_column = "pc_pc_payment_id"
      when "agent_id"
        payments_column = "pc_agent_id"
      end

      transactions_table = Revisioner::AgentTransaction.table_name

      External::PaymentAgentTransaction.joins("FULL OUTER JOIN (SELECT id AS transaction_id,
                                                                       'payments' AS table_name,
                                                                       external_payment_id AS pc_pc_payment_id,
                                                                       agent_payment_id AS pc_agent_id,
                                                                       payment_system AS pc_payment_system,
                                                                       amount AS pc_amount,
                                                                       external_payment_time AS pc_date
                                                                FROM payments
                                                                WHERE status = #{STATUS_COMPLETED}
                                                                      AND payment_system IS NOT NULL
                                                                      AND external_payment_time BETWEEN '#{self.date_start - 3.hours}' AND '#{self.date_end - 3.hours}'
                                                                UNION ALL
                                                                SELECT id AS transaction_id,
                                                                       'payment_transactions' AS table_name,
                                                                       external_id AS pc_pc_payment_id,
                                                                       agent_payment_id AS pc_agent_id,
                                                                       payment_system AS pc_payment_system,
                                                                       amount AS pc_amount,
                                                                       payment_time AS pc_date
                                                                FROM payment_transactions
                                                                WHERE status = #{STATUS_PAID}
                                                                      AND payment_system IS NOT NULL
                                                                      AND payment_time BETWEEN '#{self.date_start - 3.hours}' AND '#{self.date_end - 3.hours}')
                                                                AS all_smp_payments
                                                            ON all_smp_payments.#{payments_column} = #{transactions_table}.#{compare}
                                                               AND #{transactions_table}.agent_revision_id = #{self.id}")
                                        .select("#{transactions_table}.*, all_smp_payments.*")
                                        .where("(#{transactions_table}.agent_revision_id = #{self.id}
                                                OR #{transactions_table}.id IS NULL)
                                                AND (lower(all_smp_payments.pc_payment_system) LIKE '%#{agent}%'
                                                OR all_smp_payments.transaction_id IS NOT NULL
                                                AND #{transactions_table}.id IS NOT NULL
                                                OR all_smp_payments.transaction_id IS NULL)
                                                AND (all_smp_payments.transaction_id IS NULL
                                                OR #{transactions_table}.id IS NULL
                                                OR #{transactions_table}.status <> '#{status}'
                                                OR #{transactions_table}.amount*100 <> all_smp_payments.pc_amount)")
                                        .all
    end
  end
end