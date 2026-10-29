# Omiyage Cover（お土産の義務カバー）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-omiyage-cover
```

JP09 · 日本ローカライズシリーズ。対話の哲学：**人情カバー Obligation Grid**。この Agent は贈り物リストをカバーグリッドに変える。マスは品物ではなく人である。出発前に受取人6人を登録し（デモ用リスト）、店で1点買うごとに1人を消し込む。在庫が足りないときは先に「後で」（後日対応）と記録し、買ったふりは決してさせない。6マス全てに ✓ が付いて初めて「全員分そろいました」と言う。SCAN でギフトボックスのバーコードを読み取っても在庫が1点増えるだけであり（暫定の識別）、消し込みは必ず自分で確認する。贈り物が良いかどうかを判別はしない（それは慧眼の仕事である）。守るのは「全員に行き渡る」という人情の最低ラインだけである。

## プレビュー画像

![プレビュー-index](<../../screenshots/omiyage-cover/preview-omiyage-cover-index.png>)
![プレビュー-s2](<../../screenshots/omiyage-cover/preview-omiyage-cover-s2.png>)
![プレビュー-s3](<../../screenshots/omiyage-cover/preview-omiyage-cover-s3.png>)
![プレビュー-s4](<../../screenshots/omiyage-cover/preview-omiyage-cover-s4.png>)

## ローカル性

日本の出張や旅行の帰りに、お土産は気まぐれな贈り物ではなく義務である。上司や同じグループの同僚を一人も漏らしてはならず、誰かを漏らすことは品物を間違えることより失礼である。店で買っているときにいちばん焦るのは「自分はもう何点買ったのか、あと誰が残っているのか」である。

## 機能フロー（クローズドループ）

- リスト：受取人6人、一人1マス（デモ用リスト）。スライドして人を選ぶ
- 消し込み：BOUGHT で ✓ を付け、在庫を1点引く。在庫がゼロのときは LATER（△ 後日対応）と記録することしかできず、透かしは許さない
- 在庫：STOCK で手動で +1 するか、SCAN でギフトボックスのバーコードを読み取って暫定で +1 する。6 / 6 が ✓ になって初めて全員カバーを知らせる

## ジェスチャー対応表

| ジェスチャー（テンプルタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（README の機能フローと画面のガイド行を参照） |
| 上スワイプ / 下スワイプ | ArrowUp / ArrowDown | 画面のガイド行にあるこの Agent 固有の定義を参照 |
| うなずき（頭が安定しているとき） | `onHeadGesture('nod')` | この Agent の主な確認（BOUGHT と同等。ガイド行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面のボタンはいずれも上記ジェスチャーのミラーであり、ほかに SPEAK（いつでも現在の状態を聞く）と DEMO（デモ用ステートマシン。終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| `CAMERA` | 写真で照合する経路（機能フローを参照。失敗した場合は SKIP する） |

## 誠実な境界

- リストも贈り物もデモ用セットである。単価と予算は扱わない（それは買い物の帳簿であり、人情の帳簿ではない）
- SCAN によるギフトボックスの識別は暫定である（wide 撮影と LLM による二値判定）。誤判定のときは STOCK の手動修正を正とする

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントで効果がないと明記されている）。

## パッケージとプレビュー

```bash
cd ~/workspace/rokid/omiyage-cover
~/tools/bin/aix pack . -o ../dist/omiyage-cover.aix
~/tools/bin/aix list ../dist/omiyage-cover.aix
```

## 実機テスト情報

| フィールド | 値 |
|---|---|
| Studio 名 | Omiyage Cover（インポート後に記入） |
| Version / Build | 1.0.3 / インポート後に記入 |
| App Category | Life |
| Intent Description | Buying omiyage souvenirs in Japan: covers a 6-person recipient grid against gift-box stock. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了。Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> お土産の義務カバーです。贈り物リストを品物ではなく人のグリッドとして扱います。受取人6人、各1マス。買えばチェックし、在庫が切れれば正直に後日に回します。ごまかしはさせません。ギフトボックスをスキャンして在庫を加えるのは暫定判定で、各人の確定は自分で行います。全部のマスが埋まって初めて完了です。

### Opening Message

> ## Omiyage Cover
> 
> 贈る相手を忘れることは、品物を間違えることより失礼です。6人の名前、6つのマス。箱を買って1人をカバーし、在庫がなければマスには堂々と「後で」と出ます。静かな偽チェックはありません。6人全員をカバーして初めて、全員分そろいましたと言えます。

### Preview Media

- `preview-omiyage-cover-index.png` — 初期状態
- `preview-omiyage-cover-s2.png` — デモ状態 2
- `preview-omiyage-cover-s3.png` — デモ状態 3
- `preview-omiyage-cover-s4.png` — デモ状態 4

> 正式な審査提出には3–5点のメディアファイルが必要で、動画1点以上（60秒以内）を含むこと。動画は GO の実機セルフテスト時に追加で録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：人情カバー Obligation Grid。ギフトボックスのマス配列（破線枠のバリエーション）：マスは人であり、全員カバーで初めて締める

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）

### Change Log（Build 1.0.1）

**Features added**

- なし

**Improvements**

- ボタンをこの Agent の UI 形態に合わせて個別に形作りした（形態は設計契約を参照）。シリーズ全体で同じボタンのセットを共用しない

**Fixes**

- 実機のモノクロ緑パネルに合わせて色を調整した。元の純白 #ffffff を緑の階調に変え（最も明るい緑 #7dff9e）、明暗は緑だけで表現する

### Change Log（Build 1.0.2）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- 言語の純化：画面と音声の文案を現地の言語に統一し（日本は日本語、韓国は韓国語）、混入していた日本語・中国語の文案を一つずつ調べて取り除いた（SCAN のプロンプトを含む）

### Change Log（Build 1.0.3）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- FileReader 削除（Ink ランタイムに存在せず、実機で必ず失敗する）：写真 Blob→dataURL を公式ドキュメントの経路 `blob.arrayBuffer()` + 分割 `btoa` に変更し、失敗時は全艦隊エラーコード E2005 を表示する。
