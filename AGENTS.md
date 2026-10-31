# 駅待ち合わせ — Agent Notes

JP45。日本在地 × 指向性 × 路縁坡

## Design contract

駅で待ち合わせる人が、登録した待ち合わせ場所へ GPS の方角と距離で向かう

## Counts

内容集の数：待ち合わせ場所 6つ；到着記録は実際の条数で数える。セッションをまたぐ永続化：ストレージキー `ekiShuugouV1`（待ち合わせ場所の緯度・経度・登録時刻、到着記録の配列、`lastError`）。

## Storage

ストレージキー `ekiShuugouV1`。

## Gesture map

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |
