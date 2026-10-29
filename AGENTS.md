# 投票所ガイド — Agent Notes

JP33（日本在地 × カーブカット × 注意力）。設計の考え方：**投票手順の見守り帳簿**。一文の場面：初めて投票する高齢者が、手順と持ち物を忘れずに投票を終える。

## Design contract

- 入口から過程を経て結果まで、一つの流れで繰り返し使える。内容集は一つずつ数えられる。セッションをまたぐ永続化の鍵は `touhyouGuideV1`。
- pages/index：投票手順 6 項目、持ち物 5 点、期日前投票 3 選択肢。
- pages/check：手順 6 項目＋持ち物 5 点の計 11 項目を 1 つずつチェックし、そろった時点で TTS で読み上げて完了記録を残す。
- pages/record：直近 6 件＋総数。

## 誠実な境界

README の「誠実な境界」の節を参照：記録するのは本人の手順確認だけであり、候補者名や投票内容は記録しない。

## Permissions

README の「権限」の節を参照。TTS は宿主の固定音色を使い、utterance の `lang` は設定しない。

## Gesture map

- シングルタップ Enter：主確認。上下スワイプ ArrowUp / ArrowDown：前後の項目。うなずき nod：主確認と等価。ダブルタップ Backspace：前のページに戻る。

## Validation

- 検証とパッケージの結果は精品線の台帳を参照。プレビュー画像はリポジトリの `screenshots/touhyou-guide/` に置く。
