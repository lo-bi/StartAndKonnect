require "startandkonnect/version"
require "aws-sdk"

module Startandkonnect
  #class Error < StandardError; end
  
  class AWS

    def initialize(region)
      config_file = File.join(File.dirname(File.expand_path(__FILE__)), %w( .. config aws_config.yml))
      if File.exists?(config_file)
        @@aws_config = YAML.load_file(config_file)
        access_key = @@aws_config["AWS_ACCESS_KEY_ID"]
        secret_key = @@aws_config['AWS_SECRET_ACCESS_KEY']
      elsif (ENV["AWS_ACCESS_KEY_ID"] && ENV["AWS_SECRET_ACCESS_KEY"])
        access_key = ENV["AWS_ACCESS_KEY_ID"]
        secret_key = ENV["AWS_SECRET_ACCESS_KEY"]
      else
        raise "AWS credentials not found!"
      end
      credentials = Aws.config[:credentials] = Aws::Credentials.new(access_key, secret_key)
      @client = Aws::EC2::Client.new(region: region, credentials: credentials)
    end

    def search_instances(query)
      resp = @client.describe_instances({filters: [{name: "tag:Name", values: query}]})
    end

  end
end
