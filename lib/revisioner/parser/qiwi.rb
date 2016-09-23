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
      def revision_from_file(filepath, date_min, date_max) #Создание сверки
        data = []
        CSV.foreach(filepath, encoding: encoding, col_sep: ';', skip_blanks: true, headers: true, skip_lines: /^[^;]*$/) do |row|
          hash = row.to_h

          if (hash["Комментарий"] || '').strip == QIWI_COMMENT
            data << Revisioner::AgentTransaction.new({
                                  :agent_code => Revisioner::Parser::AGENT_QIWI,
                                  :agent_id => hash["ID счета"],
                                  :amount => hash["Сумма счета"].to_i,
                                  :date => Time.parse(hash["Дата выставления"]),
                                  :pc_payment_id => hash["ID счета"],
                                  :status => hash["Статус"]})
            date_min = [date_min, Time.parse(hash["Дата выставления"])].min
            date_max = [date_max, Time.parse(hash["Дата выставления"])].max
          end
        end

        return [data, date_max, date_min]
      end

    end

  end
end