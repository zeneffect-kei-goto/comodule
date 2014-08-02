module Comodule::Deployment::Helper

  def self.included(receiver)
    receiver.send :include, SystemUtility, Aws
  end
end
