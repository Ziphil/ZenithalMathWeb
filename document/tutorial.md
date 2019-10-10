## 下準備

### Ruby のインストール
[Ruby](https://www.ruby-lang.org/ja/) の最新バージョンをインストールしてください。
少なくともバージョン 2.5 以上が必要です。

以下のコマンドで、Ruby と Gem が呼び出せるか確認できます。
```
ruby -v
gem -v
```

### ZenML と ZenMath のパーサーのインストール
RubyGems から ZenML と ZenMath のパーサーをそれぞれインストールします。
以下のコマンドを実行してください。
```
gem install zenml
gem install zenmath
```

### Zotica Math フォントのダウンロード
Zotica を正しく表示するには、専用の数式記号用フォントをダウンロードする必要があります。
[こちら](https://github.com/Ziphil/ZenithalMathWeb/blob/master/source/zenmath/resource/font.otf)からダウンロードし、作業フォルダに置いてください。

## 変換

### 変換スクリプトの作成
ZenML ドキュメントを HTML に変換するには、先程インストールした ZenML パーサーを用いて変換スクリプトを書く必要があります。
とりあえず、以下のソースコードをコピーして、作業フォルダに `convert.rb` として保存してください。
```ruby
require 'zenml'
require 'zenmath'
include Zenithal

# ファイルの読み込み (適切なファイル名に変更してください)
source = File.read("index.zml")
# パーサーの作成
parser = ZenmathParser.new(source)
# &m<(ZenMath コード)> の形で ZenMath 形式で数式を書けるようにする
parser.simple_math_macro_name = "m"
# パース
document = parser.parse

# HTML へのコンバーターの作成
converter = ZenithalConverter.simple_html(document)
# 変換
output = converter.convert

# ファイルへ書き込み
File.write("index.html", output)
```

### ZenML ドキュメントの作成
HTML に変換したい ZenML ドキュメントを作り、作業フォルダに `index.zml` として保存してください。
例えば以下のような感じです。
```
\zml?|version="1.0"|>
\html<
  \head<
    \meta|charset="UTF-8"|>
    ## Zotica 用の CSS と JavaScript の埋め込み (フォントのパスは適切に書き換えてください)
    &math-resource|font-url="font.otf"|>
    \title<Zotica Test>
  >
  \body<
    \h1<Zotica Test>
    \p<
      &m<x = \frac<-b \pm> \sqrt<\sp<b><2> - 4 ac>><2 a>>
    >
    \p<
      &m<\frac<`p><2> = \sum<k = 0><\infty>> \frac<(2 k)!><\sp<2><2 k> \sp<(k!)><2>> \frac<1><2 k + 1> = \prod<k = 1><\infty>> \frac<4 \sp<k><2>><4 \sp<k><2> - 1>>
    >
  >
>
```

### 変換
作業フォルダには `index.zml`, `convert.rb`, `font.otf` の 3 つのファイルがあるはずです。
この状態で、上で用意したスクリプトを呼び出し、変換を行います。
```
ruby convert.rb
```
同じフォルダ内に `index.html` が生成されます。