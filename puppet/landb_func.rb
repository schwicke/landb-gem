module Puppet::Parser::Functions
  newfunction(:landb_func, :type => :rvalue, :doc => "A puppet funtion to integrate with LanDB") do |args|

    require 'rubygems'
    require 'yaml'
    require 'landb'

    option_hash = args[0]

    config = begin
      YAML.load(File.open("/etc/puppet/landb_config.yml"))
    rescue ArgumentError => e
      puts "Could not parse YAML: #{e.message}"
    end

    LandbClient.set_config(config)
    client = LandbClient.instance

    client_method = client.method option_hash["method"].to_sym

    responce = client_method.call option_hash["method_arguments"]

    if option_hash["responce_info"].first.instance_of?(Array)
      responce = responce.get_values_for_paths option_hash["response_info"]
    else
      responce = responce.get_value_for_path option_hash["response_info"]
    end

    responce
  end
end