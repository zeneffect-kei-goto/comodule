module Comodule::ConfigSupport
  class Config
    class << self
      def original_methods
        return @original_methods if @original_methods

        @original_methods =  public_instance_methods
        @original_methods += protected_instance_methods
        @original_methods += private_instance_methods
      end

      def combine(config1, config2)
        new_obj = new

        config1.each do |key, value|
          new_obj[key] = value
        end

        config2.each do |key, value|
          if self === new_obj[key] && self === value
            new_obj[key] = combine(new_obj[key], value)
          else
            new_obj[key] = value
          end
        end

        new_obj
      end
    end

    def initialize(config_hash={})
      config_hash[:configure_type] ||= :soft

      config_hash.each do |directive, value|
        value = value.to_sym if directive == :configure_type

        if Hash === value
          value[:configure_type] ||= config_hash[:configure_type]
          value = self.class.new(value)
        end

        set_directive directive, value
      end

      if block_given?
        yield self
      end
    end

    def method_missing(directive, arg=nil)
      if directive =~ /^(.+)=/
        set_directive($1, arg)
      else
        get_directive(directive)
      end
    end

    def [](directive)
      get_directive(directive)
    end

    def []=(directive, arg)
      set_directive(directive, arg)
    end

    def merge(other_config)
      self.class.combine(self, other_config)
    end

    alias + merge

    def each
      instance_variables.each do |variable_name|
        next if variable_name == :@configure_type

        key = variable_name.to_s.sub(/@/, '').to_sym
        value = instance_variable_get(variable_name)

        yield key, value
      end
    end

    def to_hash
      hsh = {}
      each do |key, value|
        value = value.to_hash if self.class === value
        hsh[key] = value
      end
      hsh
    end

    def slice(*keys)
      keys.inject(self.class.new) do |new_obj, key|
        new_obj[key] = self[key] if self[key]
        new_obj
      end
    end


  private

    def get_directive(directive)
      value = instance_variable_get("@#{directive}")
      if @configure_type == :hard && !value
        raise ArgumentError, "Comodule::ConfigSupport::Config is missing this directive [#{directive}]."
      end
      value
    end

    def set_directive(directive, arg)
      directive = directive.to_sym

      if self.class.original_methods.member?(directive)
        raise ArgumentError, "You cannot use the directive [#{directive}= #{arg}] same as a member of Object#methods."
      end

      arg = arg.to_sym if directive == :configure_type

      if Hash === arg
        arg[:configure_type] ||= configure_type
        arg = self.class.new(arg)
      end

      instance_variable_set("@#{directive}", arg)
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
