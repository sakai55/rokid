# 風呂敷の包み方

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-furoshiki-steps
```

[furoshiki-steps.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/furoshiki-steps.aix)

## 機能

贈り物を風呂敷で包む人が、布と荷物で両手がふさがったまま、頭の向きで包み方を選び、うなずきで手順を一つずつ進め、一包みできたら記録する。6種の包み方×各4手順の24手順を、声で次の手順を聞きながら進める。

## シーン

贈り物を渡す人が、玄関や客間で風呂敷と荷物で両手がふさがったまま、眼鏡だけで包み方を選び、手順を進めて包み終えたことを記録する。

## 方向構成

日本在地 × 路縁坡（両手がふさがった風呂敷包みの手助け）× 注意力（6種24手順の見守り）。路縁坡は両手ふさがりでも手順が進む仕組みを担い、注意力は手順の逐項確認を担う。

## 眼鏡だけの能力

目の前での手順案内＋両手がふさがったときのうなずき推進：布と荷物で両手がふさがっていても、頭を向けるだけで包み方が選べ、うなずくだけで手順が進み、次の手順が声で聞ける。接線：pages/index/index.ink の _startSensor（AbsoluteOrientationSensor、存在性ガード）と _onYaw（±0.35 で包み方を切替、まっすぐで再武装）＋ onHeadGesture('nod') が primaryTap と同じ確認。センサーが使えないときはボタンで選べ、センサー読取失敗は E7001 を出す。

## 正直な境界

- 包み方の手順は目安で、布の大きさや荷物の形に合わせて加減する。
- 記録は包み終えた記録のみで、包みの出来ばえの判定はしない。
- センサーが使えないときはボタンで選ぶ。記録は 4 つの手順を全部終えたときだけ付く。

## ページ

| ページ | ページ |
|---|---|
| pages/index | 包み方 6 種の一覧、頭の向きで選ぶ |
| pages/confirm | 選んだ包み方と手順 4 つをうなずきで逐項確認し、包み終えたら記録 |
| pages/record | 最近 6 件の包み記録と合計 |

## 内容集

包み方 6 種（本包み／花包み／瓶包み／箱包み／二つ包み／結び目包み）×手順 4 つ、合計 24 手順。記録は件数で数える。

## セッションをまたぐ保存

保存キー `furoshikiStepsV1`。選んだ包み方、包み方ごとの確認ずみ手順数、包み記録の配列、lastError を保存する。

## 権限

権限なし。音声読み上げに権限はいらない。カメラと位置情報は使わない。

## ジェスチャー対応

| 単指タップ | Enter | 主確認（包み方の選択・手順） |
| 上下スワイプ | ArrowUp / ArrowDown | 包み方の選択切替 |
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

![preview-furoshiki-steps-index.png](../screenshots/furoshiki-steps/preview-furoshiki-steps-index.png)
![preview-furoshiki-steps-confirm.png](../screenshots/furoshiki-steps/preview-furoshiki-steps-confirm.png)
![preview-furoshiki-steps-confirm-s2.png](../screenshots/furoshiki-steps/preview-furoshiki-steps-confirm-s2.png)
![preview-furoshiki-steps-record.png](../screenshots/furoshiki-steps/preview-furoshiki-steps-record.png)

## 提審資料

### Feature Description

贈り物を風呂敷で包む人が、布と荷物で両手がふさがったまま、頭の向きで包み方を選び、うなずきで手順を一つずつ進め、一包みできたら記録する。6種の包み方×各4手順の24手順を、声で次の手順を聞きながら進める。

### Opening Message

風呂敷包みで両手がふさがっていても大丈夫。頭を向けて包み方を選び、うなずいて手順を進めよう。

### Preview Media

[preview-furoshiki-steps-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/furoshiki-steps/preview-furoshiki-steps-video.mp4)
![preview-furoshiki-steps-index.png](../screenshots/furoshiki-steps/preview-furoshiki-steps-index.png)
![preview-furoshiki-steps-confirm.png](../screenshots/furoshiki-steps/preview-furoshiki-steps-confirm.png)
![preview-furoshiki-steps-record.png](../screenshots/furoshiki-steps/preview-furoshiki-steps-record.png)

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
