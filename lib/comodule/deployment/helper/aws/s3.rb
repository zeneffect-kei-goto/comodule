module Comodule::Deployment::Helper::Aws::S3

  def self.included(receiver)
    receiver.send :include, InstanceMethods
  end

  module InstanceMethods
    def s3
      @s3 ||= ::Comodule::Deployment::Helper::Aws::S3::Service.new(self)
    end
  end

  class Service
    include ::Comodule::Deployment::Helper::Aws::Base

    def s3
      @s3 ||= aws.s3
    end

    def bucket_name
      @bucket_name ||= config.s3_bucket
    end

    def bucket
      return @bucket if @bucket

      bucket = s3.buckets[bucket_name]
      @bucket =
        if bucket.exists?
          bucket
        else
          s3.buckets.create(bucket_name)
        end
    end
  end
end
