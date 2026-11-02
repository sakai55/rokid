# 冬ゲーム集

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-fuyu-game-shuu
```

**AIX 直接ダウンロード**（最新版）: [fuyu-game-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/fuyu-game-shuu.aix)

AIX サイズ: 61553 B

JP53・日本在地 × ゲーム × 指向性 × 注意力。冬の家族の待ち時間に、眼鏡一本で20の冬ゲームを回す

## プレビュー画像

![preview-fuyu-game-shuu-index.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-index.png)
![preview-fuyu-game-shuu-t01.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t01.png)
![preview-fuyu-game-shuu-t02.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t02.png)
![preview-fuyu-game-shuu-t03.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t03.png)
![preview-fuyu-game-shuu-t04.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t04.png)
![preview-fuyu-game-shuu-t05.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t05.png)
![preview-fuyu-game-shuu-t06.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t06.png)
![preview-fuyu-game-shuu-t07.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t07.png)
![preview-fuyu-game-shuu-t08.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t08.png)
![preview-fuyu-game-shuu-t09.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t09.png)
![preview-fuyu-game-shuu-t10.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t10.png)
![preview-fuyu-game-shuu-t11.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t11.png)
![preview-fuyu-game-shuu-t12.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t12.png)
![preview-fuyu-game-shuu-t13.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t13.png)
![preview-fuyu-game-shuu-t14.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t14.png)
![preview-fuyu-game-shuu-t15.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t15.png)
![preview-fuyu-game-shuu-t16.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t16.png)
![preview-fuyu-game-shuu-t17.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t17.png)
![preview-fuyu-game-shuu-t18.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t18.png)
![preview-fuyu-game-shuu-t19.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t19.png)
![preview-fuyu-game-shuu-t20.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t20.png)
![preview-fuyu-game-shuu-t01-s2.png](../../screenshots/fuyu-game-shuu/preview-fuyu-game-shuu-t01-s2.png)

## 方向構成

日本在地 × ゲーム × 指向性 × 注意力。

## 構造と機能

21 ページ：`pages/index/` ゲーム集一覧（ゲーム 20本を 5 本ずつ窓に表示、上下で選び Enter で開く、選んだゲームのベスト記録と記録件数を表示）。ゲームページは各一つの仕組みで内容集が互いに異なる：t01 雪合戦数え（数える・10回）、t02 雪だるま積み（積み・6段）、t03 雪うさぎ数え（数える・10回）、t04 こたつクイズ（選択・4問）、t05 凧方向当て（方向・6回）、t06 雪かき数え（数える・10回）、t07 温泉湯気当て（選択・4問）、t08 みかん数え（数える・10回）、t09 鏡餅積み順（順番・5品）、t10 雪道歩数（数える・10歩）、t11 氷割りリズム（手順・6拍）、t12 手袋色当て（選択・4問）、t13 雪結晶当て（選択・4問）、t14 冬料理当て（選択・4問）、t15 スキー方向当て（方向・6回）、t16 スノーボード数え（数える・10回）、t17 暖房温度当て（選択・4問）、t18 雪像順番（順番・5手）、t19 冬歌ステップ（手順・5手）、t20 雪だるま色当て（選択・4問）。状態の変形をページ数に数えない。

内容集の数：冬ゲーム 20本；数える 5 ページ（各 10回・10歩）；積み 1 ページ（6段）；選択 7 ページ（各 4問）；方向 2 ページ（各 6回）；順番 2 ページ（各 5品・5手）；手順 2 ページ（6拍・5手）。セッションをまたぐ永続化：ストレージキー `fuyuGameShuuV1`（選択ゲーム、ベスト記録、完了記録の配列、`lastError`）。

| ゲーム | 仕組み |
|---|---|
| t01 雪合戦数え | 数える |
| t02 雪だるま積み | 積み |
| t03 雪うさぎ数え | 数える |
| t04 こたつクイズ | 選択 |
| t05 凧方向当て | 方向 |
| t06 雪かき数え | 数える |
| t07 温泉湯気当て | 選択 |
| t08 みかん数え | 数える |
| t09 鏡餅積み順 | 順番 |
| t10 雪道歩数 | 数える |
| t11 氷割りリズム | 手順 |
| t12 手袋色当て | 選択 |
| t13 雪結晶当て | 選択 |
| t14 冬料理当て | 選択 |
| t15 スキー方向当て | 方向 |
| t16 スノーボード数え | 数える |
| t17 暖房温度当て | 選択 |
| t18 雪像順番 | 順番 |
| t19 冬歌ステップ | 手順 |
| t20 雪だるま色当て | 選択 |

眼鏡独占能力は視線と頭の向きの協調とうなずき推進です。全ゲームページが `onHeadGesture` でうなずきを主操作に結び、方向系の t05・t15 は `AbsoluteOrientationSensor`（存在性守衛つき、しきい値 ±0.35、中央復帰必須）で頭の向きを読み取ります。うなずきと頭の向きが遊びの必経路で、携帯を手に持つ遊び方では成立しません。

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

- 勝敗の判定は頭の向きと本人のうなずきによる。実際の雪や凧やスキーの動きを Agent は判定しません。
- 動きは分段のみ：中央→一方向→中央に戻る→次方向。首を回す動きは一切使いません。
- くじや当てものは決まった順で出る見本であり、実際の運試しではありません。

## エラーコード

失敗時はグラスの画面に裸のコードを表示し、直近のエラーは永続データの `lastError` に書く（コード、本機の slug、バージョン、原文を含む）。本機で起こりうるコード：

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
| 状態 | 未導入 |


## 審査提出資料

Feature Description: 冬の家族の待ち時間に遊ぶゲーム集です。雪合戦数えから雪だるま色当てまで20本を一冊にまとめ、数える・積む・選ぶ・方向当てなど仕組みの違う遊びを収めました。頭の向きとうなずきで遊び、各ゲームのベスト記録を残します。

Opening Message: 冬ゲーム集を開きましょう。20本のゲームから選んで、頭の向きとうなずきで遊びます。

Preview Media:
- `preview-fuyu-game-shuu-video.mp4`
- `preview-fuyu-game-shuu-index.png`
- `preview-fuyu-game-shuu-t01.png`
- `preview-fuyu-game-shuu-t20.png`

Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: なし（初版）
- Fixes: なし（初版）
