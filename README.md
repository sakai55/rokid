# デパ地下の買い物

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-depachika-guide
```

[depachika-guide.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/depachika-guide.aix)

## 機能

デパ地下で買い物する人が両手に袋を持ったまま、頭の向きで売り場を選び、うなずきで4つの確認を一つずつ進め、買い終えたら記録する。売り場6×確認4の24点。

## シーン

デパ地下で買い物する人が両手に袋を持ったまま、頭の向きで売り場を選び、うなずきで確認を進め、買い終えたら記録する。

## 方向構成

日本在地 × 指向性（頭を向けて売り場を選ぶ）× 注意力（4項目の逐項確認）。指向性は売り場の選択を担い、注意力は確認を一つずつ進めることを担う。

## 眼鏡だけの能力

視線と頭の方向の連携：両手に袋を持っていると携帯電話を取り出せないが、頭を向けるだけで売り場が選べ、うなずくだけで確認が進み、次の確認が声で聞ける。接線：pages/index/index.ink の _startSensor（AbsoluteOrientationSensor、存在性ガード）と _onYaw（±0.35 で売り場を切替、まっすぐで再武装）＋ onHeadGesture('nod') が primaryTap と同じ確認。センサーが使えないときはボタンで選べ、センサー読取失敗は E7001 を出す。

## 正直な境界

- 値段と賞味期限は売り場の表示が正解で、なかの目録は目安です。
- 4つ確認していない売り場は記録しません。
- センサーが使えないときはボタンで売り場を選びます。

## ページ

| ページ | ページ |
|---|---|
| pages/index | 売り場 6 つの一覧、頭の向きで選ぶ |
| pages/detail | 選んだ売り場で 4 つの確認をうなずきで一つずつ進め、買い終えたら記録 |
| pages/record | 最近 6 件の買い物記録と合計 |

## 内容集

売り場 6 つ（惣菜コーナー／鮮魚コーナー／精肉コーナー／パン売り場／和菓子コーナー／洋菓子コーナー）×確認 4 つ（値段を確認した／賞味期限を確認した／保冷剤をもらった／袋に入れた）、合計 24 点。記録は件数で数える。

## セッションをまたぐ保存

保存キー `depachikaGuideV1`。選んだ売り場、売り場ごとの確認ずみ項目数、買い物記録の配列、lastError を保存する。

## 権限

権限なし。音声読み上げに権限はいらない。カメラと位置情報は使わない。

## ジェスチャー対応

| 単指タップ | Enter | 主確認（売り場の選択・確認） |
| 上下スワイプ | ArrowUp / ArrowDown | 売り場の選択切替 |
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

![preview-depachika-guide-index.png](../screenshots/depachika-guide/preview-depachika-guide-index.png)
![preview-depachika-guide-detail.png](../screenshots/depachika-guide/preview-depachika-guide-detail.png)
![preview-depachika-guide-detail-s2.png](../screenshots/depachika-guide/preview-depachika-guide-detail-s2.png)
![preview-depachika-guide-record.png](../screenshots/depachika-guide/preview-depachika-guide-record.png)

## 提審資料

### Feature Description

デパ地下で買い物する人が両手に袋を持ったまま、頭の向きで売り場を選び、うなずきで4つの確認を一つずつ進め、買い終えたら記録する。売り場6×確認4の24点。

### Opening Message

デパ地下で両手がふさがっていても大丈夫。頭を向けて売り場を選び、うなずいて確認を進めよう。

### Preview Media

[preview-depachika-guide-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/depachika-guide/preview-depachika-guide-video.mp4)
![preview-depachika-guide-index.png](../screenshots/depachika-guide/preview-depachika-guide-index.png)
![preview-depachika-guide-detail.png](../screenshots/depachika-guide/preview-depachika-guide-detail.png)
![preview-depachika-guide-record.png](../screenshots/depachika-guide/preview-depachika-guide-record.png)

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
