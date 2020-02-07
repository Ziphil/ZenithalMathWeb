## 基本的な使い方

### Zotica を含む ZenML のパース
Zotica を含んだ ZenML をパースするには、`ZoticaParser` クラスのインスタンスを用います。
ただし、パースを行う前に、Zotica 構文を記述するのに用いるマクロの名前を登録する必要があります。

このパーサーは、ZenML 内の特定のマクロの中身を Zotica 構文と見なし、その部分を表示用の HTML (と等価な XML) に置き換えます。
まず、`register_simple_math_macro` メソッドを用いて、このときのマクロの名前を登録する必要があります。

また、Zotica が出力する HTML 要素を正しく表示するには、専用の CSS と JavaScript を適用する必要があります。
`register_resource_macro` メソッドを用いてマクロ名を設定しておくと、そのマクロが書かれた位置に、表示に必要な CSS と JavaScript を含んだ `style` 要素と `script` 要素を埋め込むことができます。

これらの設定後に `run` メソッドを呼ぶと、パースが実行され、その結果として `REXML::Document` インスタンスが返されます。
あとは好きな方法でこれを処理してください。

以下は、ZenML ドキュメントを HTML ドキュメントに変換するコード例です。
```ruby
# ライブラリの読み込み
require 'rexml/document'
require 'zenml'
require 'zotica'
include REXML
include Zenithal
# ファイルの読み込み
source = File.read("sample.zml")
# パーサーの作成
parser = ZoticaParser.new(source)
# Zotica 用のマクロの登録
parser.register_simple_math_macro("m")
parser.register_resource_macro("math-resource")
# パースの実行
document = parser.run
# HTML として保存
html_string = ZenithalConverter.simple_html(document).convert
File.write("sample.html", html_string)
```
このようにすると、以下のような ZenML ドキュメントがパースされ HTML に変換できます。
```
\zml?|version="1.0"|>
\xml?|version="1.0",encoding="UTF-8"|>
\html<
  \head<
    ## 数式を正しく表示するための CSS と JavaScript を埋め込む
    ## url 属性で Zotica 用数式フォントのパスを設定する
    &math-resource|url="font.otf"|>
  >
  \body<
    \p<
      ## 登録したマクロ内に Zotica が書ける
      2 次方程式 &m<a \sp<x><2> + bx + c = 0> は &m<\sp<b><2> - 4ac = 0> のとき重解をもち･･･。
    >
  >
>
```

### Zotica 単独のパース
ZenML ではなく Zotica 構文単独を HTML に変換したい場合は、`ZoticaSingleParser` クラスを用います。

このクラスのインスタンスを作成して `run` メソッドを呼ぶと、パースが実行され、その結果として `REXML::Element` インスタンスが返されます。
```ruby
# ライブラリの読み込み
require 'rexml/document'
require 'zenml'
require 'zotica'
include REXML
include Zenithal
# ファイルの読み込み
source = File.read("only_zotica.zml")
# パーサーの作成
parser = ZoticaSingleParser.new(source)
# パースの実行
document = parser.run
# HTML として保存
html_string = ZenithalConverter.simple_html(document).convert
File.write("only_zotica.html", html_string)
```

なお、このパース結果の HTML だけでは数式を正しく表示することはできず、別途 CSS と JavaScript を読み込んでおく必要があります。
必要な CSS と JavaScript は、コマンドラインインターフェースの `zotica` コマンドを用いるなどして得ることができます。

## CSS と JavaScript の直接生成
Zotica が出力する HTML 要素を正しく表示するための CSS と JavaScript は、Ruby から直接生成することもできます。
以下のようにしてください。
```ruby
# JavaScript の生成
javascript_string = ZoticaBuilder.create_script_string
# CSS の生成
font_url = "font.otf"
css_string = ZoticaBuilder.create_style_string(font_url)
```