module Comodule::ConfigSupport
  class Config
    def initialize(config_hash={})
      config_hash[:configure_type] ||= :soft
      config_hash.each do |directive, value|
        value = value.to_sym if directive == :configure_type
        if Hash === value
          value[:configure_type] ||= config_hash[:configure_type]
          value = self.class.new(value)
        end
        instance_variable_set "@#{directive}", value
      end
    end

    def method_missing(directive, arg=nil)
      if directive =~ /^(.+)=/
        arg = arg.to_sym if directive == :configure_type
        if Hash === arg
          arg[:configure_type] ||= configure_type
          arg = self.class.new(arg)
        end
        arg = self.class.new(arg) if Hash === arg
        return instance_variable_set("@#{$1}", arg)
      end
      value = instance_variable_get("@#{directive}")
      if @configure_type == :hard && !value
        raise ArgumentError, "Comodule::ConfigSupport::Config is missing this directive [#{directive}]."
      end
      value
    end

    def [](directive)
      send(directive)
    end

    def []=(directive, arg)
      send("#{directive}=", arg)
    end

    def to_hash
      hsh = {}
      instance_variables.each do |variable_name|
        next if variable_name == :@configure_type
        key = variable_name.to_s.sub(/@/, '').to_sym
        hsh[key] = instance_variable_get(variable_name)
      end
      hsh
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
    receiver.extend ClassMethods
  end
end
