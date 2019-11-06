## 下準備

### Ruby のインストール
[Ruby](https://www.ruby-lang.org/ja/) の最新バージョンをインストールしてください。
少なくともバージョン 2.5 以上が必要です。

以下のコマンドで、Ruby と Gem が呼び出せるか確認できます。
```
ruby -v
gem -v
```

### ZenML と Zotica の処理系のインストール
RubyGems から ZenML と Zotica の処理系をそれぞれインストールします。
以下のコマンドを実行してください。
```
gem install zenml
gem install zotica
```

### Zotica Math フォントのダウンロード
Zotica を正しく表示するには、専用の数式記号用フォントをダウンロードする必要があります。
[こちら](https://github.com/Ziphil/ZenithalMathWeb/blob/master/source/zotica/resource/font.otf)からダウンロードし、作業フォルダに置いてください。

## 変換

### ZenML ドキュメントの作成
HTML に変換したい ZenML ドキュメントを作り、作業フォルダに `index.zml` として保存してください。
例えば以下のような感じです。
```
\zml?|version="1.0"|>
\html<
  \head<
    \meta|charset="UTF-8"|>
    ## Zotica 用の CSS と JavaScript の埋め込み
    ## font-url 属性には数式用フォントのパスを指定します
    &math-resource|font-url="font.otf"|>
    \title<Zotica Test>
  >
  \body<
    \h1<Zotica Test>
    \p<
      ## m マクロで Zotica を記述
      &m<\sb<x><0> = \frac<-b \pm> \sqrt<\sp<b><2> - 4 ac>><2 a>>
    >
    \p<
      &m<\frac<`p><2> = \sum<k = 0><\infty>> \frac<(2 k)!><\sp<2><2 k> \sp<(k !)><2>> \frac<1><2 k + 1> = \prod<k = 1><\infty>> \frac<4 \sp<k><2>><4 \sp<k><2> - 1>>
    >
    \p<
      &m<\widehat<\frak<T> (V)> = \bigoplus<n \in> \bb<N>> (\un<\underbrace<V \otimes> V \otimes> \cdots> \otimes> V>><n \text< times>>)>
    >
  >
>
```

### フォントの文字形データの抽出
アクセント記号などを正しい位置に表示するため、HTML の本文に使われるフォントのデータをあらかじめ抽出しておく必要があります。
この作業を行わなくてもある程度綺麗に数式を組むことはできるので、面倒であればこのセクションの作業は飛ばしても構いません。

本文フォントに使う TrueType 形式のフォントファイルを用意し、作業フォルダに `main.ttf` という名前で保存します。
この状態で、以下のコマンドを実行してください。
```
zotica --create-font main.ttf -o main.json
```
同じフォルダ内に `main.json` が生成されます。

### 変換
ZenML ドキュメントの変換を行います。
前のセクションで文字形データの抽出を行っている場合は、以下のコマンドを実行してください。
```
zotica index.zml -f main.json -o index.html
```
文字形データがない場合は、`-f` オプションを指定せず、以下のコマンドを実行してください。
```
zotica index.zml -o index.html
```
同じフォルダ内に `index.html` が生成されます。