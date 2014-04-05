require 'aws-sdk'

module Comodule::Deployment::Helper
  def yaml_to_config(path)
    ::Comodule::ConfigSupport::Config.new(
      YAML.load( File.read(path) )
    )
  end

  def be_dir(dir)
    FileUtils.mkdir_p dir unless File.directory?(dir)
    dir
  end

  class AwsSdk
    def initialize(access_credentials=nil)
      @aws_sdk_object = {}
      @access_credentials = access_credentials || {}
      @method_map = {}
      ::AWS.constants.each do |const_name|
        const = ::AWS.const_get(const_name)
        if defined?(const.new)
          @method_map[const_name.to_s.underscore.to_sym] = const
        end
      end
    end

    def method_missing(method_name)
      if @method_map[method_name]
        return @aws_sdk_object[method_name] if @aws_sdk_object[method_name]
        iam = @access_credentials[method_name] || @access_credentials[:common]
        if iam
          iam_hsh = iam.to_hash
          @aws_sdk_object[method_name] = @method_map[method_name].new(iam_hsh)
          return @aws_sdk_object[method_name]
        end
        @aws_sdk_object[method_name] = @method_map[method_name].new
        return @aws_sdk_object[method_name]
      end
      raise ArgumentError, "Comodule::Deployment::AwsSdk was missing AWS class."
    end
  end
end
