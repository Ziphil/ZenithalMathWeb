<div align="center">
<h1>Zotica ＋ ZenMath</h1>
</div>

## 概要

### 構成要素
このリポジトリは、以下の 2 つの要素から構成されています。

- HTML 上に数式を表示するための HTML カスタム要素仕様 ＋ CSS ＋ JavaScript セット (Zotica)
- 上記仕様に則った HTML を出力するためのマークアップ言語 (ZenMath)

以下でそれぞれについて説明します。

### Zotica
Zotica とは、数式を記述するための HTML カスタム要素と、それを綺麗に表示するための CSS ＋ JavaScript のセットです。
TeX と同程度の品質の数式を組めることと、自動生成にありがちな難読な HTML にはならないようにすることを目指しています。
この HTML 要素の仕様は、数式の構造というよりもブラウザ上での見た目に沿った構成になっており、記号の位置を調整するためのアドホックな要素も含みます。
そのため、人間が直接書くことは想定していません。

ブラウザ上で数式を表示するエンジンとしては、すでに [MathJax](https://www.mathjax.org/) や [KaTeX](https://katex.org/) などがあります。
これらを使わずに新しいエンジンを開発している理由は、既存のエンジンの数式のフォントやスペーシングを自分好みに調整しようとしたところ、なかなか思うようにいかず、「それなら最初から作った方が早くね?」となったためです。
自己満足です。

Zotica の表示サンプルは[こちら](https://ziphil.github.io/ZenithalMathWebDemo/main.html)から見られます。

カスタム要素の仕様は以下の通りです。
現在は試案段階なので、突然変更になる可能性があります。

- バージョン 1.0 (準備中)

### ZenMath
Zenithal Math Markup Language (略称 ZenMath) は、[ZenML](https://github.com/Ziphil/Zenithal) ライクな文法で数式を記述できるマークアップ言語です。
人間が直接書くことを想定しています。

ZenMath はほとんど ZenML のサブセットになっています。
ZenML と異なる点は、以下の 2 ヶ所のみです。

- 一部の普通の要素が 2 つ以上の引数をもてる
- エスケープ記法がラテン文字に対しても使える (対応するギリシャ文字に変換される)

このリポジトリは、Ruby 実装の ZenML パーサーである `ZenithalParser` クラスを拡張した `ZenmathParser` クラスを提供します。
このクラスは通常の ZenML パーサーと同じように ZenML ドキュメントをパースしますが、引数の内容が ZenMath で書かれるマクロを処理できるようになっています。

## インストール
RubyGems からインストールできるようになる予定です。
```
gem install zenmath
```

## パーサーの使い方
`ZenmathParser` インスタンスを作成します。

このクラスには `register_math_macro` メソッドが追加されており、引数の内容が ZenMath で書かれるマクロを登録することができます。
このマクロに渡されるノードは、ドキュメント上の該当マクロの引数として記述された ZenMath の構造そのものではなく、それが Zotica に変換されたものになります。

Zotica を正しく表示するには、専用の CSS と JavaScript を適用する必要があります。
このクラスのパーサーを使うと、`math-style` マクロによって必要な CSS と JavaScript を埋め込むことができます。

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
parser = ZenmathParser.new(source)
# ZenMath マクロの登録
parser.register_math_macro("math") do |attributes, children_list|
  # children_list には ZenML ドキュメント上で該当マクロに渡された各引数を Zotica に変換したものが渡される
  # ここではそれをそのまま返して HTML として表示させている
  next children_list.first
end
```
このようにすると、以下のような ZenML ドキュメントがパースできます。
```
\zml?|version="1.0"|>
\xml?|version="1.0",encoding="UTF-8"|>
\html<
  \head<
    ## 数式を正しく表示するための CSS と JavaScript を埋め込む
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