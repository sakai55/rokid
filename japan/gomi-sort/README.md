# Gomi Sort（ごみ分別のレフェリー）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-gomi-sort
```

JP06・日本ローカライズシリーズ。インタラクション哲学：**分流レフェリー Branching Referee**。この Agent の権威は決して AI ではなく、あなたの家のルールカード：まず自宅の自治体のモデルカードを選ぶ（デモには渋谷区／世田谷区の 2 枚のモデルカードと 1 枚の自宅カードを含む）。品目ごとにまず自分で落下先を判断し、Agent がルールカードと照らして正誤を判定する——間違えたらその場で正しい分類と収集日を説明し、間違いの数に記録する。撮影＋LLM は「候補」（候補の提案）を出すだけで、決して代わりに判定しない。汎用の物体認識 Q&A はしない（プラットフォームの慧眼の仕事）。することは 1 つだけ：あなたの家のごみを、あなたの家のルールの下で、正しく分けること。

## プレビュー画像

![プレビュー-index](<../../screenshots/gomi-sort/preview-gomi-sort-index.png>)
![プレビュー-s2](<../../screenshots/gomi-sort/preview-gomi-sort-s2.png>)
![プレビュー-s3](<../../screenshots/gomi-sort/preview-gomi-sort-s3.png>)
![プレビュー-s4](<../../screenshots/gomi-sort/preview-gomi-sort-s4.png>)

## 地域性

日本のごみ分別は世界でも最も細かい家庭の制度の 1 つ：同じ物でも市区町村によって属する分類が違うことがあり、ペットボトルはラベルを剥がし、スプレー缶は穴を開け、粗大ごみは券を買って予約する。間違えて出すとシールを貼って返され、棟全体から見えてしまう。

## 機能フロー（閉ループ）

- カード選択：WARD でルールカードを巡回（デモ用モデルカード ×2 ＋ 自宅カード）、分類と収集日はカードに連れて切り替わる
- 判定：スワイプで落下先を選択（燃やす／燃やさない／資源／粗大）→ JUDGE がルールカードと照合し、間違えたら正しい枝と収集日を説明する
- 候補：SCAN で物を撮ると LLM の「候補」の提案が得られる（暫定、画面に明示）。最終の判定は常にあなた＋ルールカードが決める

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（README の機能フローと画面の guide 行を参照） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある、この Agent 固有の定義を参照 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | この Agent の主確認（JUDGE と等価。guide 行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンはすべて上記ジェスチャのミラーで、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態機械のデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| `CAMERA` | 撮影による照合の経路（機能フローを参照。失敗したら SKIP） |

## 誠実な境界

- デモのルールカードはモデル化した一般的な分け方で、どの自治体の公式条文でもない；実際に使うときは自宅の自治体のマニュアルを正とし、それに合わせてカードを書き換えること（方法は README に記載）
- LLM の候補は間違うことがあり、分類は地域によって変わる。だから候補には提案権しかなく判定権はない——これがこの Agent の核の設計

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式に効果なしと明記）。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/gomi-sort
~/tools/bin/aix pack . -o ../dist/gomi-sort.aix
~/tools/bin/aix list ../dist/gomi-sort.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Gomi Sort（インポート後に記入） |
| Version / Build | 1.0.3 / インポート後に記入 |
| App Category | Life |
| Intent Description | At home sorting trash in Japan: drills and checks items against the household ward rule card. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 日本の家庭ごみ分別のレフェリー：まず自治体のルールカードを選ぶ——法は AI ではなくカードです。品目ごとに自分で判断し、Agent がカードと照らして判定し、外れたら正しい分別先と収集日を言います。写真＋LLM のヒントは暫定と明示され、決して判定しません。日常生活で最も厳しいリサイクルルールのために作りました。

### Opening Message

> ## Gomi Sort
> 
> ここで法なのはあなたの自治体のルールカードで、私ではありません。カードを選んで、品目ごとに自分で判断してください。カードと照らして判定し、間違えたら正しい分別先とその収集日を言います。写真による推測はあくまでヒントで、常にそう明示します。

### Preview Media

- `preview-gomi-sort-index.png` — 初期状態
- `preview-gomi-sort-s2.png` — デモ状態 2
- `preview-gomi-sort-s3.png` — デモ状態 3
- `preview-gomi-sort-s4.png` — デモ状態 4

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO の実機テスト時に追加録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：分流レフェリー Branching Referee；分流の木：品目が木の根にあり、4 本の枝が並んだ分類と収集日へ落ちる

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）

### Change Log（Build 1.0.1）

**Features added**

- なし

**Improvements**

- ボタンをこの Agent の UI 形状に合わせて個別に造形（形状は設計契約を参照）し、シリーズ全員で同じボタンのセットを共有しない

**Fixes**

- 実機の単色グリーンパネルに色を合わせた：元の純白 #ffffff をグリーンの階調に変更（最も明るいグリーン #7dff9e）、濃淡はグリーンだけで表現

### Change Log（Build 1.0.2）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- 言語の純化：画面と音声の文言を現地言語に統一（日本＝日本語／韓国＝韓国語）し、混入していた日本語・中国語の文言（SCAN のプロンプトを含む）を 1 つずつ調べて除去

### Change Log（Build 1.0.3）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- FileReader 削除（Ink ランタイムに存在せず、実機で必ず失敗する）：写真 Blob→dataURL を公式ドキュメントの経路 `blob.arrayBuffer()` + 分割 `btoa` に変更し、失敗時は全艦隊エラーコード E2005 を表示する。
