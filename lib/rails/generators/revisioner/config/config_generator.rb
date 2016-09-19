# encoding: utf-8

module Revisioner
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc 'Creates a Revisioner gem configuration file at config/revisioner.yml'

      def self.source_root
        @_sugarcrm_source_root ||= File.expand_path("../templates", __FILE__)
      end

      def create_config_file
        template 'revisioner.yml', File.join('config', 'revisioner.yml')
      end

      # def create_initializer_file
      #   template 'initializer.rb', File.join('config', 'initializers', 'revisioner.rb')
      # end
    end
  end
end
