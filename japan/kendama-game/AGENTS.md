# けんだま遊び — Agent Notes

JP52。日本在地 × ゲーム × 指向性

## Design contract

家族の集まりで、子どもが頭の向きとうなずきだけでけんだまを遊ぶ

## Counts

内容集の数：投げる回数 10投；方向 3方向；狙う方向の並び 10手。セッションをまたぐ永続化：ストレージキー `kendamaGameV1`（ベスト記録、勝負記録の配列、`lastError`）。

## Storage

ストレージキー `kendamaGameV1`。

## Gesture map

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |
