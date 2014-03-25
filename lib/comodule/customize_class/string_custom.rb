# coding: utf-8
require 'nkf'

module Comodule::CustomizeClass::StringCustom

  def ltrim
    lstrip.sub(/^\p{Z}+/mu, '')
  end

  def ltrim!
    str = ltrim
    return nil if str == self
    replace str
    self
  end

  def rtrim
    rstrip.sub(/\p{Z}+$/mu, '')
  end

  def rtrim!
    str = rtrim
    return nil if str == self
    replace str
    self
  end

  def trim
    ltrim.rtrim
  end

  def trim!
    str = trim
    return nil if str == self
    replace str
    self
  end

  def ascii_space
    gsub(/\p{Z}/u, ?\s)
  end

  def ascii_space!
    str = ascii_space
    return nil if str == self
    replace str
    self
  end

  # 全角または半角のスペースが連続する場合は一つの半角スペースにする。
  def single_space
    trim.gsub(/\p{Z}+/u, ?\s)
  end

  def single_space!
    str = single_space
    return nil if str == self
    replace str
    self
  end

  # NKF.nkfで"½"などの文字が失われることがあるので、文字数が変化してしまったら一文字ずつの変換を行う。
  # 半角カタカナの濁点、半濁点により文字数が変化した場合も一文字ずつの処理にする。
  def standardize(_single_space=single_space)
    before = _single_space || trim.ascii_space
    after = NKF.nkf( '-Wwxm0Z0', NKF.nkf('-WwXm0', before) )
    before.size == after.size ? after : standardize_delicate(_single_space)
  end

  # 1文字ずつ変換するので、当然パフォーマンスが低い。
  def standardize_delicate(_single_space=single_space)
    str = _single_space || trim.ascii_space
    str_array = []

    # 濁点と半濁点が一文字として変換されることを避ける。
    str_chars = str.chars.to_enum
    loop do
      s = str_chars.next
      # 濁点、半濁点は直前の文字と組み合わせる。
      if !str_array.empty? && s =~ /(ﾞ|ﾟ)/
        s = str_array.pop+s
      end
      str_array << s
    end

    re_str = ""
    str_array.each do |char|
      re_char =  NKF.nkf( '-Wwxm0Z0', NKF.nkf('-WwXm0', char) )
      re_str << (re_char.present? ? re_char : char)
    end
    re_str
  end

  def standardize!
    str = standardize
    return nil if str == self
    replace str
    self
  end

  # 空白文字をワイルドカードに置き換えて検索ワードを作る。
  # ex. "株　 山 　のり" -> "株%山%のり%"
  # デフォルトは前方一致、部分一致にしたければ:prefixに"%"を渡す。
  def to_token(prefix: "", suffix: "%")
    str = sub(/^%+/,'').sub(/%+$/,'')
    prefix + str.standardize.split(/\p{Z}+/u).join("%") + suffix
  end

  def to_token!(*args)
    str = to_token(*args)
    return nil if str == self
    replace str
    self
  end

  def digitalize
    standardize.gsub(/[^0-9]/,"")
  end

  def digitalize!
    str = digitalize
    return nil if str == self
    replace str
    self
  end

end
