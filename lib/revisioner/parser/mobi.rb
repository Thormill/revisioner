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
      def revision_from_file(filepath, date_min, date_max) #Создание сверки
        data = []

        filename = filepath.split('/').last
        xlsx = Roo::Spreadsheet.open(filepath, extension: filename.split('.')[-1].to_sym)
        sheet = xlsx.sheet(0)
        mobi_data = sheet.parse(header_search: HEADERS, clean: true)

        mobi_data.each do |hash|
          if hash["Дата и время перевода"].is_a?(Date)
            date = hash["Дата и время перевода"].to_time.localtime - 3.hours
            data << {
                      :agent_code => Revisioner::Parser::AGENT_MOBI,
                      :agent_id => hash["Номер перевода"],
                      :amount => hash["Сумма перевода"].to_i,
                      :date => date
                    }
            date_min = [date_min, date].min
            date_max = [date_max, date].max
          end
        end

        return [data, date_max, date_min]
      end

    end
  end
end
