#encoding: utf-8
# @author: Anton Shisnkin, Yuriy Soshin
class Revisioner::Parsers::Webmoney
  HEADERS = []
  # HEADERS = [ "Дата и время перевода",
  #            "Номер перевода",
  #            "Дата перевода",
  #            "Сумма перевода",
  #            "Вознаграждение НКО",
  #            "КФЛ",
  #            "Оператор Связи",
  #            "Идентификатор плательщика",
  #            "Назначение"
  #

  def self.revision_from_file(filepath, filename) #Создание сверки
      data = []
      date_min = Time.now
      date_max = Time.parse("2001-01-01")

      encodings = EncodingSampler::Sampler.new(filepath, ['UTF-8']).valid_encodings
      encoding = nil
      encoding = 'windows-1251:utf-8' unless encodings.include? 'UTF-8'

      begin
        CSV.foreach(filepath, encoding: encoding, col_sep: ';', skip_blanks: true, headers: false, skip_lines: /^[^;]*$/) do |row|

          if (row[10] || '').strip == WEBMONEY_COMMENT
            data << {
                      :agent_code => AGENT_WEBMONEY,
                      :agent_id => row[0],
                      :amount => row[3].to_i,
                      :date => Time.parse(row[1]),
                      :pc_payment_id => row[2]
                    }
            date_min = [date_min, Time.parse(row[1])].min
            date_max = [date_max, Time.parse(row[1])].max
          end

        end
      rescue Exception => e
        Log.error("#{filename}. Не удалось создать сверку с источниками денег: %s: %s" % [e.class, e.message], component: Components::PAYMENT_AGENT_REVISION)
        return false
      end

      if !data.empty?
        rev = External::PaymentAgentRevision.create(:agent_code => data[0][:agent_code],
                                                    :date_start => date_min.beginning_of_day,
                                                    :date_end => date_max.end_of_day)
        rev.payment_agent_transactions.create(data)

        revision_result = rev.get_differences

        case rev.count = revision_result.count
          when 0
            rev.status = REVISION_SUCCESS
          else
            rev.status = REVISION_FAILURE
        end


        agent = "ebmoney"


        External::Payment.where("external_payment_time BETWEEN ? AND ?", rev.date_start, rev.date_end)
                         .where("payment_system LIKE '%#{agent}%'")
                         .update_all(payment_agent_revision_status: PaymentTransaction::PAYMENT_AGENT_REVISION_SUCCESS)

        PaymentTransaction.where("payment_time BETWEEN ? AND ?", rev.date_start, rev.date_end)
                          .where("payment_system LIKE '%#{agent}%'")
                          .update_all(payment_agent_revision_status: PaymentTransaction::PAYMENT_AGENT_REVISION_SUCCESS)

        revision_result.each do |transaction|
          if transaction.id.blank? && transaction.transaction_id.present?
            case transaction.table_name
            when "payments"
              External::Payment.find(transaction.transaction_id)
                               .update_attributes(payment_agent_revision_status: PaymentTransaction::PAYMENT_AGENT_REVISION_NOT_FOUND)
            when "payment_transactions"
              PaymentTransaction.find(transaction.transaction_id)
                                .update_attributes(payment_agent_revision_status: PaymentTransaction::PAYMENT_AGENT_REVISION_NOT_FOUND)
            end
          elsif transaction.id.present? && transaction.transaction_id.present?
            case transaction.table_name
            when "payments"
              External::Payment.find(transaction.transaction_id)
                               .update_attributes(payment_agent_revision_status: PaymentTransaction::PAYMENT_AGENT_REVISION_DIFFERENCE)
            when "payment_transactions"
              PaymentTransaction.find(transaction.transaction_id)
                                .update_attributes(payment_agent_revision_status: PaymentTransaction::PAYMENT_AGENT_REVISION_DIFFERENCE)
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
             ]
end