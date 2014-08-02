require 'aws-sdk'

module Comodule::Deployment::Helper::Aws

  def self.included(receiver)
    receiver.send :include, Service, CloudFormation
  end

  module Service

    def self.included(receiver)
      receiver.send :include, InstanceMethods
    end

    module InstanceMethods

      def aws
        @aws ||= ::Comodule::Deployment::Helper::Aws::Sdk.new(self)
      end
    end
  end

  def self.validate_credential(aws_resource_name, iam)
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
end
