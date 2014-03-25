comodule
========

今まで作って来た Rails プロジェクトで共通して使用しているコードを gem にします。

## 概要

  * モジュール
    * ConfigSupport
    * UniArray

  * クラスの拡張
    * Hash
      * pullout, pullout!
    * String
      * standardize

## モジュール

### ConfigSupport

定義なしにアトリビュートを保存できる初期情報などを扱うのに適した汎用オブジェクト。

```ruby
config = Comodule::ConfigSupport::Config.new
config.host = 'example.com'
config.port = '3000'

config.host
# => "example.com"

config.port
# => "3000"
```

デフォルトでは、設定されていないディレクティブは nil を返します。

```ruby
config.nothing
# => nil
```

設定されていないディレクティブにアクセスした場合に例外を挙げることもできます。

```ruby
config = Comodule::ConfigSupport::Config.new(
  configure_type: :hard,
  host: 'example.com',
  port: '3000'
)
config.nothing
# => ArgumentError: Comodole::ConfigSupport::Config is missing this directive [nothing].
```

`Hash` に変換

```ruby
config.to_hash
# => {:host=>"example.com", :port=>"3000"}
```

### UniArray

要素の重複をさせない `Array` のサブクラス。スニペットと言っていいくらい簡単なコードで出来ています。

```ruby
arr = Comodule::UniArray.new

# 重複する要素は無視されます。
arr << "a"
arr << "b"
arr << "a"
arr << "c"
arr << "a" << "b" << "c"
# => ["a", "b", "c"]
```

`#max_size=` で要素数の上限を決めることもできます。`#max_size` を超えると、先頭が切り詰められます。

```ruby
arr = Comodule::UniArray.new
arr.max_size = 5

arr << 1 << 2 << 3
arr << 1 << 2 << 3

arr << 4 << 5 << 6
arr << 4 << 5 << 6

arr << 7 << 8 << 9 << 10
# => [6, 7, 8, 9, 10]
```

`Array` の集合和演算を使えば済むことなので、`merge` はオーバーライドしていません。

```ruby
arr1 = [1, 3, 4, 5]
arr2 = [2, 3, 5, 9]

# 集合和演算を使いましょう。
arr = Comodule::UniArray.new
arr += arr1
arr |= arr2
# => [1, 3, 4, 5, 2, 9]
```

## クラスの拡張

### Hash

#### pullout, pullout!

ハッシュから指定要素を抜き出して新しいハッシュを返す。

```ruby
hsh = {
  date: "20130322",
  title: "The Tell-Tale Brain",
  secret_token: "it-is-secret"
}
result_hsh = hsh.pullout(:date, :title)
# => {date: "20130322", title: "The Tell-Tale Brain"}
```

デフォルトでは未定義の要素は無視します。

```ruby
hsh = {
  date: "20130322",
  title: "The Tell-Tale Brain",
  secret_token: "it-is-secret"
}
result_hsh = hsh.pullout(:date, :title, :author)
# => {date: "20130322", title: "The Tell-Tale Brain"}
```

未定義要素へのアクセス時に例外を挙げたいときは `pullout!` を使います。

```ruby
hsh = {
  date: "20130322",
  title: "The Tell-Tale Brain",
  secret_token: "it-is-secret"
}
result_hsh = hsh.pullout!(:date, :title, :author)
# => ArgumentError: Comodule::CustomizeClass::HashCustom cannot find key 'author' is a Symbol.
```

### String

#### standardize

英数字記号などを半角に変換します。Ruby の標準添付ライブラリーに含まれる。`NKF` を利用します。変換のコアは以下のコードです。

```ruby
after = NKF.nkf( '-Wwxm0Z0', NKF.nkf('-WwXm0', before) )
```

これだけだと `½` など、失われる文字がありますが、極力文字が失われないように工夫してあります。

```ruby
txt = "Ｒuｂｙ　２．０.1−ｐ451 ½"
txt.standardize
# => "Ruby 2.0.1-p451 ½"
```

半角カナは全角カナに変換されます。

```ruby
txt = 'ﾄﾞﾎﾞｳﾌﾞｼﾋﾞﾃﾍﾞｶﾊﾞﾅｰﾊﾞ'
txt.standardize
# => "ドボウブシビテベカバナーバ"
```

#### to_token

空白文字をワイルドカード `%` に置き換えて、検索文字列を作ります。

```ruby
search_word = "株　 山 　のり"
query_token = search_word.to_token
# => "株%山%のり%"
```

デフォルトでは前方一致から始まるけど、`prefix` に `%` を指定すれば、部分一致から開始することもできます。

```ruby
search_word = "株　 山 　のり"
query_token = search_word.to_token(prefix: ?%)
# => "%株%山%のり%"
```

#### digitalize

数字以外の文字列を排除します。

```ruby
tel = "01-2345-6789"
tel.digitalize
# => "0123456789"

# 全角でも大丈夫
tel = "０１−２３４５−６７８９"
tel.digitalize
# => "0123456789"
```

#### その他 String の拡張

上記のミューテーター

* standardize!
* to_token!
* digitalize!

その他細々したメソッド

* ltrim, ltrim!
* rtrim, rtrim!
* trim, trim!
* ascii_space, ascii_space!
  => 全角スペースを半角スペースに
* single_space, single_space!
  => 全角、半角問わず複数のスペースを一つの半角スペースに
