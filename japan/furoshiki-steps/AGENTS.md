# 風呂敷の包み方 - Agent Notes

JP62。日本在地 × 路縁坡 × 注意力。

## Design contract

贈り物を渡す人が、玄関や客間で風呂敷と荷物で両手がふさがったまま、眼鏡だけで包み方を選び、手順を進めて包み終えたことを記録する。

## Counts

内容集：包み方 6 種 × 手順 4 つ、合計 24 手順。記録は件数で数える。

## Storage

保存キー `furoshikiStepsV1`（選んだ包み方、包み方ごとの確認ずみ手順数、包み記録の配列、lastError）。

## Gesture map

| 単指タップ | Enter | 主確認（包み方の選択・手順） |
| 上下スワイプ | ArrowUp / ArrowDown | 包み方の選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## Honest boundaries

- 包み方の手順は目安で、布の大きさや荷物の形に合わせて加減する。
- 記録は包み終えた記録のみで、包みの出来ばえの判定はしない。
- センサーが使えないときはボタンで選ぶ。記録は 4 つの手順を全部終えたときだけ付く。

## Validation

- 言語純度：日本語文案、簡体字特有の字なし（静的機検）。
- 禁用名单 grep：0 命中。
- 独占の接線：pages/index/index.ink の _startSensor（存在性ガード）＋ _onYaw（±0.35 で包み方を切替、まっすぐで再武装）＋ onHeadGesture('nod') が primaryTap と同じ確認。確認票は 4 つ終えたときだけ包み記録を書く（furoshikiStepsV1）。
- センサー読取失敗は E7001。
