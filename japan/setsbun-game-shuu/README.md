# 節分ゲーム集

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-setsbun-game-shuu
```

[setsbun-game-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/setsbun-game-shuu.aix)

## 機能

節分の待ち時間、家族みんなで眼鏡一台を使って節分のゲーム20本で遊び、ゲームごとに得点を決めて、次も残る。

## シーン

節分の待ち時間、家族みんなで眼鏡一台を使って節分のゲームで遊び、得点を決める。

## 方向構成

日本在地 × ゲーム × 指向性 × 注意力。

## 眼鏡だけの能力

頭の方向の連携＋うなずきが主確認：両手がふさがっていても、頭を向けて向きを選び、うなずくだけで遊べる。接線：全ゲーム頁の onHeadGesture('nod') が primaryTap と同じ主確認、方向ゲーム頁 t05／t08／t13／t18 の _startSensor（AbsoluteOrientationSensor、存在性ガード）＋ _onYaw。センサーが使えないときはボタンで向きを選べ、センサー読取失敗は E7001 を出す。

## ページ

| ページ | ページ |
|---|---|
| pages/index | 20本の節分ゲーム一覧 |
| pages/t01 | 豆数え |
| pages/t02 | 鬼数え |
| pages/t03 | 豆まき順番 |
| pages/t04 | 節分クイズ |
| pages/t05 | 鬼方向当て |
| pages/t06 | 恵方巻き数え |
| pages/t07 | 恵方巻き順番 |
| pages/t08 | 豆方向当て |
| pages/t09 | 鬼退治順番 |
| pages/t10 | 恵方巻き色当て |
| pages/t11 | 鬼色当て |
| pages/t12 | 豆色当て |
| pages/t13 | 恵方方向当て |
| pages/t14 | 豆計算 |
| pages/t15 | 節分ステップ |
| pages/t16 | 鬼計算 |
| pages/t17 | 福数え |
| pages/t18 | 福方向当て |
| pages/t19 | 節分計算 |
| pages/t20 | 節分記録 |

## 内容集

20本：19ゲーム（数える 4、クイズ 4、向き 4、段取り 4、算数 3）＋記録1本。数える目標 10／12／8／15、向きは1局6回、段取りは1局5手順。

## セッションをまたぐ保存

保存キー `setsbunGameShuuV1`（選んだゲーム、ゲームごとのベスト、決まった記録、lastError）。

## 権限

権限の宣言なし。音声読み上げは宿主管理で、宣言は不要。カメラと位置情報は使わない。

## ジェスチャー対応

| 単指タップ | Enter | 主確認 |
| 上下スワイプ | ArrowUp / ArrowDown | 選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## エラーコード

- `E5001` 保存の書き込み失敗
- `E5002` 保存の読み込み失敗
- `E3005` 音声読み上げ失敗
- `E8001` ページ遷移失敗
- `E7001` 頭部センサー不可または読取失敗

- 得点は本物のタップとうなずきだけで決まり、作った得点はない。
- センサーが使えないときはボタンで向きを選べ、向きゲームの遊び方自体は変わらない。

## プレビュー画像

![preview-setsbun-game-shuu-index.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-index.png)
![preview-setsbun-game-shuu-t01.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t01.png)
![preview-setsbun-game-shuu-t02.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t02.png)
![preview-setsbun-game-shuu-t03.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t03.png)
![preview-setsbun-game-shuu-t04.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t04.png)
![preview-setsbun-game-shuu-t05.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t05.png)
![preview-setsbun-game-shuu-t06.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t06.png)
![preview-setsbun-game-shuu-t07.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t07.png)
![preview-setsbun-game-shuu-t08.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t08.png)
![preview-setsbun-game-shuu-t09.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t09.png)
![preview-setsbun-game-shuu-t10.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t10.png)
![preview-setsbun-game-shuu-t11.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t11.png)
![preview-setsbun-game-shuu-t12.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t12.png)
![preview-setsbun-game-shuu-t13.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t13.png)
![preview-setsbun-game-shuu-t14.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t14.png)
![preview-setsbun-game-shuu-t15.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t15.png)
![preview-setsbun-game-shuu-t16.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t16.png)
![preview-setsbun-game-shuu-t17.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t17.png)
![preview-setsbun-game-shuu-t18.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t18.png)
![preview-setsbun-game-shuu-t19.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t19.png)
![preview-setsbun-game-shuu-t20.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t20.png)
![preview-setsbun-game-shuu-t01-s2.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t01-s2.png)

## 提審資料

### Feature Description

節分の待ち時間、家族みんなで眼鏡一台を使って節分のゲーム20本で遊び、ゲームごとに得点を決めて、次も残る。

### Opening Message

節分へようこそ。ゲームを選んで、うなずいて遊ぼう。得点はちゃんと残るよ。

### Preview Media

[preview-setsbun-game-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-video.mp4)
![preview-setsbun-game-shuu-index.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-index.png)
![preview-setsbun-game-shuu-t01.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t01.png)
![preview-setsbun-game-shuu-t02.png](../../screenshots/setsbun-game-shuu/preview-setsbun-game-shuu-t02.png)

### Change Log

- Features：初版機能は上記の通り。
- Improvements：なし。
- Fixes：なし。

## デバイス試験情報

| Studio 名 | 未記入 |
|---|---|
| Studio 名 | 未記入 |
| Version / Build | 未記入 |
| App Category | 未記入 |
| Intent Description | 未記入 |
| Agent ID | 未記入 |
| 状態 | 未記入 |
