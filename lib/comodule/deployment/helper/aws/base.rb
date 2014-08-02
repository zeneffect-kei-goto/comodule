module Comodule::Deployment::Helper::Aws::Base

  def self.included(receiver)
    receiver.send :include, ::Comodule::Deployment::Helper::Base
    receiver.send :include, InstanceMethods
  end

  module InstanceMethods

    def aws
      owner.aws
    end
  end
end
