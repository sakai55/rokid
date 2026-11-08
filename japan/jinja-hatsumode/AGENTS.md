# 初詣で参拝 - Agent Notes

JP59。日本在地 × 注意力 × 指向性。

## Design contract

初詣で参拝する人が、両手にお賽銭と御朱印帳を持ち、眼鏡だけで参拝所を選び、参拝手順を一つずつ確認して参拝を記録する。

## Counts

内容集：参拝所 6 か所 × 参拝手順 4 つ。参拝記録は実数で数える。

## Storage

保存キー `jinjaHatsumodeV1`（選んだ参拝所、参拝所ごとの確認ずみ手順数、参拝記録の配列、lastError）。

## Gesture map

| 単指タップ | Enter | 主確認（参拝所の選択・参拝手順） |
| 上下スワイプ | ArrowUp / ArrowDown | 参拝所の選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## Honest boundaries

- 参拝の作法は神社の掲示が正で、ここは確認の手助けだけをする。
- 参拝は記録のみで、お賽銭の納め方や御朱印の受付はしない。
- センサーが使えないときはボタンで選ぶ。参拝記録は 4 つの手順を全部終えたときだけ付く。

## Validation

- 言語純度：日本語文案、簡体字特有の字なし（静的機検）。
- 禁用名单 grep：0 命中。
- 独占の接線：pages/index/index.ink の _startSensor（存在性ガード）＋ _onYaw（±0.35 で参拝所を切替、まっすぐで再武装）＋ onHeadGesture('nod') が primaryTap と同じ確認。確認票は 4 つ終えたときだけ参拝記録を書く（jinjaHatsumodeV1）。
- センサー読取失敗は E7001。
