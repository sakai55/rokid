# 桜ゲーム集

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-sakura-game-shuu
```

[sakura-game-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/sakura-game-shuu.aix)

## 機能

春の花見の待ち時間、家族みんなで眼鏡一台を使って桜のゲーム20本で遊び、ゲームごとに得点を決めて、次も残る。

## シーン

春の花見の待ち時間、家族みんなで眼鏡一台を使って桜のゲームで遊び、得点を決める。

## 方向構成

日本在地 × ゲーム × 指向性 × 注意力。

## 眼鏡だけの能力

視線と頭の方向の連携＋うなずきが主確認：両手がふさがっていても、頭を向けて向きを選び、うなずくだけで遊べる。接線：全ゲーム頁の onHeadGesture('nod') が primaryTap と同じ主確認、方向ゲーム頁 g02／g07／g12／g17 の _startSensor（AbsoluteOrientationSensor、存在性ガード）＋ _onYaw。センサーが使えないときはボタンで向きを選べ、センサー読取失敗は E7001 を出す。

## ページ

| ページ | ページ |
|---|---|
| pages/index | 20本の桜ゲーム一覧 |
| pages/g01 | 桜の花数え |
| pages/g02 | 桜の向き |
| pages/g03 | 桜クイズ |
| pages/g04 | 花見弁当の段取り |
| pages/g05 | 桜の算数 |
| pages/g06 | 花びら数え |
| pages/g07 | 風の向き |
| pages/g08 | 花見クイズ |
| pages/g09 | 桜茶の段取り |
| pages/g10 | 花見の算数 |
| pages/g11 | つぼみ数え |
| pages/g12 | 枝の向き |
| pages/g13 | 桜の名所クイズ |
| pages/g14 | 桜餅の段取り |
| pages/g15 | 団子の算数 |
| pages/g16 | 桜の木数え |
| pages/g17 | 桜吹雪の向き |
| pages/g18 | 春クイズ |
| pages/g19 | 花見の片付け |
| pages/g20 | 桜の記録 |

## 内容集

20本：19ゲーム（数える 4、クイズ 4、向き 4、段取り 4、算数 3）＋記録1本。数える目標 10／12／8／15、向きは1局6回、段取りは1局5手順。

## セッションをまたぐ保存

保存キー `sakuraGameShuuV1`（選んだゲーム、ゲームごとのベスト、決まった記録、lastError）。

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

![preview-sakura-game-shuu-index.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-index.png)
![preview-sakura-game-shuu-g01.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g01.png)
![preview-sakura-game-shuu-g02.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g02.png)
![preview-sakura-game-shuu-g03.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g03.png)
![preview-sakura-game-shuu-g04.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g04.png)
![preview-sakura-game-shuu-g05.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g05.png)
![preview-sakura-game-shuu-g06.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g06.png)
![preview-sakura-game-shuu-g07.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g07.png)
![preview-sakura-game-shuu-g08.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g08.png)
![preview-sakura-game-shuu-g09.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g09.png)
![preview-sakura-game-shuu-g10.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g10.png)
![preview-sakura-game-shuu-g11.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g11.png)
![preview-sakura-game-shuu-g12.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g12.png)
![preview-sakura-game-shuu-g13.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g13.png)
![preview-sakura-game-shuu-g14.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g14.png)
![preview-sakura-game-shuu-g15.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g15.png)
![preview-sakura-game-shuu-g16.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g16.png)
![preview-sakura-game-shuu-g17.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g17.png)
![preview-sakura-game-shuu-g18.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g18.png)
![preview-sakura-game-shuu-g19.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g19.png)
![preview-sakura-game-shuu-g20.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g20.png)
![preview-sakura-game-shuu-g01-s2.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g01-s2.png)

## 提審資料

### Feature Description

春の花見の待ち時間、家族みんなで眼鏡一台を使って桜のゲーム20本で遊び、ゲームごとに得点を決めて、次も残る。

### Opening Message

桜の花見へようこそ。ゲームを選んで、うなずいて遊ぼう。得点はちゃんと残るよ。

### Preview Media

[preview-sakura-game-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/sakura-game-shuu/preview-sakura-game-shuu-video.mp4)
![preview-sakura-game-shuu-index.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-index.png)
![preview-sakura-game-shuu-g01.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g01.png)
![preview-sakura-game-shuu-g02.png](../../screenshots/sakura-game-shuu/preview-sakura-game-shuu-g02.png)

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
