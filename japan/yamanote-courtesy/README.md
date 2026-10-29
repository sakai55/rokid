# Yamanote Courtesy（通勤マナーの駅順提示）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-yamanote-courtesy
```

JP07 · 日本ローカル化シリーズ。対話の哲学：**駅名ライン図 Station Line Cue**。本 Agent はナビゲーションをしない（基盤側の AR ナビゲーションの役目）。あなたがどこにいるかは扱わず、「マナーの動作が正しい駅で発動すること」だけを扱う：固定の通勤駅順を1つ登録し（デモは山手線の品川→東京区間）、駅に着くたびにあなたがシングルタップで確認する（列車 API は存在せず、その旨を正直に明記する；GEO は大まかな照合にのみ使う）。終点の1つ前の駅で3点セットのマナーリストが自動で表示され、1件ずつうなずいて完了にする。その本体は位置そのものではなく、状況に応じた知らせのタイミングである。

## プレビュー画像

![プレビュー-index](<../../screenshots/yamanote-courtesy/preview-yamanote-courtesy-index.png>)
![プレビュー-s2](<../../screenshots/yamanote-courtesy/preview-yamanote-courtesy-s2.png>)
![プレビュー-s3](<../../screenshots/yamanote-courtesy/preview-yamanote-courtesy-s3.png>)
![プレビュー-s4](<../../screenshots/yamanote-courtesy/preview-yamanote-courtesy-s4.png>)

## 地域性

東京の通勤マナーは身体に染み付いている：リュックは前に抱える、スマホはマナーモード、降りる駅の一つ前から出口側へ寄る。できないのはマナーを知らないからではなく、スマホに集中していると本当に忘れてしまうからだ——特に終点駅で降りなければならず、乗り過ごしも怖い人にとっては。

## 機能フロー（閉じた流れ）

- 登録：固定の駅順6駅（デモ区間）、目的地は終点駅にプリセット
- 進行：ARRIVE で駅ごとに確認して進み、横線のドットがそれに合わせて移動する；GEO キーで大まかな位置情報を試しに取得して傍証にできる（失敗したら SKIP、ブロックしない）
- 発動：終点の1つ前の駅で自動的にマナーモードに入る——リュックを前に抱える／マナーモード／ドア付近への準備を、CUE またはうなずきで1件ずつ完了する

## ジェスチャ対応

| ジェスチャ（テンプル＝つるのタッチパッド） | キーイベント | 本 Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況 GO（README の機能フローと画面の guide 行を参照） |
| 上スワイプ / 下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある本 Agent 固有の定義を参照 |
| うなずき（頭が安定したとき） | `onHeadGesture('nod')` | 本 Agent の主な確認（ARRIVE と同等、guide 行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面のボタンはいずれも上記のジェスチャのミラーであり、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態マシンのデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| `GEOLOCATION` | 大まかな位置情報／高度／速度の傍証（失敗したら SKIP） |

## 誠実な境界

- 列車のリアルタイム API は一切ない：駅への到着の進行は本人の確認を基準とし、GEO は大まかな傍証にすぎない（駅間距離が短いと隣の駅と区別できないことがある）。画面と README の両方に明記している
- 駅順はデモ区間である；乗り換えと支線は未対応。路線を変えるときは開き直して新しい区間を登録する（方法は README に記載）

- TTS はホストの固定音色を使い、utterance の `lang` は決して設定しない（公式ドキュメントに効果がないと明記されている）。

## パッケージングとプレビュー

```bash
cd ~/workspace/rokid/yamanote-courtesy
~/tools/bin/aix pack . -o ../dist/yamanote-courtesy.aix
~/tools/bin/aix list ../dist/yamanote-courtesy.aix
```

## 実機テスト情報

| フィールド | 値 |
|---|---|
| Studio 名 | Yamanote Courtesy（インポート後に記入） |
| Version / Build | 1.0.2 / インポート後に記入 |
| App Category | Life |
| Intent Description | On a Tokyo commuter train: advances a registered station sequence and fires courtesy cues one stop before the destination. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 駅順に沿った通勤マナーのキュー：固定の6駅の区間を登録すると、到着はあなたのタップでのみ進みます。列車 API はなく、そのことも明言します。目的地の1つ前の駅でマナーの3点セットを表示します：リュックを前に抱える、スマホをマナーモードにする、ドア側へ寄る。ナビゲーションはしません。マナーを出すタイミングこそが仕事のすべてです。

### Opening Message

> ## Yamanote Courtesy
> 
> ナビゲーションではなく、タイミングです。いつもの区間を登録し、駅を過ぎるたびにタップしてください。あなたの駅の1つ前でお知らせします：リュックは前へ、スマホはマナーモード、ドア側へ寄りましょう。降りるときには、すでにマナー万全です。

### Preview Media

- `preview-yamanote-courtesy-index.png` — 初期状態
- `preview-yamanote-courtesy-s2.png` — デモ状態 2
- `preview-yamanote-courtesy-s3.png` — デモ状態 3
- `preview-yamanote-courtesy-s4.png` — デモ状態 4

> 正式な審査提出には3–5点のメディアファイルが必要で、動画を≥1点（≤60 s）含めること。動画は GO の実機セルフテスト時に追加で録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：駅名ライン図 Station Line Cue；横線の駅順図：ドットを連ねた路線、現在の駅は横線上で明るく表示

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）

### Change Log（Build 1.0.1）

**Features added**

- なし

**Improvements**

- ボタンを本 Agent の UI 形態に合わせて個別にデザインした（形態は設計契約を参照）。シリーズ全体で同じボタンのセットを共用しない

**Fixes**

- 色を実機の単色グリーンパネルに合わせた：元の純白 #ffffff を緑の階調に変更した（最も明るい緑 #7dff9e）。明暗は緑だけで表現する

### Change Log（Build 1.0.2）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- 言語の純化：画面と音声の文案を現地の言語に統一した（日本＝日本語 / 韓国＝韓国語）。混入していた日本語・中国語の文案（SCAN のプロンプトを含む）を1件ずつ確認して除去した
