# 銀行ATM案内

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-ginkou-atm-guide
```

[ginkou-atm-guide.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/ginkou-atm-guide.aix)

## 機能

銀行のATMの前で、両手に荷物を持った人が、頭を向けて手続きを選び、うなずいて一つずつ確かめ、終わったら記録を残す。手続き6つ×確かめること4つ、全部で24の確かめどころ。

## シーン

銀行のATMの前で、両手に荷物を持った人が、頭を向けて手続きを選び、うなずいて一つずつ確かめ、終わったら記録を残す。

## 方向構成

日本在地 × 指向性 × 注意力 × バリアフリー。指向性は手続きを選ぶ役目、注意力は確かめることを一つずつ守る役目、バリアフリーは年を重ねた人にも分かりやすい段取りの役目。

## 眼鏡だけの能力

視線と頭の向きの合わせ技：両手に荷物を持っていても、頭を向ければ手続きが選べ、うなずくだけで一つずつ確かめられる。接線：pages/index/index.ink の _startSensor（AbsoluteOrientationSensor、存在性ガード）＋ _onYaw（±0.35 で手続きを替え、正面に戻ると再び構える）＋ onHeadGesture('nod') が主確認と同じ。センサーが使えないときはボタンで手続きを選べ、センサー読取失敗は E7001 を出す。

## ページ

| ページ | ページ |
|---|---|
| pages/index | 手続き6つ一覧、頭を向けて選ぶ |
| pages/guide | 選んだ手続きで4つの確かめをうなずいて一つずつ終え、ATM案内の記録へ |
| pages/record | 直近6件のATM案内の記録と合計 |

## 内容集

手続き6つ（引き出し／預け入れ／振り込み／残高照会／通帳記帳／暗証番号変更）×確かめること4つ（案内を読んだ／金額を確かめた／暗証番号を入れた／明細を受け取った）、全部で24の確かめどころ。記録は件数で数える。

## セッションをまたぐ保存

保存キー `ginkouAtmGuideV1`（選んだ手続き、手続きごとの確かめた数、ATM案内の記録、lastError）。

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

- 手続きの中身は案内どおりで、銀行ごとの画面とちがうところがある。
- お金の動きはこの台では行わない。ATMの画面が正しい。
- センサーが使えないときはボタンで手続きを選べる。

## プレビュー画像

![preview-ginkou-atm-guide-index.png](../screenshots/ginkou-atm-guide/preview-ginkou-atm-guide-index.png)
![preview-ginkou-atm-guide-guide.png](../screenshots/ginkou-atm-guide/preview-ginkou-atm-guide-guide.png)
![preview-ginkou-atm-guide-guide-s2.png](../screenshots/ginkou-atm-guide/preview-ginkou-atm-guide-guide-s2.png)
![preview-ginkou-atm-guide-record.png](../screenshots/ginkou-atm-guide/preview-ginkou-atm-guide-record.png)

## 提審資料

### Feature Description

銀行のATMの前で、両手に荷物を持った人が、頭を向けて手続きを選び、うなずいて一つずつ確かめ、終わったら記録を残す。手続き6つ×確かめること4つ、全部で24の確かめどころ。

### Opening Message

銀行のATMへようこそ。頭を向けて手続きを選び、うなずいて確かめよう。

### Preview Media

[preview-ginkou-atm-guide-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/ginkou-atm-guide/preview-ginkou-atm-guide-video.mp4)
![preview-ginkou-atm-guide-index.png](../screenshots/ginkou-atm-guide/preview-ginkou-atm-guide-index.png)
![preview-ginkou-atm-guide-guide.png](../screenshots/ginkou-atm-guide/preview-ginkou-atm-guide-guide.png)
![preview-ginkou-atm-guide-guide-s2.png](../screenshots/ginkou-atm-guide/preview-ginkou-atm-guide-guide-s2.png)

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
