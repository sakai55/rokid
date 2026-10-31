# 郵便局手続き — Agent Notes

JP43。日本在地 × 路縁坡 × 注意力

## Design contract

郵便局で手続きする高齢者が、書類と手順を忘れず手続きを終える

## Counts

内容集の数：手続き 6つ；チェック項目 5つ；記録は実際の条数で数える。セッションをまたぐ永続化：ストレージキー `yuubinKyokuV1`（選択手続き、チェック状態、記録の配列、`lastError`）。

## Storage

ストレージキー `yuubinKyokuV1`。

## Gesture map

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |
