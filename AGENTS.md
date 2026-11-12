# デパ地下の買い物 - Agent Notes

JP63。日本在地 × 指向性 × 注意力。

## Design contract

デパ地下で買い物する人が両手に袋を持ったまま、頭の向きで売り場を選び、うなずきで確認を進め、買い終えたら記録する。

## Counts

内容集：売り場 6 つ × 確認 4 つ、合計 24 点。記録は件数で数える。

## Storage

保存キー `depachikaGuideV1`（選んだ売り場、売り場ごとの確認ずみ項目数、買い物記録の配列、lastError）。

## Gesture map

| 単指タップ | Enter | 主確認（売り場の選択・確認） |
| 上下スワイプ | ArrowUp / ArrowDown | 売り場の選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## Honest boundaries

- 値段と賞味期限は売り場の表示が正解で、なかの目録は目安です。
- 4つ確認していない売り場は記録しません。
- センサーが使えないときはボタンで売り場を選びます。

## Validation

- 言語純度：日本語文案、簡体字特有の字なし（静的機検）。
- 禁用名单 grep：0 命中。
- 独占の接線：pages/index/index.ink の _startSensor（存在性ガード）＋ _onYaw（±0.35 で売り場を切替、まっすぐで再武装）＋ onHeadGesture('nod') が primaryTap と同じ確認。確認は 4 つ終えたときだけ買い物記録を書く（depachikaGuideV1）。
- センサー読取失敗は E7001。
