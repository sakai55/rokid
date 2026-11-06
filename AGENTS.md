# 回転寿司注文 - Agent Notes

JP57。日本在地 × 注意力 × 指向性。

## Design contract

回転寿司のレーンの前で、両手に荷物と醤油皿を持った人が、眼鏡だけで寿司を選び、トッピングを一つずつ確認して注文を終える。

## Counts

内容集：寿司 6 種 × トッピング 4 つ。注文記録は実数で数える。

## Storage

保存キー `kaitenSushiOrderV1`（選んだ寿司、寿司ごとの確認ずみトッピング数、注文記録の配列、lastError）。

## Gesture map

| 単指タップ | Enter | 主確認（寿司の選択・トッピングの確認） |
| 上下スワイプ | ArrowUp / ArrowDown | 寿司の選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## Honest boundaries

- 寿司と値段は内蔵の見本で、レーンの表示が正しい。
- 注文は記録のみで、店への送信はしない。
- センサーが使えないときはボタンで選ぶ。注文記録は 4 つのトッピングを全部確認したときだけ付く。

## Validation

- 言語純度：日本語文案、簡体字特有の字なし（静的機検）。
- 禁用名单 grep：0 命中。
- 独占の接線：pages/index/index.ink の _startSensor（存在性ガード）＋ _onYaw（±0.35 で寿司を切替、まっすぐで再武装）＋ onHeadGesture('nod') が primaryTap と同じ確認。確認票は 4 つ終えたときだけ注文記録を書く（kaitenSushiOrderV1）。
- センサー読取失敗は E7001。
