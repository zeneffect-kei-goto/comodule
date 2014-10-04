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

      bucket_obj = s3.buckets[bucket_name]
      @bucket =
        if bucket_obj.exists?
          bucket_obj
        else
          s3.buckets.create(bucket_name)
        end
    end

    def local_to_cloud(local_path)
      local_path.sub(%r|#{owner.project_root}/|, "#{owner.name}/")
    end

    def cloud_to_local(s3_path)
      s3_path.sub(%r|#{owner.name}/|, "#{owner.project_root}/")
    end

    def public_url(s3_path)
      s3.bucket[s3_path].public_url secure: true
    end

    def local_to_public_url(local_path)
      public_url local_to_cloud(local_path)
    end
  end
end
