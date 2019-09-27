require "startandkonnect/version"
require "aws-sdk"

module Startandkonnect
  #class Error < StandardError; end
  
  class AWS

    def initialize(in_region)
      config_file = File.join(File.dirname(File.expand_path(__FILE__)), %w( .. config aws_config.yml))
      if File.exists?(config_file)
        @@aws_config = YAML.load_file(config_file)
        access_key = @@aws_config["AWS_ACCESS_KEY_ID"]
        secret_key = @@aws_config['AWS_SECRET_ACCESS_KEY']
        region = @@aws_config['AWS_REGION']
      elsif (ENV["AWS_ACCESS_KEY_ID"] && ENV["AWS_SECRET_ACCESS_KEY"])
        access_key = ENV["AWS_ACCESS_KEY_ID"]
        secret_key = ENV["AWS_SECRET_ACCESS_KEY"]
        region = ENV['AWS_REGION']
      else
        raise "AWS credentials not found!"
      end
      region = in_region unless in_region.nil?

      credentials = Aws.config[:credentials] = Aws::Credentials.new(access_key, secret_key)
      @client = Aws::EC2::Client.new(region: region, credentials: credentials)
      @ec2 = Aws::EC2::Resource.new(region: region, credentials: credentials)
    end

    def search_instances(query)
      resp = @client.describe_instances({filters: [{name: "tag:Name", values: query}]})
    end

    def start_instance(instance_id)
      i = @ec2.instance(instance_id)
      if i.exists?
        case i.state.code
        when 0  # pending
          r = "#{instance_id} is pending, so it will be running in a bit"
        when 16  # started
          r = "#{instance_id} is already started"
        when 48  # terminated
          r = "#{instance_id} is terminated, so you cannot start it"
        else
          i.start
          while i.state.code != 16
            i = @ec2.instance(instance_id)
            sleep 1
          end
          r = "#{instance_id} is started"
        end
      else
        r = "#{instance_id} does not exist!"
      end
      return r
    end

    def stop_instance(instance_id)
      i = @ec2.instance(instance_id)
      if i.exists?
        case i.state.code
        when 48  # terminated
          r = "#{instance_id} is terminated, so you cannot stop it"
        when 64  # stopping
          r = "#{instance_id} is stopping, so it will be stopped in a bit"
        when 80  # stopped
          r = "#{instance_id} is already stopped"
        else
          i.stop
           while i.state.code != 80
            i = @ec2.instance(instance_id)
            sleep 1
          end
          r = "#{instance_id} is stopped"
        end
      else
        r = "#{instance_id} does not exist!"
      end
      return r
    end

  end

  class SSH 

    def connect(server)
      `ssh -i ~/Documents/kali_perso.pem ec2-user@#{server}`
    end
  end
end
