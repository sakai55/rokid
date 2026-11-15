# 初詣の参拝手順 - Agent Notes

JP66。日本在地 × 路縁坡 × 注意力。

## Design contract

初詣に来た高齢者が両手にお守りと絵馬を持ったまま、携帯電話を取り出さずに、うなずきで6段階24歩の参拝手順を一つずつ進め、段階を終えたら参拝を記録する。

## Counts

内容集：参拝 6 段階 × 各 4 歩、合計 24 歩。記録は件数で数える。

## Storage

保存キー `hatsumodeStepsV1`（選んだ段階、段階ごとの終えた歩数、参拝記録の配列、lastError）。

## Gesture map

| 単指タップ | Enter | 主確認（段階の選択・一歩の進行） |
| 上下スワイプ | ArrowUp / ArrowDown | 段階の選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## Honest boundaries

- 参拝の作法は一般的な手順で、神社ごとの違いは境内の案内が正解です。
- 4歩を終えていない段階は記録しません。
- うなずきが使えないときはボタンで進めます。

## Validation

- 言語純度：日本語文案、簡体字特有の字なし（静的機検）。
- 禁止リスト grep：0 件。
- 独占の接線：pages/guide/index.ink の onHeadGesture('nod') が primaryTap と同じ一歩の進行で、primaryTap は次の一歩を TTS で読み上げる。段階の選択はボタンと上下スワイプのみで、頭部センサーは使わない。
