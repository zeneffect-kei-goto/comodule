# coding:utf-8

module Comodule::CustomizeClass

  class CustomizeClassError < StandardError; end

module_function

  # customize_classディレクトリにあるクラスで既存のクラスを拡張する。
  # モジュールのパブリックメソッドとClassMethodsをチェックし、
  # フレームワークに影響がないように、既に存在するメソッドのオーバーライドは許可しない。
  def customize
    Dir.glob(File.expand_path('../customize_class/*', __FILE__)).each do |path|
      name = File.basename(path, "_custom.rb").classify
      mod = "Comodule::CustomizeClass::#{name}Custom".constantize
      klass = name.constantize

      # パブリックメソッドのチェック
      mod.public_instance_methods.each do |sym|
        if klass.public_method_defined? sym
          raise CustomizeClassError, "RubyまたはRailsで定義されている#{klass.name}##{sym}をオーバーライドしようとしています。"
        end
      end
      klass.send :include, mod

      # クラスメソッドのチェック
      if mod.constants.member?(:ClassMethods)
        class_methods = "#{mod.name}::ClassMethods".constantize
        class_methods.public_instance_methods.each do |sym|
          if klass.singleton_methods.member?(sym)
            raise CustomizeClassError, "RubyまたはRailsで定義されている#{klass.name}.#{sym}をオーバーライドしようとしています。"
          end
        end
        klass.extend class_methods
      end
    end
  end
end
