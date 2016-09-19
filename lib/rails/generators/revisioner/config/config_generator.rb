# encoding: utf-8
# @author Anton Shishkin
# generates default config and required migrations

module Revisioner
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc 'Creates a Revisioner gem configuration file at config/revisioner.yml'
      def self.source_root
        @_sugarcrm_source_root ||= File.expand_path("../templates", __FILE__)
      end

      def create_config_file
        template 'revisioner.yml', File.join('config', 'revisioner.yml')
      end

      def copy_migrations
        copy_migration "create_agent_transactions"
        copy_migration "create_agent_revisions"
      end

      # error fix
      def self.next_migration_number(dir)
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        @@previous_timestamp ||= timestamp.to_i

        timestamp = timestamp.to_i + 1 while @@previous_timestamp >= timestamp

        @@previous_timestamp = timestamp.to_i

        timestamp.to_s
      end

    protected

      def copy_migration(filename)
        if self.class.migration_exists?("db/migrate", "#{filename}")
          say_status("skipped", "Migration #{filename}.rb already exists")
        else
          migration_template "migrations/#{filename}.rb", "db/migrate/#{filename}.rb"
        end
      end

    end
  end
end
