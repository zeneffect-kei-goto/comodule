comodule
========

今まで作って来た Rails プロジェクトで共通して使用しているコードを gem にします。

## 概要

  * モジュール
    * Deployment
    * ConfigSupport
    * UniArray

  * クラスの拡張
    * String
      * standardize

## モジュール

### Deployment

AWS CloudFormation を使って、AWS 上へのデプロイを容易にします。
`Rails.root` の直下にデプロイに必要なファイルを格納する `platform` ディレクトリを作り、構築する環境の名前のディレクトリをその中に作ります。ここでは、`staging` とします。

```ruby
platform = Comodule::Deployment::Platfrom.new 'staging'

# ローカルのソースを S3 に acl: :private でアップする。
platform.archive_repository
platform.upload_archive

# スタックの作成
platform.create_stack
```

これで `platform/cloud_formation/template.json.erb` を使って CloudFormation のスタックを作成します。この際、変数 `config` で `config.yml` または `secret_config.yml` で設定した項目にアクセスできます。
例えば、

```yaml
stack_name_prefix: trial
application: &application Trial
project_root: !str /ec2-user/projects
rails_root: !str /ec2-user/projects/trial

ec2_instance:
  instance_type: m3.medium
  ami: ami-a1bec3a0
  name: *application
  key_name: ssh_key
  iam_role: dev_master
  security_group: aa-1a2b3c4d

aws_access_credentials:
  cloud_formation:
    region: ap-northeast-1
```

```json
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "It creates a Rails stack.",

  "Resources": {
    "System": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "InstanceType": "<%= config.ec2_instance.instance_type %>",
        "ImageId": "<%= config.ec2_instance.ami %>",
        "KeyName": "<%= config.ec2_instance.key_name %>",
        "IamInstanceProfile": { "Ref": "InstanceProfile" },
        "SecurityGroupIds": ["<%= config.ec2_instance.security_group %>"],
        "Tags": [{"Key": "Name", "Value": "<%= config.ec2_instance.name %>"}],
      }
    }
  }
}
```

### ConfigSupport

定義なしにアトリビュートを保存できる初期情報などを扱うのに適した汎用オブジェクトです。

```ruby
config = Comodule::ConfigSupport::Config.new
config.host = 'example.com'
config.port = '3000'

config.host
# => "example.com"

config.port
# => "3000"
```

但し、あくまでも `Object` のサブクラスなので、`Object#methods`, `Object#protected_methods`, `Object#private_methods` に含まれる名前のディレクティブを作ることはできません。

```ruby
config = Comodule::ConfigSupport::Config.new(
  system: 'app_name'
)
# => ArgumentError
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

`new` の引数に `Hash` が含まれる場合は、再帰的にオブジェクト化します。

```ruby
config = Comodule::ConfigSupport::Config.new(
  host: 'example.com',
  port: '3000',
  db: {
    host: 'rds',
    database: 'app_development',
    username: 'ec2-user',
    password: 'secret',
    instance: {
      type: 't1.micro',
      multi_az: true
    }
  }
)

config.db.host
# => "rds"

config.db.instance.type
# => "t1.micro"
```

角括弧演算子を使えば、`Hash` のような振る舞いもします。

```ruby
config = Comodule::ConfigSupport::Config.new

config[:host] = 'example.com'

config[:db] = {
  host: 'rds',
  username: 'ec2-user'
}

config[:db][:host]
# => "rds"

config.db.username
# => "ec2-user"
```

`Hash` に変換

```ruby
config.to_hash
# => {:host=>"example.com", :port=>"3000"}
```

`#merge` で二つの `Config` オブジェクトをマージできます。`#+()` はそのエイリアスです。マージは再帰的に行われます。

```ruby
config = Comodule::ConfigSupport::Config.new(
  host: 'example.com',
  db: {
    host: 'rds',
    database: 'app_development',
    username: 'ec2-user',
    schedule: {
      boot: '08-00-00',
    }
  }
)

config2 = Comodule::ConfigSupport::Config.new(
  port: '3000',
  db: {
    host: 'rds',
    password: 'secret',
    schedule: {
      shutdown: '22-00-00'
    }
  }
)

config = config1 + config2

config.to_hash
# => {
  host: 'example.com',
  port: '3000',
  db: {
    host: 'rds',
    database: 'app_development',
    username: 'ec2-user',
    password: 'secret',
    schedule: {
      boot: '08-00-00',
      shutdown: '22-00-00'
    }
  }
}
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

Comodule は、Hash と String の独自拡張を持っています。
利用するには `Comodule::CustomizeClass.customize` を使います。Rails の場合は、`config/initializers/comodule.rb` などに

```ruby
Comodule::CustomizeClass.customize
```

として、読み込みます。このメソッドは複数回呼び出すとエラーになりますので、気をつけてください。
尚、Comodule は既存のメソッドをオーバーライドできません。

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
