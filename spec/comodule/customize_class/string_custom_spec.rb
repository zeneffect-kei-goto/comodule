# coding:utf-8

require 'spec_helper'


describe Comodule::CustomizeClass::StringCustom do
  context '#standardize' do
    it 'converts alphanumeric to singlebyte charactors' do
      txt = "Ｒuｂｙ　２．０.1−ｐ451 ½"
      expect(txt.standardize).to eq("Ruby 2.0.1-p451 ½")
    end

    it 'support hankaku' do
      txt = 'ﾄﾞﾎﾞｳﾌﾞｼﾋﾞﾃﾍﾞｶﾊﾞﾅｰﾊﾞ'
      expect(txt.standardize).to eq("ドボウブシビテベカバナーバ")
    end
  end

  context '#to_token' do
    it 'convert spaces to wildcards' do
      txt = "株　 山 　のり"
      expect(txt.to_token).to eq("株%山%のり%")
    end

    it 'partial match' do
      txt = "株　 山 　のり"
      expect(txt.to_token(prefix: ?%)).to eq("%株%山%のり%")
    end
  end

  context '#digitalize' do
    it 'become string into only digit' do
      tel = "01-2345-6789"
      expect(tel.digitalize).to eq('0123456789')
    end

    it 'support multi byte charactors' do
      tel = "０１−２３４５−６７８９"
      expect(tel.digitalize).to eq('0123456789')
    end
  end
end 
