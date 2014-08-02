require "comodule/version"
require "rails"

module Comodule
  autoload :UniArray,       'comodule/uni_array'
  autoload :ConfigSupport,  'comodule/config_support'
  autoload :CustomizeClass, 'comodule/customize_class'
  autoload :Deployment,     'comodule/deployment'

  module CustomizeClass
    autoload :StringCustom, 'comodule/customize_class/string_custom'
  end

  module Deployment
    autoload :Base,     'comodule/deployment/base'
    autoload :Platform, 'comodule/deployment/platform'
    autoload :Helper,   'comodule/deployment/helper'

    module Helper
      autoload :Base,          'comodule/deployment/helper/base'
      autoload :SystemUtility, 'comodule/deployment/helper/system_utility'
      autoload :Aws,           'comodule/deployment/helper/aws'

      module Aws
        autoload :Base, 'comodule/deployment/helper/aws/base'
        autoload :Sdk,  'comodule/deployment/helper/aws/sdk'
      end
    end
  end
end
