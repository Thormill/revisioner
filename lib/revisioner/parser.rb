# @author Anton Shishkin
# abstract class for report file parsing

require "revisioner/parser/qiwi"
require "revisioner/parser/yandex"
require "revisioner/parser/mobi"

module Revisioner
  module Parser
    AGENT_QIWI = 1
    AGENT_WEBMONEY = 2
    AGENT_MOBI = 3
    AGENT_YANDEX = 4
    AGENT_MOBI_NEW = 5

    REVISION_SUCCESS = 1
    REVISION_FAILURE = 2

    STATUS_QIWI = "Оплачен"

    QIWI_COMMENT = "Тройка"
    WEBMONEY_COMMENT = "Оплата карт"



    WEBMONEY_CHECK = {
                        "value"    => "WebMoney",
                        "position" => 7,
                      }


    class << self
      def get_agent(type) # private
        agent = case type
        when "qiwi"
          Qiwi
        when "wbm"
          Webmoney
        when AGENT_MOBI
          Mobi
        when "yandex"
          Yandex
        when "new_mobi"
          Mobi #TODO new mobi?
        end

        agent
      end


      def define_agent(filepath)
        agent_kind = nil
        filename = filepath.split("/").last

        encodings = EncodingSampler::Sampler.new(filepath, ['UTF-8']).valid_encodings
        encoding = nil
        encoding = 'windows-1251:utf-8' unless encodings.include? 'UTF-8'

        if /\.xls/ =~ filename
          xlsx = Roo::Spreadsheet.open(filepath, extension: filename.split('.')[-1].to_sym)
          sheet = xlsx.sheet(0)

          sheet.each do |row|
            row = row.inject([]) { |h, v| h << v.strip unless v.blank?; h}
            if Mobi::HEADERS == row
              agent_kind = AGENT_MOBI
              break
            end
          end

        else
          csv_data = CSV.read(filepath, encoding: encoding, col_sep: ';', skip_blanks: true, headers: false, skip_lines: /^[^;]*$/)

          first_row = csv_data[0].inject([]) { |h, v| h << v.strip unless v.blank?; h}

          agent_kind = case first_row
          when Yandex::HEADERS
            "yandex"
            # AGENT_YANDEX
          when Qiwi::HEADERS
            "qiwi"
            # AGENT_QIWI
          else
            if WEBMONEY_CHECK["value"] == first_row[WEBMONEY_CHECK["position"]]
              "wbm"
              # AGENT_WEBMONEY
            elsif first_row.count < 5 #TODO constant me!
              "new_mobi"
              # AGENT_MOBI_NEW
            end
          end
        end

        return agent_kind
      end

      def read_file(filepath)
        agent = define_agent(filepath) # мб сразу возвращать класс обработчика
        parser_class = get_agent(agent)


        data = []
        date_min = Time.now
        date_max = Time.parse("2001-01-01")

        encodings = EncodingSampler::Sampler.new(filepath, ['UTF-8']).valid_encodings
        encoding = nil
        encoding = 'windows-1251:utf-8' unless encodings.include? 'UTF-8'

        data = begin
          parser_class.send(:revision_from_file, filepath, date_min, date_max)
        rescue Exception => e
          Log.error("#{filepath.split('/').last}. Не удалось создать сверку с источниками денег: %s: %s\n\n%s" % [e.class, e.message, e.backtrace], component: Components::PAYMENT_AGENT_REVISION)
          return false
        end

        if !data.empty?
          rev = Revisioner::AgentRevision.create(:agent_code => data[0][:agent_code],
                                    :date_start => date_min.beginning_of_day,
                                    :date_end => date_max.end_of_day)
          rev.payment_agent_transactions.create(data)

          revision_result = rev.get_differences

          rev.status = case rev.count = revision_result.count
          when 0
            Revisioner::REVISION_SUCCESS
          else
            Revisioner::REVISION_FAILURE
          end


          # agent = "qiwi"
          external_payment = Revisioner::Config[:external_payment_name].constantize
          payment_transaction = Revisioner::Config[:payment_transaction_name].constantize

          external_payment.where("external_payment_time BETWEEN ? AND ?", rev.date_start, rev.date_end)
                           .where("payment_system LIKE '%#{agent}%'")
                           .update_all(payment_agent_revision_status: Revisioner::REVISION_SUCCESS)

          payment_transaction.where("payment_time BETWEEN ? AND ?", rev.date_start, rev.date_end)
                            .where("payment_system LIKE '%#{agent}%'")
                            .update_all(payment_agent_revision_status: Revisioner::REVISION_SUCCESS)

          revision_result.each do |transaction|
            if transaction.id.blank? && transaction.transaction_id.present?
              case transaction.class_name
              when external_payment
                external_payment.find(transaction.transaction_id)
                                 .update_attributes(payment_agent_revision_status: Revisioner::REVISION_NOT_FOUND)
              when payment_transaction
                payment_transaction.find(transaction.transaction_id)
                                  .update_attributes(payment_agent_revision_status: Revisioner::REVISION_NOT_FOUND)
              end
            elsif transaction.id.present? && transaction.transaction_id.present?
              case transaction.class_name
              when external_payment
                external_payment.find(transaction.transaction_id)
                                .update_attributes(payment_agent_revision_status: Revisioner::REVISION_DIFFERENCE)
              when payment_transaction
                payment_transaction.find(transaction.transaction_id)
                                .update_attributes(payment_agent_revision_status: Revisioner::REVISION_DIFFERENCE)
              end
            end
          end

          rev.save
          return true
        else
          Log.error("#{filepath.split('/').last}. Не удалось создать сверку с источниками денег: не удалось получить данные из файла", component: Components::PAYMENT_AGENT_REVISION)
          return false
        end

      end

      def get_file(filepath)
        agent = define_agent(filepath) # мб сразу возвращать класс обработчика
        parser_class = get_agent(agent)

        parser_class.send(:download_file, filepath)
      end

    end
  end
end