module Comodule::CustomizeClass::HashCustom

  # 指定したキーの組み合わせだけのハッシュを新たに作って返す。
  # キーが見つからなくても無視する。
  def pullout(*args)
    args.inject({}) do |hsh, key|
      hsh[key] = self[key] if self[key]
      hsh
    end
  end

  # キーが見つからないときは例外を挙げる。
  def pullout!(*args)
    args.inject({}) do |hsh, key|
      raise ArgumentError, "U::CustomizeClass::HashCustom cannot find key '#{key}' is a #{key.class.name}." unless self[key]
      hsh[key] = self[key]
      hsh
    end
  end
end
