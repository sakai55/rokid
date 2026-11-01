# お正月ゲーム集

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-oshogatsu-game-shuu
```

**AIX 直接ダウンロード**（最新版）: [oshogatsu-game-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/oshogatsu-game-shuu.aix)

JP50・日本在地 × ゲーム × 指向性 × 注意力。正月の家族の待ち時間に、家族が眼鏡一本で20の正月ゲームを回す

## プレビュー画像

![preview-oshogatsu-game-shuu-index.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-index.png)
![preview-oshogatsu-game-shuu-t01.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t01.png)
![preview-oshogatsu-game-shuu-t02.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t02.png)
![preview-oshogatsu-game-shuu-t03.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t03.png)
![preview-oshogatsu-game-shuu-t04.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t04.png)
![preview-oshogatsu-game-shuu-t05.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t05.png)
![preview-oshogatsu-game-shuu-t06.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t06.png)
![preview-oshogatsu-game-shuu-t07.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t07.png)
![preview-oshogatsu-game-shuu-t08.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t08.png)
![preview-oshogatsu-game-shuu-t09.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t09.png)
![preview-oshogatsu-game-shuu-t10.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t10.png)
![preview-oshogatsu-game-shuu-t11.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t11.png)
![preview-oshogatsu-game-shuu-t12.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t12.png)
![preview-oshogatsu-game-shuu-t13.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t13.png)
![preview-oshogatsu-game-shuu-t14.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t14.png)
![preview-oshogatsu-game-shuu-t15.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t15.png)
![preview-oshogatsu-game-shuu-t16.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t16.png)
![preview-oshogatsu-game-shuu-t17.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t17.png)
![preview-oshogatsu-game-shuu-t18.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t18.png)
![preview-oshogatsu-game-shuu-t19.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t19.png)
![preview-oshogatsu-game-shuu-t20.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t20.png)
![preview-oshogatsu-game-shuu-t01-s2.png](../screenshots/oshogatsu-game-shuu/preview-oshogatsu-game-shuu-t01-s2.png)

## 方向構成

日本在地 × ゲーム × 指向性 × 注意力。

## 構造と機能

21 ページ：`pages/index/` ゲーム集一覧（ゲーム 20本を 5 本ずつ窓に表示、上下で選び Enter で開く、選んだゲームのベスト記録と記録件数を表示）。ゲームページは各一つの仕組みで内容集が互いに異なる：t01 羽根つき数え（数える・10回）、t02 すごろく進み（進む・8マス）、t03 かるた取り（選択・4問）、t04 独楽回し数え（数える・8回転）、t05 凧方向当て（方向・6回）、t06 餅つきリズム（リズム・6拍）、t07 お年玉計算（計算・4問）、t08 書初め字当て（選択・4問）、t09 獅子舞ステップ（手順再現・5手）、t10 福袋くじ（くじ・3回）、t11 門松数え（数える・6門）、t12 鏡餅積み順（順番・5品）、t13 初詣参拝順（順番確認・5手順）、t14 甘酒色当て（選択・4問・ヒントつき）、t15 雪だるま積み（積み・9層）、t16 凧糸長さ当て（長さ当て・4問）、t17 かるた読み句当て（読み句当て・4問）、t18 独楽色当て（方向色当て・5回）、t19 羽子板色当て（選択・4問）、t20 正月料理当て（ヒント当て・3問）。状態の変形をページ数に数えない。

内容集の数：正月ゲーム 20本；数える 3 ページ（目標 10回・8回転・6門）；進む 1 ページ（8マス）；選択 5 ページ（各 4問）；方向 1 ページ（6回）；リズム 1 ページ（6拍）；計算 1 ページ（4問）；手順再現 1 ページ（5手）；くじ 1 ページ（3回）；順番 1 ページ（5品）；順番確認 1 ページ（5手順）；積み 1 ページ（9層）；長さ当て 1 ページ（4問）；読み句当て 1 ページ（4問）；方向色当て 1 ページ（5回）；ヒント当て 1 ページ（3問）。セッションをまたぐ永続化：ストレージキー `oshogatsuGameShuuV1`（選択ゲーム、ベスト記録、完了記録の配列、`lastError`）。

| ゲーム | 仕組み |
|---|---|
| t01 羽根つき数え | 数える |
| t02 すごろく進み | 進む |
| t03 かるた取り | 選択 |
| t04 独楽回し数え | 数える |
| t05 凧方向当て | 方向 |
| t06 餅つきリズム | リズム |
| t07 お年玉計算 | 計算 |
| t08 書初め字当て | 選択 |
| t09 獅子舞ステップ | 手順再現 |
| t10 福袋くじ | くじ |
| t11 門松数え | 数える |
| t12 鏡餅積み順 | 順番 |
| t13 初詣参拝順 | 順番確認 |
| t14 甘酒色当て | 選択 |
| t15 雪だるま積み | 積み |
| t16 凧糸長さ当て | 長さ当て |
| t17 かるた読み句当て | 読み句当て |
| t18 独楽色当て | 方向色当て |
| t19 羽子板色当て | 選択 |
| t20 正月料理当て | ヒント当て |

眼鏡独占能力は視線と頭の向きの協調とうなずき推進：全ゲームページが helpers の `onHeadGesture` でうなずきを主操作に結び、方向系の t05・t18 は `AbsoluteOrientationSensor`（存在性守衛つき、しきい値 ±0.35）で頭の向きを読み取る。うなずきと頭の向きが遊びの必経路で、携帯を手に持つ遊び方では成立しない。

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |

## 権限

無。TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ。

## 誠実な境界

- 勝敗の判定は頭の向きと本人のうなずきによる。実際の羽根や独楽の動きを Agent は判定しない。
- 動きは分段のみ：中心→一方向→戻る→次方向。首を回す動きは一切使わない。
- 福袋くじは決まった順で出る見本であり、実際の運試しではない。

## エラーコード

失敗時はグラスの画面に裸のコードを表示し、TTS はコードだけを読み上げ、直近のエラーは永続データの `lastError` に書く（コード、本機の slug、バージョン、原文を含む）。本機で起こりうるコード：

- `E5001` 記録の保存に失敗（ストレージ書き込みで例外）
- `E5002` 記録の読み取りに失敗（読み取り／解析で例外）
- `E3005` 読み上げに失敗（TTS の speak で例外）
- `E8001` ページ遷移に失敗（navigateTo/navigateBack で例外）
- `E7001` 頭センサーに失敗（センサーが使えない／読み取りエラー。センサーがなくてもボタンで遊べる）

## 機器テスト情報

| Studio 名 | 未記入 |
| Version | 1.0.0 |
| App Category | 未記入 |
| Intent Description | 未記入 |
| Agent ID | 未記入 |
| 状態 | 未実機検証 |

## 審査提出資料

Feature Description: 正月の待ち時間に家族で遊ぶゲーム集です。羽根つき数えから正月料理当てまで20本を一冊にまとめ、頭の向きとうなずきで遊び、各ゲームのベスト記録を残します。

Opening Message: お正月ゲーム集を開きましょう。20本のゲームから選んで、頭の向きとうなずきで遊びます。

Preview Media:
- `preview-oshogatsu-game-shuu-index.png`
- `preview-oshogatsu-game-shuu-t01.png`
- `preview-oshogatsu-game-shuu-t02.png`
- `preview-oshogatsu-game-shuu-t03.png`
- `preview-oshogatsu-game-shuu-t04.png`
- `preview-oshogatsu-game-shuu-t05.png`
- `preview-oshogatsu-game-shuu-t06.png`
- `preview-oshogatsu-game-shuu-t07.png`
- `preview-oshogatsu-game-shuu-t08.png`
- `preview-oshogatsu-game-shuu-t09.png`
- `preview-oshogatsu-game-shuu-t10.png`
- `preview-oshogatsu-game-shuu-t11.png`
- `preview-oshogatsu-game-shuu-t12.png`
- `preview-oshogatsu-game-shuu-t13.png`
- `preview-oshogatsu-game-shuu-t14.png`
- `preview-oshogatsu-game-shuu-t15.png`
- `preview-oshogatsu-game-shuu-t16.png`
- `preview-oshogatsu-game-shuu-t17.png`
- `preview-oshogatsu-game-shuu-t18.png`
- `preview-oshogatsu-game-shuu-t19.png`
- `preview-oshogatsu-game-shuu-t20.png`

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 1 本以上、60 秒以内）が必要。動画は GO が実機で録画した後に追加する。

Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: なし（初版）
- Fixes: なし（初版）
