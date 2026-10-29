# Konbini Basket（コンビニかごチェック）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-konbini-basket
```

**AIX 直接ダウンロード**（最新版）：[konbini-basket.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/konbini-basket.aix)

JP03 ・ 日本ローカライズシリーズ。操作の考え方：**レシート台帳 Receipt Ledger**。本 Agent は、自動で記帳するレシートである。出かける前に買うものを 4 つ登録し、店内で手に取るたびに 1 行ずつ消し込む。合計行は、残り何件かを常に知らせる。レジでは翻訳はしない（翻訳は基盤側の担当）。最も頻繁に使うレジの定型句 4 つを大きな文字のフレーズカードにし、店員に指して示すか、読み上げるかできるようにする。バーコード読み取りは任意の消し込み支援である。現在の品目と一致した場合だけ記帳し、一致しなければその旨を正直に伝え、合わない台帳には緑の合図を出さない。

## プレビュー画像

![プレビュー-index](<../../screenshots/konbini-basket/preview-konbini-basket-index.png>)
![プレビュー-s2](<../../screenshots/konbini-basket/preview-konbini-basket-s2.png>)
![プレビュー-s3](<../../screenshots/konbini-basket/preview-konbini-basket-s3.png>)
![プレビュー-s4](<../../screenshots/konbini-basket/preview-konbini-basket-s4.png>)

## 地域性

日本のコンビニでの買い物は、頻度が高く金額は小さい。片手にかご、もう一方の手にスマートフォンを持ち、レジでは定型の問いかけ（割り箸は？袋は？温めますか？）が続く。1 つ買い忘れればもう一度足を運ぶことになり、問いかけが分からなければレジ前で止まってしまう。

## 機能の流れ（完結した流れ）

- 登録：固定の 4 件リスト（おにぎり / お茶 / サラダ / プリンはデモ用セット。README に、自分のリストに差し替えできると明記） を 1 件ずつ並べる
- 消し込み：GOT または SCAN（wide 撮影 → バーコード / LLM で名称を読み取り、暫定照合）で 1 行記帳し、✓ と金額を同時に累計する
- レジ：定型句カード 4 枚（割り箸 / 袋 / 温め / そのまま）を大きな文字で切り替え、レジ前で PHRASE を押すだけにする

## ジェスチャー対応表

| ジェスチャー（テンプル側タッチパッド） | キーイベント | 本 Agent での役割 |
|---|---|---|
| 1 回タップ | Enter | 状況に応じた GO（README の機能の流れと画面の guide 行を参照） |
| 上スワイプ / 下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある本 Agent 専用の定義を参照 |
| うなずき（頭が安定しているとき） | `onHeadGesture('nod')` | 本 Agent の主な承認操作（GOT と同等。guide 行を参照） |
| 2 回タップ | Backspace | システムの戻る操作（横取りしない） |

画面のボタンは上記ジェスチャーの鏡像であり、ほかに SPEAK（現在の状態をいつでも聞ける）と DEMO（状態遷移のデモ。終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| `CAMERA` | 撮影による照合経路（機能の流れを参照。失敗した場合は SKIP） |

## 正直な境界

- リストは内蔵のデモ用 4 件セットであり、自由な編集には対応していない（音声登録による編集は今後の課題）。合計はリスト表示価格の合計であり、レジでの実際の支払額ではない
- SCAN の読み取り名称は撮影 + LLM によるもので暫定である。原文を表示し、利用者の承認を待ってから消し込む。失敗した場合は SKIP とし、読み取れたふりをしない

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントに効果がないと明記されている）。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/konbini-basket
~/tools/bin/aix pack . -o ../dist/konbini-basket.aix
~/tools/bin/aix list ../dist/konbini-basket.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Konbini Basket（インポート後に記入） |
| Version / Build | 1.0.3 / インポート後に記入 |
| App Category | Life |
| Intent Description | In a Japanese convenience store: checks off a 4-item basket list and shows counter phrase cards. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> コンビニかご台帳：買うもの 4 件を、自分で埋まっていくレシートとして表示します。品物を手に取るたびに価格付きで消し込み、合計行が残りを知らせます。レジでは、割り箸・袋・温め・そのままの大きなフレーズカード 4 枚がライブ翻訳の代わりになります。任意のバーコード読み取りは、承認するまで暫定扱いです。

### Opening Message

> ## Konbini Basket
> 
> 品物は 4 つ、レシートは 1 枚。品物を手に取り、GOT を押すと行が埋まります。合計が残りを常に知らせます。レジでは PHRASE を押して大きなカードを示してください。割り箸、袋、温める、そのまま、の 4 つです。

### Preview Media

- `preview-konbini-basket-index.png` — 初期状態
- `preview-konbini-basket-s2.png` — デモ状態 2
- `preview-konbini-basket-s3.png` — デモ状態 3
- `preview-konbini-basket-s4.png` — デモ状態 4

> 正式な審査提出には 3–5 件のメディアファイルが必要で、動画を 1 件以上（≤60 s）含めます。動画は GO の実機セルフテスト時に追加録画します。

### Change Log（Build 1.0.0）

**Features added**

- 初版：レシート台帳 Receipt Ledger。レシート型の縦台帳：破線枠内に等幅フォントの明細を並べ、合計行で締める

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）

### Change Log（Build 1.0.1）

**Features added**

- なし

**Improvements**

- ボタンを本 Agent の UI 形態に合わせて個別に造形した（形態は設計契約を参照）。全シリーズ共通のボタンは使わない

**Fixes**

- 色を実機の単色緑パネルに合わせた：元の純白 #ffffff を緑の階調に変更した（最も明るい緑 #7dff9e）。明暗は緑だけで表す

### Change Log（Build 1.0.2）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- 言語の純化：画面と音声の文案を現地の言語に統一した（日本 = 日本語 / 韓国 = 韓国語）。混入していた日本語・中国語の文案（SCAN のプロンプトを含む）を 1 件ずつ調べて取り除いた

### Change Log（Build 1.0.3）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- FileReader 削除（Ink ランタイムに存在せず、実機で必ず失敗する）：写真 Blob→dataURL を公式ドキュメントの経路 `blob.arrayBuffer()` + 分割 `btoa` に変更し、失敗時は全艦隊エラーコード E2005 を表示する。
