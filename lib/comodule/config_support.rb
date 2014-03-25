module Comodule::ConfigSupport
  class Config
    def initialize(config_hash={})
      config_hash[:configure_type] ||= :soft
      config_hash.each do |directive, value|
        instance_variable_set "@#{directive}", value
      end
    end

    def method_missing(directive, arg=nil)
      if directive =~ /^(.+)=/
        return instance_variable_set("@#{$1}", arg)
      end
      value = instance_variable_get "@#{directive}"
      if @configure_type == :hard && !value
        raise ArgumentError, "Comodule::ConfigSupport::Config is missing this directive [#{directive}]."
      end
      value
    end

    def to_hash
      instance_variables.inject({}) do |hsh, variable_name|
        key = variable_name.to_s.sub(/@/, '').to_sym
        hsh[key] = instance_variable_get(variable_name)
        hsh
      end
    end
  end


  module ClassMethods
    def create_config(config_hash={})
      Comodule::ConfigSupport::Config.new config_hash
    end

    def create_config_hard(config_hash={})
      config_hash[:configure_type] = :hard
      create_config config_hash
    end

    def create_config_soft(config_hash={})
      config_hash[:configure_type] = :soft
      create_config config_hash
    end
  end


  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end
