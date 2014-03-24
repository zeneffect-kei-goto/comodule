# coding:utf-8

require 'spec_helper'

Comodule::CustomizeClass.customize

describe Comodule do
  it 'should have a version number' do
    Comodule::VERSION.should_not be_nil
  end

  describe Comodule::ConfigSupport do
    it 'useful configure object' do
      config = Comodule::ConfigSupport::Config.new(
        host: 'example.com',
        ip: '10.0.0.1'
      )
      expect(config.host).to eq('example.com')
      expect(config.ip).to eq('10.0.0.1')
    end
  end

  describe Comodule::UniArray do
    it 'UniArray has only unique value' do
      arr = Comodule::UniArray.new
      arr << "a"
      arr << "b"
      arr << "a"
      arr << "c"
      arr << "a" << "b" << "c"
      expect(arr.size).to eq(3)
      expect(arr[0]).to eq("a")
      expect(arr[1]).to eq("b")
      expect(arr[2]).to eq("c")
    end
  end

  describe Comodule::CustomizeClass do
    it 'extended Hash Class' do
      hsh = {a: "A", b: "B", c: "C"}
      expect(hsh.pullout(:a, :c)).to eq({a: "A", c: "C"})
    end

    it 'extended String Class' do
      str = "ＡＢCD12３４５"
      expect(str.standardize).to eq('ABCD12345')
    end
  end
end
