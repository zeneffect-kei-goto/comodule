module Comodule::Deployment::Helper::Base

  def self.included(receiver)
    receiver.send :include, InstanceMethods
    receiver.send :attr_accessor, :owner
  end

  module InstanceMethods

    def initialize(platform)
      self.owner = platform
    end

    def config
      owner.config
    end
  end
end
