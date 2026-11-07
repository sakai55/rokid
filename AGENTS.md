# 駅コインロッカー - Agent Notes

JP58。日本在地 × 注意力 × 指向性。

## Design contract

駅のコインロッカーの前で、両手に荷物を持った人が、眼鏡だけで駅を選び、預け確認を一つずつ進めて荷物を預ける。

## Counts

内容集：駅 6 か所 × 預け確認 4 つ。預け記録は実数で数える。

## Storage

保存キー `ekiCoinLockerV1`（選んだ駅、駅ごとの確認ずみ項目数、預け記録の配列、lastError）。

## Gesture map

| 単指タップ | Enter | 主確認（駅の選択・預け確認） |
| 上下スワイプ | ArrowUp / ArrowDown | 駅の選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## Honest boundaries

- 料金は内蔵の見本ではなく、ロッカーの表示が正しい。
- 預けは記録のみで、ロッカーの開錠や決済はしない。
- センサーが使えないときはボタンで選ぶ。預け記録は 4 つの確認を全部終えたときだけ付く。

## Validation

- 言語純度：日本語文案、簡体字特有の字なし（静的機検）。
- 禁用名单 grep：0 命中。
- 独占の接線：pages/index/index.ink の _startSensor（存在性ガード）＋ _onYaw（±0.35 で駅を切替、まっすぐで再武装）＋ onHeadGesture('nod') が primaryTap と同じ確認。確認票は 4 つ終えたときだけ預け記録を書く（ekiCoinLockerV1）。
- センサー読取失敗は E7001。
