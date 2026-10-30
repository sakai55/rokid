# 防災避難 — Agent Notes

JP40（日本在地 × 指向性 × 路縁坡）。交互哲学：**避難場所コンパス**。一文の場面：地震のあと避難する人が、登録した避難場所へ GPS の方角と距離で向かう。

## Design contract

入り口は避難場所の登録、過程は方角と距離による帰路案内、結果は到着の記録。内容集は逐項数えられる。跨セッション永続化キー `bosaiHinanV1`。

## Page duties

- `pages/index/` 避難場所登録：GPS 保存ボタンで避難場所を保存し、緯度・経度を小数 4 桁と登録時刻で表示する。未登録のときは未登録と表示する。
- `pages/guide/` 帰路案内：現在地を測り、8 方位の方角と 10m 単位の距離を表示する。未登録のときは案内しない。「到着した」で到着を記録する。
- `pages/record/` 記録：直近 6 件の到着記録と合計件数を表示する。

## Counts

到着記録は実際の条数で数える。

## Storage

ストレージキー `bosaiHinanV1`（避難場所の緯度・経度・登録時刻、到着記録の配列、`lastError`）。

## GPS evidence

- 権限の宣言：`app.json` の `permissions` に `GEOLOCATION`。
- 位置の取得：`pages/index/index.ink` の `saveTap` と `pages/guide/index.ink` の `primaryTap` の `navigator.geolocation.getCurrentPosition` 呼び出し（存在性の守りつき。拒否は E7003、それ以外は E7002）。
- 方角の換算：`pages/guide/index.ink` の `_calc`（`Math.atan2` による方位角から 8 方位の配列 `CARD` へ換算、ハーバーサイン式で距離を 10m 単位に丸める）。

## Gesture map

| ジェスチャ | キーイベント | 役割 |
|---|---|---|
| シングルタップ | Enter | 主確認 |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 前後の項目 |
| うなずき | onHeadGesture nod | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |

## Validation notes

- ボタン形状は上辺の太い線つき角丸で、他機と共用しない。
- 色は緑色階のみ。純白と白の rgba は使わない。
- 権限は `GEOLOCATION` のみ。測位の拒否と測位の失敗は別コードで扱う。
- 誠実な境界：避難場所は本人の登録であり、公式の避難情報が優先される。距離は概算である。
