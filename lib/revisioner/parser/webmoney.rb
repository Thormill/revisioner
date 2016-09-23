#encoding: utf-8
# @author: Anton Shisnkin, Yuriy Soshin
module Revisioner::Parser
  class Webmoney
  #   HEADERS = []
  #   # HEADERS = [ "Дата и время перевода",
  #   #            "Номер перевода",
  #   #            "Дата перевода",
  #   #            "Сумма перевода",
  #   #            "Вознаграждение НКО",
  #   #            "КФЛ",
  #   #            "Оператор Связи",
  #   #            "Идентификатор плательщика",
  #   #            "Назначение"
  #   #

    class << self
      def revision_from_file(filepath, date_min, date_max) #Создание сверки
        data = []

        CSV.foreach(filepath, encoding: encoding, col_sep: ';', skip_blanks: true, headers: false, skip_lines: /^[^;]*$/) do |row|
          if (row[10] || '').strip == Revisioner::Parser::WEBMONEY_COMMENT
            data << {
                      :agent_code => Revisioner::Parser::AGENT_WEBMONEY,
                      :agent_id => row[0],
                      :amount => row[3].to_i,
                      :date => Time.parse(row[1]),
                      :pc_payment_id => row[2]
                    }
            date_min = [date_min, Time.parse(row[1])].min
            date_max = [date_max, Time.parse(row[1])].max
          end
        end

        return [data, date_max, date_min]
      end
    end
  end
end