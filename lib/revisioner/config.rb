class Revisioner::Config
  # True global settings which you can use as:
  # Settings.pc_payment_api
  #  => {"namespace"=>"http://pc.tprs.ru/api/processing", "endpoint"=>"https://demoapi.tprs.ru/processing", "cert"=>"./config/certs/dev/pc.crt", "key"=>"./config/certs/dev/pc.nopass.key", "ca_cert"=>"./config/certs/dev/pc.ca.crt"}

  @app_config_file = if File.file?("#{Rails.root}/config/revisioner.yml")
    "#{Rails.root}/config/revisioner.yml"
  else
    "/home/antonio/git/revisioner/lib/rails/generators/revisioner/config/templates/revisioner.yml"
  end

  @app_config = YAML.load_file(@app_config_file).with_indifferent_access


  @app_config.each_key do |m|
    define_singleton_method(m.to_sym) do
      if @app_config[m].is_a? Hash
        @app_config[m].with_indifferent_access
      else
        @app_config[m]
      end
    end
  end

  def self.[](path)
    raise_error = false
    names = if path.is_a? String
              raise_error = path.end_with? '!'
              path = path[0..-2] if raise_error
              path.split('.').map {|p| p.to_sym}
            else
              [path.to_sym]
            end

    result = @app_config
    names.each {|name| result = result.fetch(name)}

    raise Error, "Undefined configuration parameter: #{path}" if result.nil? && raise_error

    result
  rescue KeyError
    raise Error, "Undefined configuration parameter: #{path}" if raise_error
    nil
  end

end