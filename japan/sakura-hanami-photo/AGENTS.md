# 桜の花見写真 - Agent Notes

JP61。日本在地 × 指向性 × 注意力。

## Design contract

花見の観光客が、弁当と案内冊子で両手がふさがったまま、桜の名所を見てうなずくだけで写真を撮り、12の撮影点に印を付けて花見を終える。

## Counts

内容集：名所 6 か所 × 撮影点 12 か所（1 か所 2 点）。記録は実数で数える。

## Storage

保存キー `sakuraHanamiPhotoV1`（選んだ名所、撮影点ごとの印、撮影の時刻とバイト数、花見の記録の配列、lastError）。写真そのものはその場だけに置き、保存はしない。

## Gesture map

| 単指タップ | Enter | 主確認（撮影ページでは撮影） |
| 上下スワイプ | ArrowUp / ArrowDown | 名所の選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## Honest boundaries

- 写真は本人の確認だけに使う。他の人の顔を識別しないし、名所を自動で識別するとは言わない。
- 撮影なしでは完了を確認できない。印が付いていない撮影点があるときは記録を書かない。
- プレビューにカメラはないので撮影は失敗として表示し、成功したふりはしない。

## Validation

- 言語純度：日本語文案、簡体字特有の字なし（静的機検）。
- 禁用名单 grep：0 命中。
- 撮影の接線：pages/photo/index.ink の photoTap（getUserMedia＋ImageCapture.takePhoto）；Blob から data URL への変換は arrayBuffer＋分割 btoa、FileReader＝0。
- センサー読取失敗は E7001。撮影失敗は E8004／E2001／E2013。
