# Nomikai Kanji（飲み会幹事帳簿）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-nomikai-kanji
```

JP08 · 日本ローカライズシリーズ。対話の哲学：**幹事帳簿 Host Ledger**。この Agent は幹事のあの帳簿そのものである。人数、品目の合計、1人分（割り勘の地元の流儀として自動で100円単位に切り上げる）、終電までのカウントダウン、すべてが1枚の伝票に載る。録音も文字起こしも、会話内容の要約も決してしない——会議の文字起こしは基盤の能力であり、酒席に必要なものでもない。持つのはお金と人数と時間という、幹事が持ち続けなければならない3つの数字だけであり、うなずきが会計の確認になる。

## プレビュー画像

![プレビュー-index](<../../screenshots/nomikai-kanji/preview-nomikai-kanji-index.png>)
![プレビュー-s2](<../../screenshots/nomikai-kanji/preview-nomikai-kanji-s2.png>)
![プレビュー-s3](<../../screenshots/nomikai-kanji/preview-nomikai-kanji-s3.png>)
![プレビュー-s4](<../../screenshots/nomikai-kanji/preview-nomikai-kanji-s4.png>)

## ローカル性

日本の飲み会では、幹事（主催者）がいちばん気を使う役回りである。人を数え、ペースを整え、割り勘を計算し（100円単位に切り上げる作法にも気を配る）、終電を見張る。幹事自身はなかなか楽しく飲めない——注意がずっと帳簿に向いているからである。

## 機能フロー（クローズドループ）

- 記帳：+ITEM で品目ごとに加算する（デモ単価は1品 ¥1,200）、+PERSON で人数を調整し、1人分は自動で100円単位に切り上げる
- 時間管理：TRAIN で終電時刻のプリセットを切り替え、カウントダウンは分単位で伝票の下部に大きな文字で常時表示する
- 会計：うなずきが決済の確認となり、1人分を読み上げる。全過程で録音も文字起こしもせず、ページを閉じれば忘れる

## ジェスチャー対応表

| ジェスチャー（テンプルタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（README の機能フローと画面のガイド行を参照） |
| 上スワイプ / 下スワイプ | ArrowUp / ArrowDown | 画面のガイド行にあるこの Agent 固有の定義を参照 |
| うなずき（頭が安定しているとき） | `onHeadGesture('nod')` | この Agent の主な確認（+ITEM と同等。ガイド行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面のボタンはいずれも上記ジェスチャーのミラーであり、ほかに SPEAK（いつでも現在の状態を聞く）と DEMO（デモ用ステートマシン。終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | この Agent はどの権限も申請しない。TTS とセンサーにマニフェスト権限は不要であり、カメラは一切呼び出さない（該当する場合） |

## 誠実な境界

- 単価と終電時刻はデモ用プリセットである（単価 ¥1,200、終電は3段階）。実際には店と路線に合わせて登録を変更すること（方法は README に記載）。合計は登録内容の和であり、レシートではない
- カウントダウンは分粒度で進み、ネットワークで時刻を合わせることはしない。日付をまたぐ終電はプリセットの分数で数える

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントで効果がないと明記されている）。

## パッケージとプレビュー

```bash
cd ~/workspace/rokid/nomikai-kanji
~/tools/bin/aix pack . -o ../dist/nomikai-kanji.aix
~/tools/bin/aix list ../dist/nomikai-kanji.aix
```

## 実機テスト情報

| フィールド | 値 |
|---|---|
| Studio 名 | Nomikai Kanji（インポート後に記入） |
| Version / Build | 1.0.2 / インポート後に記入 |
| App Category | Life |
| Intent Description | At a Japanese nomikai: the organizer ledger for headcount, bill split with 100-yen rounding, and last-train countdown. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了。Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 飲み会幹事の帳簿です。人数、累計金額、割り勘の流儀で100円単位に切り上げた1人分、そして大きな終電カウントダウンを、居酒屋の伝票1枚にまとめます。テーブルでの会話を録音・文字起こしすることは決してありません。帳簿が持つのはお金と人数と時間だけです。

### Opening Message

> ## Nomikai Kanji
> 
> 幹事とは、一晩中3つの数字を持ち続けることです。人数とお金と終電です。その3つを1枚の伝票に載せます。合計と、割り勘で切り上げた1人分と、大きな文字のカウントダウンです。あなたは飲んでください。帳簿は酔いません。

### Preview Media

- `preview-nomikai-kanji-index.png` — 初期状態
- `preview-nomikai-kanji-s2.png` — デモ状態 2
- `preview-nomikai-kanji-s3.png` — デモ状態 3
- `preview-nomikai-kanji-s4.png` — デモ状態 4

> 正式な審査提出には3–5点のメディアファイルが必要で、動画1点以上（60秒以内）を含むこと。動画は GO の実機セルフテスト時に追加で録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：幹事帳簿 Host Ledger。居酒屋の伝票：金額列を右寄せにし、終電カウントダウンを大きな文字で表示

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
