# 秋ゲーム集

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-aki-matsuri-game-shuu
```

[aki-matsuri-game-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/aki-matsuri-game-shuu.aix)

## 概要

JP54 aki-matsuri-game-shuu — 日本在地 × ゲーム × 指向性 × 注意力。秋祭りの待ち時間に、家族が眼鏡一本で20本の秋ゲームを回します。

## 場面

秋祭りの待ち時間、家族が眼鏡一本を回して遊びます。集でゲームを選び、うなずきで遊び、1本ごとにベスト記録と完了記録が残ります。

## 方向構成

日本在地（秋祭り・月見・収穫の暮らし）× ゲーム（20本の遊び）× 指向性（方向当て2本で頭の向きが入力）× 注意力（数える・順番・クイズで集中して追う）。方向当てがなければ集はただのゲーム一覧になり、数え・順番・クイズがなければ待ち時間の遊びとして続きません。

## 眼鏡専用能力

うなずき主確認（全ページ）と頭の向き入力（方向ゲーム2本）。集もゲームも、うなずきで進みます。方向ゲームでは頭の向きがそのまま選択になり、中央に戻さないと次を選べません。携帯電話を手に持って同じことをすると、祭りの待ち時間に両手がふさがります。

接線証拠：全ページの `onHeadGesture` が `nod` を `primaryTap` に渡します。方向ゲーム `pages/t04/index.ink` と `pages/t17/index.ink` の `_startSensor` が `AbsoluteOrientationSensor`（`typeof` 守衛つき）の yaw から左右・中央を決め、±0.35 を超えたら選び、中央に戻るまで次を選べません。センサーが無い場合はボタンで向きを変える兜底があります。

## ページ

| ページ | 役割 |
|---|---|
| pages/index | 20本のゲーム一覧とベスト記録 |
| pages/t01 | 月見数え（10まで数える） |
| pages/t02 | 栗拾い数え（12まで数える） |
| pages/t03 | 紅葉色当て（3問） |
| pages/t04 | 秋刀魚方向当て（頭の向き6回） |
| pages/t05 | 収穫クイズ（3問） |
| pages/t06 | きのこ数え（8まで数える） |
| pages/t07 | 団子積み順（5段を順番に） |
| pages/t08 | コスモス色当て（3問） |
| pages/t09 | 稲刈りリズム（8拍） |
| pages/t10 | ハロウィン仮装当て（2択3問） |
| pages/t11 | さつまいも数え（15まで数える） |
| pages/t12 | ぶどう色当て（3問） |
| pages/t13 | 月見団子計算（3問） |
| pages/t14 | 紅葉ステップ（5手の順番） |
| pages/t15 | 秋祭りくじ（3回引く） |
| pages/t16 | 柿数え（9まで数える） |
| pages/t17 | すすき方向当て（頭の向き6回） |
| pages/t18 | 秋の味覚当て（3問） |
| pages/t19 | 焼き芋数え（7まで数える） |
| pages/t20 | 紅葉狩り記録（まとめ記録を残す） |

## 内容集

秋ゲーム20本。数える6本（目標10・12・8・15・9・7）、色当て・クイズ・計算7本（各3問）、順番2本（各5手）、方向当て2本（各6回）、リズム1本（8拍）、くじ1本（3回）、まとめ記録1本。内容は各ページのコードに数えられます。

## 永続化

ストレージキー `akiMatsuriGameShuuV1`。選んだゲーム、各ゲームのベスト記録とベスト点、完了記録の配列、`lastError` を保存します。

## 権限

権限は使いません。位置情報・カメラは使いません。

## ジェスチャ

| ジェスチャ | キー | 役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |

## エラーコード

- `E5001` 保存の書き込み失敗
- `E5002` 保存の読み取り失敗
- `E3005` 音声案内失敗
- `E8001` ページ移動失敗
- `E7001` 頭の向きセンサー失敗（方向ゲームのみ）

失敗時は画面に裸のコードだけを表示し、`lastError` にコード・slug・バージョン・原文を残します。

## プレビュー画像

![preview-aki-matsuri-game-shuu-index.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-index.png)
![preview-aki-matsuri-game-shuu-t01.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t01.png)
![preview-aki-matsuri-game-shuu-t02.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t02.png)
![preview-aki-matsuri-game-shuu-t03.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t03.png)
![preview-aki-matsuri-game-shuu-t04.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t04.png)
![preview-aki-matsuri-game-shuu-t05.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t05.png)
![preview-aki-matsuri-game-shuu-t06.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t06.png)
![preview-aki-matsuri-game-shuu-t07.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t07.png)
![preview-aki-matsuri-game-shuu-t08.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t08.png)
![preview-aki-matsuri-game-shuu-t09.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t09.png)
![preview-aki-matsuri-game-shuu-t10.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t10.png)
![preview-aki-matsuri-game-shuu-t11.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t11.png)
![preview-aki-matsuri-game-shuu-t12.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t12.png)
![preview-aki-matsuri-game-shuu-t13.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t13.png)
![preview-aki-matsuri-game-shuu-t14.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t14.png)
![preview-aki-matsuri-game-shuu-t15.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t15.png)
![preview-aki-matsuri-game-shuu-t16.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t16.png)
![preview-aki-matsuri-game-shuu-t17.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t17.png)
![preview-aki-matsuri-game-shuu-t18.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t18.png)
![preview-aki-matsuri-game-shuu-t19.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t19.png)
![preview-aki-matsuri-game-shuu-t20.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t20.png)
![preview-aki-matsuri-game-shuu-t01-s2.png](../screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-t01-s2.png)

## 提審資料

### Feature Description

秋祭りの待ち時間に、家族が眼鏡一本で20本の秋ゲームを回します。数える・色当て・方向当て・クイズ・順番・リズム・くじ・計算・記録の各ゲームで遊び、1本ごとにベスト記録と完了記録が残ります。頭の向きとうなずきだけで進められます。

### Opening Message

秋ゲーム集へようこそ。上下でゲームを選んで、うなずきで開いてください。数えるゲームはうなずきで数え、方向ゲームは頭の向きで選びます。遊び終わると記録に残ります。

### Preview Media

[preview-aki-matsuri-game-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/aki-matsuri-game-shuu/preview-aki-matsuri-game-shuu-video.mp4) ＋ 画像3枚（preview-aki-matsuri-game-shuu-index.png、preview-aki-matsuri-game-shuu-t01-s2.png、preview-aki-matsuri-game-shuu-t04.png）、合計4ファイル。

### Change Log

- Features added: 秋ゲーム20本（数える・色当て・方向当て・クイズ・順番・リズム・くじ・計算・まとめ記録）、ベスト記録と完了記録の永続化。
- Improvements: なし（初版）。
- Fixes: なし（初版）。

## 設備テスト情報

| 項目 | 値 |
|---|---|
| Studio名 | 未入力 |
| バージョン | 1.0.0 |
| カテゴリ | 未入力 |
| Intent説明 | 未入力 |
| Agent ID | 未入力 |
| 状態 | 未インポート |
