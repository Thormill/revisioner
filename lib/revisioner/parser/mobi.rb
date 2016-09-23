#encoding: utf-8
# @author: Anton Shisnkin, Yuriy Soshin
module Revisioner::Parser
  class Mobi
    HEADERS = [ "Дата и время перевода",
               "Номер перевода",
               "Дата перевода",
               "Сумма перевода",
               "Вознаграждение НКО",
               "КФЛ",
               "Оператор Связи",
               "Идентификатор плательщика",
               "Назначение"
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
          xlsx = Roo::Spreadsheet.open(filepath, extension: filename.split('.')[-1].to_sym)
          sheet = xlsx.sheet(0)
          mobi_data = sheet.parse(header_search: MOBI_HEADERS, clean: true)
          mobi_data.each do |hash|
            if hash["Дата и время перевода"].is_a?(Date)
              date = hash["Дата и время перевода"].to_time.localtime - 3.hours
              data << {
                        :agent_code => AGENT_MOBI,
                        :agent_id => hash["Номер перевода"],
                        :amount => hash["Сумма перевода"].to_i,
                        :date => date
                      }
              date_min = [date_min, date].min
              date_max = [date_max, date].max
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


          agent = "mobi"
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
