# 日本旅行手帳

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-nihon-tabi-hub
```

**AIX 直接ダウンロード**（最新版）：[nihon-tabi-hub.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/nihon-tabi-hub.aix)

JP42 · 日本在地 × 集合総控 × 注意力。日本を旅する人が20の旅行道具を一本の手帳で回し終える。

## プレビュー画像

![preview-nihon-tabi-hub-index.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-index.png)
![preview-nihon-tabi-hub-t01.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t01.png)
![preview-nihon-tabi-hub-t02.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t02.png)
![preview-nihon-tabi-hub-t03.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t03.png)
![preview-nihon-tabi-hub-t04.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t04.png)
![preview-nihon-tabi-hub-t05.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t05.png)
![preview-nihon-tabi-hub-t06.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t06.png)
![preview-nihon-tabi-hub-t07.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t07.png)
![preview-nihon-tabi-hub-t08.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t08.png)
![preview-nihon-tabi-hub-t09.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t09.png)
![preview-nihon-tabi-hub-t10.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t10.png)
![preview-nihon-tabi-hub-t11.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t11.png)
![preview-nihon-tabi-hub-t12.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t12.png)
![preview-nihon-tabi-hub-t13.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t13.png)
![preview-nihon-tabi-hub-t14.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t14.png)
![preview-nihon-tabi-hub-t15.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t15.png)
![preview-nihon-tabi-hub-t16.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t16.png)
![preview-nihon-tabi-hub-t17.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t17.png)
![preview-nihon-tabi-hub-t18.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t18.png)
![preview-nihon-tabi-hub-t19.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t19.png)
![preview-nihon-tabi-hub-t20.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t20.png)
![preview-nihon-tabi-hub-t01-s2.png](../../screenshots/nihon-tabi-hub/preview-nihon-tabi-hub-t01-s2.png)

## 方向構成

- この Agent の方向構成：日本在地 × 集合総控 × 注意力。各方向は場面の中で代わりのきかない一環を担い、機能の寄せ集めではありません。
- 日本在地：新幹線・在来線の乗換、宿泊、土産、城・庭園・博物館・水族館・市場・駅弁といった、日本の旅の場面だけを扱います。画面の文言はすべて日本語です。
- 集合総控：旅行道具20種を一冊の手帳に集め、ハブが各道具の進み具合と記録の件数を一目で示します。
- 注意力：チェックリストで忘れ物を防ぎ、数え上げで散策と乗換の確認を最後まで見届け、記録ページで旅の足跡を振り返ります。
- 一文の場面：日本を旅する人が20の旅行道具を一本の手帳で回し終える。

## 構造と機能

21ページ：`pages/index/` は旅行手帳のハブ（道具名20種を現在位置の前後5件の窓で表示、上下で選び、決定で開く。各道具の済み数と総数、全体の進み具合、記録の件数を表示）。道具ページはそれぞれ一つの働きです。チェックリスト11ページ（項目ごとにうなずきで確認し、すべて済むと完了記録）、選択式クイズ4ページ（各3問・3択、正誤と解説を音声で伝える）、声で伝える言葉2ページ（各定型文4つ、決定ですぐに音声で読み上げて記録）、数え上げ2ページ（目標まで数える）、記録ページ1ページ（直近6件と総件数）。各道具ページの働きと内容集は互いに異なり、状態の変化をページ数には数えません。

| 道具 | 種類 | 項目数 |
|---|---|---|
| t01 新幹線乗換 | チェックリスト | 5 |
| t02 在来線乗換 | チェックリスト | 5 |
| t03 バス路線 | チェックリスト | 4 |
| t04 宿泊チェック | チェックリスト | 5 |
| t05 お土産リスト | チェックリスト | 6 |
| t06 お城見学 | チェックリスト | 4 |
| t07 庭園散策 | 数え上げ | 目標5か所 |
| t08 博物館 | チェックリスト | 4 |
| t09 水族館 | 選択式クイズ | 3問 |
| t10 市場食べ歩き | チェックリスト | 4 |
| t11 カフェ注文 | 声で伝える言葉 | 4文 |
| t12 両替計算 | 選択式クイズ | 3問 |
| t13 天気服装 | 選択式クイズ | 3問 |
| t14 写真スポット | チェックリスト | 4 |
| t15 忘れ物チェック | チェックリスト | 6 |
| t16 緊急電話 | 声で伝える言葉 | 4文 |
| t17 駅弁選び | 選択式クイズ | 3問 |
| t18 乗換時間 | 数え上げ | 目標4回 |
| t19 荷物預かり | チェックリスト | 4 |
| t20 旅行記録 | 記録ページ | 直近6件 |

内容集の数：旅行道具20種、チェックリスト11ページ・計51項目、クイズ4ページ・計12問（各3択・計36選択肢）、定型文2ページ・計8文、数え上げ2ページ（目標5か所と4回）、記録は実際の件数で数えます。全体の進み具合は t01〜t19 の済み数の合計を 80（チェック51＋クイズ12＋定型文8＋数え上げ9）で割ったものです。t20 の済み数と総数は、表示枠6に対する直近記録数です。セッションを越える保存：保存キー `nihonTabiHubV1`（選んだ道具、道具ごとの済み数と総数、チェック・クイズ・数え上げ・伝えた言葉の状態、完了記録の配列、`lastError`）。

## ジェスチャ対応

| ジェスチャ（眼鏡のタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| 一度タップ | Enter | 主確認（各ページの主ボタン） |
| 上へ／下へスワイプ | ArrowUp / ArrowDown | 項目・選択肢の移動 |
| うなずき（頭が安定したとき） | `onHeadGesture('nod')` | 主確認と同等 |
| 二度タップ | Backspace | 前のページへもどる（道具ページ） |

数え上げページだけは例外で、上スワイプがリセット、下スワイプが数えるになります。記録ページでは上下スワイプが表示の更新になります。

## 権限

無し。音声案内と頭の動きの検出にマニフェストの権限は要らず、カメラは呼びません。

## 誠実な境界

- 各道具の案内・設問・定型文は収録済みの定型内容です。実際の時刻表・運賃・店舗の案内が基準であり、この手帳は生の時刻表や在庫の情報を出しません。
- 声で伝える言葉は、本人が選んだ定型文だけを読みます。現場で新しく作った言葉ではありません。
- クイズの解説は収録済みの説明であり、現地の最新情報の代わりにはなりません。

## エラーコード

失敗したときは画面にコードだけを示し、音声案内はコードだけを読み、直近の失敗は保存データの `lastError` に残ります（コード、この機器の slug、バージョン、原文を含みます）。この機器で出うるコード：

- `E5001` 記録の保存失敗（保存の書き込み中の例外）
- `E5002` 記録の読み込み失敗（読み込み・解析中の例外）
- `E3005` 音声案内失敗（音声読み上げ中の例外）
- `E8001` ページ移動失敗（ページ移動・もどる操作中の例外）

## 機器テスト情報

| 項目 | 内容 |
|---|---|
| Studio 名 | 記入予定 |
| Version | 1.0.0 |
| App Category | 記入予定 |
| Intent Description | 記入予定 |
| Agent ID | 記入予定 |
| 状態 | 実機検証前 |

## 提審資料 (Review Submission)

Feature Description: 日本旅行手帳：日本を旅する人のための手帳一冊。新幹線の乗換から宿泊、お土産、駅弁選びまで旅行道具20種を集め、チェックリスト、クイズ、声で伝える言葉、数え上げで進み具合と記録を端末に保存します。

Opening Message: 日本を旅しますか。旅行道具20種を一冊の手帳にまとめました。乗換も宿泊もお土産も、ここから一つずつ進めましょう。

Preview Media:
- `preview-nihon-tabi-hub-index.png`
- `preview-nihon-tabi-hub-t01.png`
- `preview-nihon-tabi-hub-t02.png`
- `preview-nihon-tabi-hub-t03.png`
- `preview-nihon-tabi-hub-t04.png`
- `preview-nihon-tabi-hub-t05.png`
- `preview-nihon-tabi-hub-t06.png`
- `preview-nihon-tabi-hub-t07.png`
- `preview-nihon-tabi-hub-t08.png`
- `preview-nihon-tabi-hub-t09.png`
- `preview-nihon-tabi-hub-t10.png`
- `preview-nihon-tabi-hub-t11.png`
- `preview-nihon-tabi-hub-t12.png`
- `preview-nihon-tabi-hub-t13.png`
- `preview-nihon-tabi-hub-t14.png`
- `preview-nihon-tabi-hub-t15.png`
- `preview-nihon-tabi-hub-t16.png`
- `preview-nihon-tabi-hub-t17.png`
- `preview-nihon-tabi-hub-t18.png`
- `preview-nihon-tabi-hub-t19.png`
- `preview-nihon-tabi-hub-t20.png`
- `preview-nihon-tabi-hub-t01-s2.png`

> 正式な提審提出にはメディアファイル3〜5点が必要で、60秒以内の動画1点以上を含まなければなりません。動画は GO が実機で録画してから追加します。

Change Log — Build 1.0.0:

- 追加した機能：旅行手帳ハブ（道具20種・5件窓・進み具合と記録件数の表示）、チェックリスト11ページ、選択式クイズ4ページ、声で伝える言葉2ページ、数え上げ2ページ、旅行記録ページ、保存キー `nihonTabiHubV1` によるセッションを越える保存。
- 改善：該当なし（初版）。
- 修正：該当なし（初版）。
