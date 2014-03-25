require 'spec_helper'

describe Comodule::ConfigSupport do
  context '::Config.new' do
    it 'useful configure object' do
      config = Comodule::ConfigSupport::Config.new(
        host: 'example.com',
        port: '3000',
        ip: '10.0.0.100'
      )
      expect(config.host).to eq('example.com')
      expect(config.port).to eq('3000')
      expect(config.ip).to eq('10.0.0.100')
    end

    it 'Undefined is nil at default' do
      config = Comodule::ConfigSupport::Config.new(
        host: 'example.com',
        port: '3000',
        ip: '10.0.0.100'
      )
      expect(config.nothing).to eq(nil)
    end

    it 'Undefined raises error when specify configure_type to :hard' do
      config = Comodule::ConfigSupport::Config.new(
        configure_type: :hard,
        host: 'example.com',
        port: '3000',
        ip: '10.0.0.100'
      )
      expect{config.nothing}.to raise_error(ArgumentError)
    end
  end

  context '#create_config' do
    before do
      stub_const("SomeClass", Class.new)
      SomeClass.send :include, Comodule::ConfigSupport
    end

    it 'class configure' do
      class SomeClass
        Configure = create_config(
          max_record_size: 3000,
          update_index: 'some_class-20140325'
        )
      end
      expect(SomeClass::Configure.max_record_size).to eq(3000)
      expect(SomeClass::Configure.update_index).to eq('some_class-20140325')
    end
  end

  context '#to_hash' do
    it 'not include :cofigure_type' do
      config = Comodule::ConfigSupport::Config.new(
        configure_type: :hard,
        host: 'example.com',
        port: '3000',
        ip: '10.0.0.100'
      )
      expect(config.to_hash).to eq({
        host: 'example.com',
        port: '3000',
        ip: '10.0.0.100'
      })
    end
  end
end
