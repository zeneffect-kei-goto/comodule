require 'spec_helper'

describe Comodule::UniArray do
  it 'UniArray has only unique value' do
    arr = Comodule::UniArray.new
    arr << "a"
    arr << "b"
    arr << "a"
    arr << "c"
    arr << "a" << "b" << "c"
    expect(arr.size).to eq(3)
    expect(arr).to eq(["a", "b", "c"])
  end

  it '#max_size' do
    arr = Comodule::UniArray.new
    arr.max_size = 5
    arr << 1
    arr << 2
    arr << 3

    arr << 1
    arr << 2
    arr << 3

    arr << 4
    arr << 5
    arr << 6

    arr << 4
    arr << 5
    arr << 6

    arr << 7 << 8 << 9 << 10

    expect(arr.size).to eq(5)
    expect(arr).to eq([6, 7, 8, 9, 10])
  end
end
