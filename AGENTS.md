# 病院受付 — Agent Notes

JP44。日本在地 × 路縁坡 × 注意力

## Design contract

初めての病院で受診する高齢者が、受付と問診票と会計を忘れず受診を終える

## Counts

内容集の数：手順 6つ；チェック項目 5つ；記録は実際の条数で数える。セッションをまたぐ永続化：ストレージキー `byouinUketsukeV1`（選択手順、チェック状態、記録の配列、`lastError`）。

## Storage

ストレージキー `byouinUketsukeV1`。

## Gesture map

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |
