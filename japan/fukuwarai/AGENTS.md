# 福笑い — Agent Notes

JP46。日本在地 × ゲーム × 指向性

## Design contract

正月に家族が集まったとき、頭の向きだけで福笑いを遊ぶ

## Counts

内容集の数：パーツ 6つ；遊びは 6 置きで一局；記録は実際の条数で数える。セッションをまたぐ永続化：ストレージキー `fukuwaraiV1`（記録の配列、`lastError`）。

## Storage

ストレージキー `fukuwaraiV1`。

## Gesture map

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |
