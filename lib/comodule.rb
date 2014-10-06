require "comodule/version"
require 'active_support/all'

module Comodule

  if defined?(Rails)
    class Railtie < Rails::Railtie
      rake_tasks { load "tasks/comodule.rake" }
    end
  end

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
      autoload :ShellCommand,  'comodule/deployment/helper/shell_command'
      autoload :Uploader,      'comodule/deployment/helper/uploader'

      module Aws
        autoload :Base,           'comodule/deployment/helper/aws/base'
        autoload :S3,             'comodule/deployment/helper/aws/s3'
        autoload :CloudFormation, 'comodule/deployment/helper/aws/cloud_formation'
        autoload :Ec2,            'comodule/deployment/helper/aws/ec2'
        autoload :Ssl,            'comodule/deployment/helper/aws/ssl'
        autoload :Rds,            'comodule/deployment/helper/aws/rds'
      end
    end
  end
end
