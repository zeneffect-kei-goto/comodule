require "comodule/version"
require "rails"

module Comodule
  autoload :UniArray,       'comodule/uni_array'
  autoload :ConfigSupport,  'comodule/config_support'
  autoload :CustomizeClass, 'comodule/customize_class'
  autoload :Deployment,     'comodule/deployment'

  module CustomizeClass
    autoload :HashCustom,   'comodule/customize_class/hash_custom'
    autoload :StringCustom, 'comodule/customize_class/string_custom'
  end

  module Deployment
    autoload :Platform, 'comodule/deployment/platform'
    autoload :Helper,   'comodule/deployment/helper'
  end
end
