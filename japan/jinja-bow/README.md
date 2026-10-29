# Jinja Bow（神社参拝シーケンス）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-jinja-bow
```

JP02・日本ローカライズシリーズ。インタラクション哲学：**身体そのものが入力 Ritual Sequence**。参拝の難しさは、両手を空け、目を神前に向けていなければならず、画面を見てボタンを押せないこと。この Agent は一連の手順を丸ごとグラスに入れる：あなたは頭を下げるだけ——お辞儀の深さがそのまま確認キーになる。各ステップは 1 行だけ表示され、1 つ終えて初めて次が点く。二拝は本当に 2 回お辞儀が要り、拍手のステップは手を打ってからうなずきで確認する（拍手の音は感知できない、と正直に書く）。神社を判別せず、神話も解説しない（それは慧眼 Q&A の仕事）。守るのは「順序」という 1 つだけ。

## プレビュー画像

![プレビュー-index](<../../screenshots/jinja-bow/preview-jinja-bow-index.png>)
![プレビュー-s2](<../../screenshots/jinja-bow/preview-jinja-bow-s2.png>)
![プレビュー-s3](<../../screenshots/jinja-bow/preview-jinja-bow-s3.png>)
![プレビュー-s4](<../../screenshots/jinja-bow/preview-jinja-bow-s4.png>)

## 地域性

日本の神社参拝には身体が覚えた順序がある：一の鳥居の前で一揖、手水舎で手を清め口をすすぎ、拝殿の前で鈴を鳴らし、二拝二拍手一拝。順序を間違えても失礼ではないが、心が定まらない；スマホで順序を調べるのは参拝そのものを壊してしまう。

## 機能フロー（閉ループ）

- シーケンスの見守り：6 ステップの固定シーケンス（鳥居の一揖→手水→鈴→二拝→二拍手→一拝）、現在のステップは全点灯、その他は半点灯
- 身体の確認：頭部の pitch センサーでお辞儀を測る（基準線から相対 >16° で、正面に戻ると 1 揖）、またはうなずき／シングルタップで確認。センサーがなければ自動で格下げ
- 正直な分担：拍手はセンサーで証明できないため、そのステップは本人の確認だけを受け付け、画面に「拍手は自己確認」と明記する

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（README の機能フローと画面の guide 行を参照） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある、この Agent 固有の定義を参照 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | この Agent の主確認（CONFIRM と等価。guide 行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンはすべて上記ジェスチャのミラーで、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態機械のデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | この Agent は権限を一切申請しない；TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ（該当する場合） |

## 誠実な境界

- お辞儀の角度は頭部の基準線からの相対的な pitch の変化で、礼儀の採点ではない；閾値 16° は実機での校正待ちの値で、README に明記済み
- AbsoluteOrientationSensor が使えない場合は全行程をうなずき／シングルタップの確認に格下げし、シーケンスのロジックは変わらない

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式に効果なしと明記）。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/jinja-bow
~/tools/bin/aix pack . -o ../dist/jinja-bow.aix
~/tools/bin/aix list ../dist/jinja-bow.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Jinja Bow（インポート後に記入） |
| Version / Build | 1.0.2 / インポート後に記入 |
| App Category | Life |
| Intent Description | At a Shinto shrine: walks the wearer through the visit sequence, confirming bows by head pitch. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> Rokid グラス向けの神社参拝シーケンスのコーチ：鳥居でのお辞儀、手水、鈴、二拝、二拍手、一拝。お辞儀がボタンです——頭の pitch の感知で各お辞儀を確認し、その他はうなずきかタップで確認します。画面には一度に 1 ステップだけ、両手は自由に、目は神社に。拍手は自己確認で、そう明示します。

### Opening Message

> ## Jinja Bow
> 
> 6 つのステップを 1 つずつ：鳥居でお辞儀をし、手を清め、鈴を鳴らし、二拝、二拍手、一拝。確認はお辞儀で——数えるのはボタンの押し下げではなく、あなたの頭の下がり方です。両手は儀式そのもののために自由なままです。

### Preview Media

- `preview-jinja-bow-index.png` — 初期状態
- `preview-jinja-bow-s2.png` — デモ状態 2
- `preview-jinja-bow-s3.png` — デモ状態 3
- `preview-jinja-bow-s4.png` — デモ状態 4

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO の実機テスト時に追加録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：身体そのものが入力 Ritual Sequence；縦の絵巻：左側の縦線が参拝のステップを串刺しにし、セルごとに点灯

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
