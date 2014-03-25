require 'spec_helper'


describe Comodule::CustomizeClass::HashCustom do
  context '#pullout' do
    it 'create new hash with selected attributes' do
      hsh = {
        date: "20130322",
        title: "The Tell-Tale Brain",
        secret_token: "it-is-secret"
      }
      expect(hsh.pullout(:date, :title)).to eq({
        date: "20130322",
        title: "The Tell-Tale Brain"
      })
    end
  end

  context '#pullout!' do
    it 'raise error when access a missing attribute' do
      hsh = {
        date: "20130322",
        title: "The Tell-Tale Brain",
        secret_token: "it-is-secret"
      }
      expect{hsh.pullout!(:date, :author)}.to raise_error(
        ArgumentError,
        /cannot find key 'author' is a Symbol/
      )
    end
  end
end
