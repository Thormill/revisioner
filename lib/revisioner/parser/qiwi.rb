#encoding: utf-8
# @author: Anton Shisnkin, Yuriy Soshin
module Revisioner::Parser
  class Qiwi
    HEADERS = [
              "Статус",
              "Дата выставления",
              "Дата оплаты",
              "ID счета",
              "Visa QIWI Wallet",
              "Сумма счета",
              "Сумма оплаты",
              "Сумма всех возвратов",
              "Валюта",
              "Комментарий"
            ]

    class << self
      def revision_from_file(filepath, filename) #Создание сверки
        data = []
        date_min = Time.now
        date_max = Time.parse("2001-01-01")

        encodings = EncodingSampler::Sampler.new(filepath, ['UTF-8']).valid_encodings
        encoding = nil
        encoding = 'windows-1251:utf-8' unless encodings.include? 'UTF-8'

        begin
          CSV.foreach(filepath, encoding: encoding, col_sep: ';', skip_blanks: true, headers: true, skip_lines: /^[^;]*$/) do |row|
            hash = row.to_h

            if (hash["Комментарий"] || '').strip == QIWI_COMMENT
              data << {
                        :agent_code => AGENT_QIWI,
                        :agent_id => hash["ID счета"],
                        :amount => hash["Сумма счета"].to_i,
                        :date => Time.parse(hash["Дата выставления"]),
                        :pc_payment_id => hash["ID счета"],
                        :status => hash["Статус"]
                      }
              date_min = [date_min, Time.parse(hash["Дата выставления"])].min
              date_max = [date_max, Time.parse(hash["Дата выставления"])].max
            end

          end
        rescue Exception => e
          Log.error("#{filename}. Не удалось создать сверку с источниками денег: %s: %s" % [e.class, e.message], component: Components::PAYMENT_AGENT_REVISION)
          return false
        end

        #------
        if !data.empty?
          rev = AgentRevision.create(:agent_code => data[0][:agent_code],
                                    :date_start => date_min.beginning_of_day,
                                    :date_end => date_max.end_of_day)
          rev.payment_agent_transactions.create(data)

          revision_result = rev.get_differences

          case rev.count = revision_result.count
            when 0
              rev.status = Revisioner::REVISION_SUCCESS
            else
              rev.status = Revisioner::REVISION_FAILURE
          end


          agent = "qiwi"
          external_payment = Config[:external_payment_name].constantize
          payment_transaction = Config[:payment_transaction_name].constantize

          external_payment.where("external_payment_time BETWEEN ? AND ?", rev.date_start, rev.date_end)
                           .where("payment_system LIKE '%#{agent}%'")
                           .update_all(payment_agent_revision_status: Revisioner::REVISION_SUCCESS)

          payment_transaction.where("payment_time BETWEEN ? AND ?", rev.date_start, rev.date_end)
                            .where("payment_system LIKE '%#{agent}%'")
                            .update_all(payment_agent_revision_status: Revisioner::REVISION_SUCCESS)

          revision_result.each do |transaction|
            if transaction.id.blank? && transaction.transaction_id.present?
              case transaction.table_name
              when "payments"
                external_payment.find(transaction.transaction_id)
                                 .update_attributes(payment_agent_revision_status: Revisioner::REVISION_NOT_FOUND)
              when "payment_transactions"
                payment_transaction.find(transaction.transaction_id)
                                  .update_attributes(payment_agent_revision_status: Revisioner::REVISION_NOT_FOUND)
              end
            elsif transaction.id.present? && transaction.transaction_id.present?
              case transaction.table_name
              when "payments"
                external_payment.find(transaction.transaction_id)
                                .update_attributes(payment_agent_revision_status: Revisioner::REVISION_DIFFERENCE)
              when "payment_transactions"
                payment_transaction.find(transaction.transaction_id)
                                .update_attributes(payment_agent_revision_status: Revisioner::REVISION_DIFFERENCE)
              end
            end
          end

          rev.save
          return true
        else
          Log.error("#{filename}. Не удалось создать сверку с источниками денег: не удалось получить данные из файла", component: Components::PAYMENT_AGENT_REVISION)
          return false
        end

      end

    end

  end
end