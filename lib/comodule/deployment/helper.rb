require 'aws-sdk'

module Comodule::Deployment::Helper
  def yaml_to_config(path)
    ::Comodule::ConfigSupport::Config.new(
      YAML.load(
        File.read(path)
      )
    )
  end

  def be_dir(dir)
    FileUtils.mkdir_p dir unless File.directory?(dir)
    dir
  end

  class AwsSdk
    def initialize(iam_config)
      @aws_sdk_object = {}
      @iam_config = iam_config
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
        iam = @iam_config[:common] || @iam_config[method_name]
        if iam
          iam_hsh = iam.to_hash
          @aws_sdk_object[method_name] = @method_map[method_name].new(iam_hsh)
          return @aws_sdk_object[method_name]
        end
        raise ArgumentError, "Comodule::Deployment::AwsSdk##{method_name} was missing IAM."
      end
      raise ArgumentError, "Comodule::Deployment::AwsSdk was missing AWS class."
    end
  end
end
