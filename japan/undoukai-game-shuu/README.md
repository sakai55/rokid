# 運動会ゲーム集

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-undoukai-game-shuu
```

[undoukai-game-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/undoukai-game-shuu.aix)

## 機能

運動会の待ち時間、家族みんなで眼鏡一台を使って運動会のゲーム20本で遊び、ゲームごとに得点を決めて、次も残る。

## シーン

運動会の待ち時間、家族みんなで眼鏡一台を使って運動会のゲームで遊び、得点を決める。

## 方向構成

日本在地 × ゲーム × 指向性 × 注意力。

## 眼鏡だけの能力

頭の方向の連携＋うなずきが主確認：両手がふさがっていても、頭を向けて向きを選び、うなずくだけで遊べる。接線：全ゲーム頁の onHeadGesture('nod') が primaryTap と同じ主確認、方向ゲーム頁 t05／t08／t13／t18 の _startSensor（AbsoluteOrientationSensor、存在性ガード）＋ _onYaw。センサーが使えないときはボタンで向きを選べ、センサー読取失敗は E7001 を出す。

## ページ

| ページ | ページ |
|---|---|
| pages/index | 20本の運動会ゲーム一覧 |
| pages/t01 | 綱引き数え |
| pages/t02 | 玉入れ数え |
| pages/t03 | 徒競走ステップ |
| pages/t04 | 借り物競争クイズ |
| pages/t05 | 騎馬戦方向当て |
| pages/t06 | 大玉転がし数え |
| pages/t07 | 障害物競走順番 |
| pages/t08 | 玉入れ方向当て |
| pages/t09 | リレー順番当て |
| pages/t10 | 綱引きリズム |
| pages/t11 | 徒競走色当て |
| pages/t12 | 玉入れ色当て |
| pages/t13 | 大玉方向当て |
| pages/t14 | 借り物計算 |
| pages/t15 | 騎馬戦ステップ |
| pages/t16 | 玉入れ計算 |
| pages/t17 | 徒競走数え |
| pages/t18 | 障害物方向当て |
| pages/t19 | リレー計算 |
| pages/t20 | 運動会記録 |

## 内容集

20本：19ゲーム（数える 4、クイズ 4、向き 4、段取り 4、算数 3）＋記録1本。数える目標 10／12／8／15、向きは1局6回、段取りは1局5手順。

## セッションをまたぐ保存

保存キー `undoukaiGameShuuV1`（選んだゲーム、ゲームごとのベスト、決まった記録、lastError）。

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

![preview-undoukai-game-shuu-index.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-index.png)
![preview-undoukai-game-shuu-t01.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t01.png)
![preview-undoukai-game-shuu-t02.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t02.png)
![preview-undoukai-game-shuu-t03.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t03.png)
![preview-undoukai-game-shuu-t04.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t04.png)
![preview-undoukai-game-shuu-t05.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t05.png)
![preview-undoukai-game-shuu-t06.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t06.png)
![preview-undoukai-game-shuu-t07.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t07.png)
![preview-undoukai-game-shuu-t08.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t08.png)
![preview-undoukai-game-shuu-t09.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t09.png)
![preview-undoukai-game-shuu-t10.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t10.png)
![preview-undoukai-game-shuu-t11.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t11.png)
![preview-undoukai-game-shuu-t12.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t12.png)
![preview-undoukai-game-shuu-t13.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t13.png)
![preview-undoukai-game-shuu-t14.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t14.png)
![preview-undoukai-game-shuu-t15.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t15.png)
![preview-undoukai-game-shuu-t16.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t16.png)
![preview-undoukai-game-shuu-t17.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t17.png)
![preview-undoukai-game-shuu-t18.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t18.png)
![preview-undoukai-game-shuu-t19.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t19.png)
![preview-undoukai-game-shuu-t20.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t20.png)
![preview-undoukai-game-shuu-t01-s2.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t01-s2.png)

## 提審資料

### Feature Description

運動会の待ち時間、家族みんなで眼鏡一台を使って運動会のゲーム20本で遊び、ゲームごとに得点を決めて、次も残る。

### Opening Message

運動会へようこそ。ゲームを選んで、うなずいて遊ぼう。得点はちゃんと残るよ。

### Preview Media

[preview-undoukai-game-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-video.mp4)
![preview-undoukai-game-shuu-index.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-index.png)
![preview-undoukai-game-shuu-t01.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t01.png)
![preview-undoukai-game-shuu-t02.png](../../screenshots/undoukai-game-shuu/preview-undoukai-game-shuu-t02.png)

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
