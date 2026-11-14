# 浅草仲見世の買い物

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-asakusa-guide
```

[asakusa-guide.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/asakusa-guide.aix)

## 機能

浅草仲見世で買い物する人が両手に袋を持ったまま、頭の向きで屋台を選び、うなずきで4つの確認を一つずつ進め、買い終えたら記録する。屋台6×確認4の24点。

## シーン

浅草仲見世で買い物する人が両手に袋を持ったまま、頭の向きで屋台を選び、うなずきで確認を進め、買い終えたら記録する。

## 方向構成

日本在地 × 指向性（頭を向けて屋台を選ぶ）× 注意力（4項目の逐項確認）× 路縁坡（両手がふさがったまま歩く買い物客）。指向性は屋台の選択を担い、注意力は確認を一つずつ進めることを担い、路縁坡は両手がふさがった状態での利用を担う。

## 眼鏡だけの能力

視線と頭の方向の連携：両手に袋を持っていると携帯電話を取り出せないが、頭を向けるだけで屋台が選べ、うなずくだけで確認が進み、次の確認が声で聞ける。接線：pages/index/index.ink の _startSensor（AbsoluteOrientationSensor、存在性ガード）と _onYaw（±0.35 で屋台を切替、まっすぐで再武装）＋ onHeadGesture('nod') が primaryTap と同じ確認。センサーが使えないときはボタンで選べ、センサー読取失敗は E7001 を出す。

## 正直な境界

- 値段と個数は屋台の表示が正解で、なかの目録は目安です。
- 4つ確認していない屋台は記録しません。
- センサーが使えないときはボタンで屋台を選びます。

## ページ

| ページ | ページ |
|---|---|
| pages/index | 屋台 6 つの一覧、頭の向きで選ぶ |
| pages/detail | 選んだ屋台で 4 つの確認をうなずきで一つずつ進め、買い終えたら記録 |
| pages/record | 最近 6 件の買い物記録と合計 |

## 内容集

屋台 6 つ（せんべい屋／人形焼き屋／雷おこし屋／手ぬぐい屋／扇子屋／土産物屋）×確認 4 つ（値段を確認した／色・柄を確認した／個数を確認した／袋に入れた）、合計 24 点。記録は件数で数える。

## セッションをまたぐ保存

保存キー `asakusaGuideV1`。選んだ屋台、屋台ごとの確認ずみ項目数、買い物記録の配列、lastError を保存する。

## 権限

権限なし。音声読み上げに権限はいらない。カメラと位置情報は使わない。

## ジェスチャー対応

| 単指タップ | Enter | 主確認（屋台の選択・確認） |
| 上下スワイプ | ArrowUp / ArrowDown | 屋台の選択切替 |
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

![preview-asakusa-guide-index.png](../screenshots/asakusa-guide/preview-asakusa-guide-index.png)
![preview-asakusa-guide-detail.png](../screenshots/asakusa-guide/preview-asakusa-guide-detail.png)
![preview-asakusa-guide-detail-s2.png](../screenshots/asakusa-guide/preview-asakusa-guide-detail-s2.png)
![preview-asakusa-guide-record.png](../screenshots/asakusa-guide/preview-asakusa-guide-record.png)

## 提審資料

### Feature Description

浅草仲見世で買い物する人が両手に袋を持ったまま、頭の向きで屋台を選び、うなずきで4つの確認を一つずつ進め、買い終えたら記録する。屋台6×確認4の24点。

### Opening Message

仲見世で両手がふさがっていても大丈夫。頭を向けて屋台を選び、うなずいて確認を進めよう。

### Preview Media

[preview-asakusa-guide-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/asakusa-guide/preview-asakusa-guide-video.mp4)
![preview-asakusa-guide-index.png](../screenshots/asakusa-guide/preview-asakusa-guide-index.png)
![preview-asakusa-guide-detail.png](../screenshots/asakusa-guide/preview-asakusa-guide-detail.png)
![preview-asakusa-guide-record.png](../screenshots/asakusa-guide/preview-asakusa-guide-record.png)

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
