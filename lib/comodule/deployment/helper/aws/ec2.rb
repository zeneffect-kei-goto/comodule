module Comodule::Deployment::Helper::Aws::Ec2

  def self.included(receiver)
    receiver.send :include, InstanceMethods
  end

  module InstanceMethods
    def ec2
      @ec2 ||= ::Comodule::Deployment::Helper::Aws::Ec2::Service.new(self)
    end
  end

  class Service
    include ::Comodule::Deployment::Helper::Aws::Base

    def ec2
      @ec2 ||= aws.ec2
    end

    def own_images
      ec2.images.with_owner('self')
    end

    def latest_ami
      images = own_images
      if config.ec2 && config.ec2.ami && config.ec2.ami.prefix
        images = images.find_all { |ami| ami.name =~ /^#{config.ec2.ami.prefix}/ }

        filter = -> ami { ami.name.match(/[0-9]*$/)[0].to_i }
        images = images.sort do |a, b|
          filter[b] <=> filter[a]
        end
      end
      images.first
    end
  end
end
