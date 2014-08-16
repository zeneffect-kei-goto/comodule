require 'aws-sdk'

module Comodule::Deployment::Helper::Aws

  def self.included(receiver)
    receiver.send :include, InstanceMethods, CloudFormation, S3
  end

  module InstanceMethods
    def aws
      @aws ||= ::Comodule::Deployment::Helper::Aws::Service.new(self)
    end
  end

  class Service
    include ::Comodule::Deployment::Helper::Base

    def initialize(platform)
      self.owner = platform

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

    def access_credentials
      config.aws_access_credentials || {}
    end

    def search_credential_directive(aws_resource_name, directive)
      (access_credentials[aws_resource_name] && access_credentials[aws_resource_name][directive]) ||
      (access_credentials[:common] && access_credentials[:common][directive]) ||
      access_credentials[directive] ||
      config["aws_#{directive}".to_sym]
    end

    def access_key_id(aws_resource_name)
      search_credential_directive(aws_resource_name, :access_key_id)
    end

    def secret_access_key(aws_resource_name)
      search_credential_directive(aws_resource_name, :secret_access_key)
    end

    def region(aws_resource_name)
      search_credential_directive(aws_resource_name, :region)
    end

    def validate_credential(aws_resource_name, iam)
      case aws_resource_name
      when :cloud_formation, :rds, :auto_scaling
        if !iam || !iam[:region]
          raise ArgumentError, "Please specify aws_access_credentials.#{aws_resource_name}.region on your config.yml."
        end
      when :cloud_front, :s3
        iam.delete(:region)
      end

      iam
    end

    def method_missing(method_name)
      if @method_map[method_name]
        return @aws_sdk_object[method_name] if @aws_sdk_object[method_name]

        iam = {}

        key_id = access_key_id(method_name)
        secret = secret_access_key(method_name)
        region = region(method_name)
        iam[:access_key_id] = key_id if key_id
        iam[:secret_access_key] = secret if secret
        iam[:region] = region if region && region.present?

        iam = (@access_credentials[method_name] || @access_credentials[:common] || {}).to_hash.merge(iam)

        validate_credential(method_name, iam)
        if !iam.empty?
          @aws_sdk_object[method_name] = @method_map[method_name].new(iam)
        else
          @aws_sdk_object[method_name] = @method_map[method_name].new
        end

        return @aws_sdk_object[method_name]
      end

      raise ArgumentError, "#{self.class.name} was missing AWS class #{method_name}."
    end
  end
end
