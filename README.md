# 七五三ゲーム

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-shichigosan-game
```

[shichigosan-game.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/shichigosan-game.aix)

## 機能

七五三詣での待ち時間、家族が頭の動きだけで七五三のおみくじ・千歳飴ゲームを遊び、10回で勝敗を決める。頭を向けてえらび、うなずいて決め、ベストは次も残る。

## シーン

七五三詣での待ち時間、家族が頭の動きだけで七五三のゲームを遊び、10回で勝敗を決める。

## 方向構成

日本在地 × ゲーム × 指向性。ゲームが七五三の遊びを、指向性が頭の向きでえらぶ役を担う。

## 眼鏡だけの能力

頭の方向の連携＋うなずきが主確認：両手が子の手や荷物でふさがっていても、頭を向けてえらび、うなずくだけで遊べる。接線：pages/play/index.ink の _startSensor（AbsoluteOrientationSensor、存在性ガード）＋ _onYaw（左／中／右の3区、中へ戻って再武装、一回の向きで一区だけ）＋ onHeadGesture('nod') が primaryTap と同じ主確認で決める。センサーが使えないときはボタンでえらぶ。遊びの判定はデモの判定で、ほんものの千歳飴の動きを読み取るものではない。

## ページ

| ページ | ページ |
|---|---|
| pages/index | 七五三のもの8つとベスト |
| pages/play | 10回遊び、もの合わせ、うなずいて決める、勝敗を決める |
| pages/record | 七五三ゲーム記録 |

## 内容集

七五三のもの 8つ（千歳飴／おみくじ／晴れ着／髪置き／袴着／帯解き／七五三詣で／神社参拝）× 10回固定の順番 [3, 0, 6, 1, 7, 2, 5, 4, 3, 0] — コードに書いた固定の順番。

## セッションをまたぐ保存

保存キー `shichigosanGameV1`（ベスト、終わった記録、lastError）。

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

- 得点は本物のうなずきとタップだけで決まり、作った得点はない。
- 遊びの判定はデモの判定で、ほんものの千歳飴の動きを読み取るものではなく、えらんだものが目標と合うかだけで決めます。
- 一回の向きでは一区だけ変わり、中へ戻らないとまた変えられず、くるくる回らない。
- センサーが使えないときはボタンでえらぶ。遊びの判定は変わらない。センサー失敗は E7001 を残す。

## プレビュー画像

![preview-shichigosan-game-index.png](../screenshots/shichigosan-game/preview-shichigosan-game-index.png)
![preview-shichigosan-game-play.png](../screenshots/shichigosan-game/preview-shichigosan-game-play.png)
![preview-shichigosan-game-play-s2.png](../screenshots/shichigosan-game/preview-shichigosan-game-play-s2.png)
![preview-shichigosan-game-record.png](../screenshots/shichigosan-game/preview-shichigosan-game-record.png)

## 提審資料

### Feature Description

七五三詣での待ち時間、家族が頭の動きだけで七五三のおみくじ・千歳飴ゲームを遊び、10回で勝敗を決める。頭を向けてえらび、うなずいて決め、ベストは次も残る。

### Opening Message

七五三ゲームへようこそ。向きを合わせてうなずいて遊ぼう。10回で勝敗が決まるよ。

### Preview Media

[preview-shichigosan-game-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/shichigosan-game/preview-shichigosan-game-video.mp4)
![preview-shichigosan-game-index.png](../screenshots/shichigosan-game/preview-shichigosan-game-index.png)
![preview-shichigosan-game-play.png](../screenshots/shichigosan-game/preview-shichigosan-game-play.png)
![preview-shichigosan-game-play-s2.png](../screenshots/shichigosan-game/preview-shichigosan-game-play-s2.png)

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
