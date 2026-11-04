# 鍋料理ステップ - Agent Notes

JP55. 日本在地 × 路縁坡（手がふさがった調理者への配慮）× 注意力（手順の守候）。

## Design contract

日本の家庭で鍋料理を作る人が、両手がふさがったまま眼鏡で手順を進め、一鍋を終える。

## Counts

6段階×4手順＝24手順（下ごしらえ／だしと鍋つゆ／野菜／肉と魚介／煮込みと味見／しめと片付け）。

## Storage

保存キー `nabeCookStepsV1`（選択段階・一鍋記録・lastError）。

## Gesture map

| 単指タップ | Enter | 主確認 |
| 上下スワイプ | ArrowUp / ArrowDown | 選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## Honest boundaries

- 塩加減や火の通りは測らない。味見は本人が行う。
- 手順は家庭の鍋料理の目安で、店のレシピではない。

## Validation

- 日本語純度：簡体字特有の言い回し 0（静的検査）。
- 禁止リスト grep：0件。
- 独占接線：pages/steps/index.ink の primaryTap＋onHeadGesture。
