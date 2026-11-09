# おせち料理の手順

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-osechi-steps
```

[osechi-steps.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/osechi-steps.aix)

## 機能

おせち料理を作る人が、両手ふさがりのまま、頭の向きで一品を選び、うなずきで手順を一つずつ進め、一品できたら記録する。6品×各4手順の24手順を、声で次の手順を聞きながら進める。

## シーン

おせち料理を作る人が、両手がふさがったまま、眼鏡だけで一品を選び、手順を進めてできあがりを記録する。

## 方向構成

日本在地 × 路縁坡（両手がふさがったおせち作りの手助け）× 注意力（6品24手順の見守り）。路縁坡は両手ふさがりでも手順が進む仕組みを担い、注意力は手順の逐項確認を担う。

## 眼鏡だけの能力

目の前での手順案内＋両手がふさがったときのうなずき推進：材料と道具で両手がふさがっていても、頭を向けるだけで一品が選べ、うなずくだけで手順が進み、次の手順が声で聞ける。接線：pages/index/index.ink の _startSensor（AbsoluteOrientationSensor、存在性ガード）と _onYaw（±0.35 で一品を切替、まっすぐで再武装）＋ onHeadGesture('nod') が primaryTap と同じ確認。センサーが使えないときはボタンで選べ、センサー読取失敗は E7001 を出す。

## 正直な境界

- おせちの味つけは家のレシピが正で、ここは手順の手助けだけをする。
- 記録はできあがりの記録のみで、味の判定はしない。
- センサーが使えないときはボタンで選ぶ。記録は 4 つの手順を全部終えたときだけ付く。

## ページ

| ページ | ページ |
|---|---|
| pages/index | 一品 6 品の一覧、頭の向きで選ぶ |
| pages/confirm | 選んだ一品と手順 4 つをうなずきで逐項確認し、できあがりを記録 |
| pages/record | 最近 6 件のできあがり記録と合計 |

## 内容集

一品 6 品（黒豆／数の子／田作り／紅白なます／伊達巻／栗きんとん）×手順 4 つ、合計 24 手順。記録は実数で数える。

## セッションをまたぐ保存

保存キー `osechiStepsV1`。選んだ一品、一品ごとの確認ずみ手順数、できあがり記録の配列、lastError を保存する。

## 権限

権限なし。音声読み上げに権限はいらない。カメラと位置情報は使わない。

## ジェスチャー対応

| 単指タップ | Enter | 主確認（一品の選択・手順） |
| 上下スワイプ | ArrowUp / ArrowDown | 一品の選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## エラーコード

- `E5001` 保存の書き込み失敗
- `E5002` 保存の読み込み失敗
- `E3005` 音声読み上げ失敗
- `E8001` ページ遷移失敗
- `E7001` 頭部センサー不可または読取失敗

失敗したときは画面に裸のコードを出し、lastError にコード・slug・バージョン・原文を残す。

## プレビュー画像

![preview-osechi-steps-index.png](../screenshots/osechi-steps/preview-osechi-steps-index.png)
![preview-osechi-steps-confirm.png](../screenshots/osechi-steps/preview-osechi-steps-confirm.png)
![preview-osechi-steps-confirm-s2.png](../screenshots/osechi-steps/preview-osechi-steps-confirm-s2.png)
![preview-osechi-steps-record.png](../screenshots/osechi-steps/preview-osechi-steps-record.png)

## 提審資料

### Feature Description

おせち料理を作る人が、両手ふさがりのまま、頭の向きで一品を選び、うなずきで手順を一つずつ進め、一品できたら記録する。6品×各4手順の24手順を、声で次の手順を聞きながら進める。

### Opening Message

おせち作りで両手がふさがっていても大丈夫。頭を向けて一品を選び、うなずいて手順を進めよう。

### Preview Media

[preview-osechi-steps-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/osechi-steps/preview-osechi-steps-video.mp4)
![preview-osechi-steps-index.png](../screenshots/osechi-steps/preview-osechi-steps-index.png)
![preview-osechi-steps-confirm.png](../screenshots/osechi-steps/preview-osechi-steps-confirm.png)
![preview-osechi-steps-record.png](../screenshots/osechi-steps/preview-osechi-steps-record.png)

### Change Log

- Features：初版機能は上記の通り。
- Improvements：なし。
- Fixes：なし。

## デバイス試験情報

| 項目 | 内容 |
|---|---|
| Studio 名 | 未記入 |
| Version / Build | 未記入 |
| App Category | 未記入 |
| Intent Description | 未記入 |
| Agent ID | 未記入 |
| 状態 | 未記入 |
