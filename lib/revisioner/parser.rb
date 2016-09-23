# @author Anton Shishkin
# abstract class for report file parsing

require "revisioner/parser/qiwi"
require "revisioner/parser/yandex"
require "revisioner/parser/mobi"

class Revisioner::Parser
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
    # def self.define_agent(filepath, filename)
    #   agent_kind = nil

    #   encodings = EncodingSampler::Sampler.new(filepath, ['UTF-8']).valid_encodings
    #   encoding = nil
    #   encoding = 'windows-1251:utf-8' unless encodings.include? 'UTF-8'

    #   if /\.xls/ =~ filename
    #     xlsx = Roo::Spreadsheet.open(filepath, extension: filename.split('.')[-1].to_sym)
    #     sheet = xlsx.sheet(0)

    #     sheet.each do |row|
    #       row = row.inject([]) { |h, v| h << v.strip unless v.blank?; h}
    #       if MOBI_HEADERS == row
    #         agent_kind = AGENT_MOBI
    #         break
    #       end
    #     end

    #   else
    #     csv_data = CSV.read(filepath, encoding: encoding, col_sep: ';', skip_blanks: true, headers: false, skip_lines: /^[^;]*$/)

    #     first_row = csv_data[0].inject([]) { |h, v| h << v.strip unless v.blank?; h}

    #     if YANDEX_HEADERS == first_row
    #       agent_kind = AGENT_YANDEX
    #     elsif WEBMONEY_CHECK["value"] == first_row[WEBMONEY_CHECK["position"]]
    #       agent_kind = AGENT_WEBMONEY
    #     elsif QIWI_HEADERS == first_row
    #       agent_kind = AGENT_QIWI
    #     elsif first_row.count < 5
    #       agent_kind = AGENT_MOBI_NEW
    #     end
    #   end

    #   return agent_kind
    # end
  end
end