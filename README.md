<div align="center">
<h1>Zenithal Math</h1>
</div>

## 概要
Zenithal Math (略称 ZenMath) は、[ZenML](https://github.com/Ziphil/Zenithal) ライクな文法で数式を記述できるマークアップ言語です。
人間が直接書くことを想定しています。

ZenMath はほとんど ZenML のサブセットになっています。
ZenML と異なる点は、以下の 2 ヶ所です。

- 一部の普通の要素が 2 つ以上の引数をもてる
- エスケープ記法がラテン文字に対しても使える (対応するギリシャ文字に変換される)

このリポジトリは、Ruby 実装の ZenML パーサーである `ZenithalParser` クラスを拡張した `ZenithalMathParser` クラスを提供します。
このクラスは通常の ZenML パーサーと同じように ZenML ドキュメントをパースしますが、引数の内容が ZenMath で書かれるマクロを処理できるようになっています。

## インストール
RubyGems からインストールできるようになる予定です。
```
gem install zenmath
```

## 使い方
`ZenithalMathParser` インスタンスを作成します。

このクラスには `register_math_macro` メソッドが追加されており、引数の内容が ZenMath で書かれるマクロを登録することができます。
このマクロに渡されるノードは、ドキュメント上の該当マクロの引数として記述された ZenMath の構造そのものではなく、それが HTML に変換されたものになります。

ZenMath が変換された HTML を正しく表示するには、専用の CSS を適用する必要があります。
このクラスのパーサーを使うと、`math-style` マクロによってその CSS を `style` 要素として埋め込むことができます。

詳しくは以下のコードを参照してください。
```ruby
# ライブラリの読み込み
require 'rexml/document'
require 'zenml'
require 'zenmath'
include REXML
include Zenithal
# パーサーの作成
source = File.read("sample.zml")
parser = ZenithalMathParser.new(source)
# ZenMath マクロの登録
parser.register_math_macro("math") do |attributes, children_list|
  # children_list には ZenML ドキュメント上で該当マクロに渡された各引数を HTML に変換したものが渡される
  # ここではそれをそのまま返して HTML を表示させている
  next children_list.first
end
```
このようにすると、以下のような ZenML ドキュメントがパースできます。
```
\zml?|version="1.0"|>
\xml?|version="1.0",encoding="UTF-8"|>
\html<
  \head<
    ## 数式を正しく表示するための CSS を埋め込む
    &math-style|url="font.otf"|>
  >
  \body<
    \p<
      ## 登録した &math マクロ内に ZenMath が書ける
      2 次方程式 &math<a \sp<x><2> + bx + c = 0> は &math<\sp<b><2> - 4ac = 0> のとき重解をもち･･･。
    >
  >
>
```