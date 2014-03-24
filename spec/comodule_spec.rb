require 'spec_helper'

describe Comodule do
  it 'should have a version number' do
    Comodule::VERSION.should_not be_nil
  end

  it 'should do something useful' do
    false.should eq(true)
  end
end
