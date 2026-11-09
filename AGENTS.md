# おせち料理の手順 - Agent Notes

JP60。日本在地 × 路縁坡 × 注意力。

## Design contract

おせち料理を作る人が、両手ふさがりのまま、眼鏡だけで一品を選び、手順を一つずつ進めてできあがりを記録する。

## Counts

内容集：一品 6 品 × 手順 4 つ、合計 24 手順。記録は実数で数える。

## Storage

保存キー `osechiStepsV1`（選んだ一品、一品ごとの確認ずみ手順数、できあがり記録の配列、lastError）。

## Gesture map

| 単指タップ | Enter | 主確認（一品の選択・手順） |
| 上下スワイプ | ArrowUp / ArrowDown | 一品の選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## Honest boundaries

- おせちの味つけは家のレシピが正で、ここは手順の手助けだけをする。
- 記録はできあがりの記録のみで、味の判定はしない。
- センサーが使えないときはボタンで選ぶ。記録は 4 つの手順を全部終えたときだけ付く。

## Validation

- 言語純度：日本語文案、簡体字特有の字なし（静的機検）。
- 禁用名单 grep：0 命中。
- 独占の接線：pages/index/index.ink の _startSensor（存在性ガード）＋ _onYaw（±0.35 で一品を切替、まっすぐで再武装）＋ onHeadGesture('nod') が primaryTap と同じ確認。確認票は 4 つ終えたときだけできあがり記録を書く（osechiStepsV1）。
- センサー読取失敗は E7001。
