# 桜ゲーム集 - Agent Notes

JP64. 日本在地 × ゲーム × 指向性 × 注意力。

## Design contract

春の花見の待ち時間、家族みんなで眼鏡一台を使って桜のゲームで遊び、得点を決める。

## Counts

20本：19ゲーム（数える 4、クイズ 4、向き 4、段取り 4、算数 3）＋記録1本。数える目標 10／12／8／15、向きは1局6回、段取りは1局5手順。

## Storage

保存キー `sakuraGameShuuV1`（選んだゲーム、ゲームごとのベスト、決まった記録、lastError）。

## Gesture map

| 単指タップ | Enter | 主確認 |
| 上下スワイプ | ArrowUp / ArrowDown | 選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## Honest boundaries

- 得点は本物のタップとうなずきだけで決まり、作った得点はない。
- センサーが使えないときはボタンで向きを選べ、向きゲームの遊び方自体は変わらない。

## Validation

- 日本語純度：簡体字特有の字 0、韓国語 0（静的検査）。
- 禁止リスト grep：0件。
- 独占接線：全ゲーム頁の onHeadGesture うなずきが主確認、方向頁 g02／g07／g12／g17 の _startSensor。
- 向きの命中判定：_zone（0／1／2）を ZONES.indexOf（目標）と比べ、向きの文字と直接比べない。
