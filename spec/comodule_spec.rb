# coding:utf-8

require 'spec_helper'

describe Comodule do
  it 'should have a version number' do
    Comodule::VERSION.should_not be_nil
  end
end
