# 宅配便受け取り — Agent Notes

JP34（日本在地 × カーブカット × 注意力）。設計の考え方：**不在票からの再配達手続き帳簿**。一文の場面：両手がふさがった人が、不在票から再配達と受取方法までを決める。

## Design contract

- 入口から過程を経て結果まで、一つの流れで繰り返し使える。内容集は一つずつ数えられる。セッションをまたぐ永続化の鍵は `takkyubinUketoriV1`。
- pages/index：荷物 6 件と受取状態。
- pages/check：再配達時間帯 6 枠、受取方法 4 種類（対面、宅配ボックス、コンビニ、置き配）から選び、確認して保存すると受取記録を残す。
- pages/record：直近 6 件＋総数。

## 誠実な境界

README の「誠実な境界」の節を参照：保存は本人の手続きメモであり、配送会社への申込み完了を証明するものではない。

## Permissions

README の「権限」の節を参照。TTS は宿主の固定音色を使い、utterance の `lang` は設定しない。

## Gesture map

- シングルタップ Enter：主確認。上下スワイプ ArrowUp / ArrowDown：前後の項目。うなずき nod：主確認と等価。ダブルタップ Backspace：前のページに戻る。

## Validation

- 検証とパッケージの結果は精品線の台帳を参照。プレビュー画像はリポジトリの `screenshots/takkyubin-uketori/` に置く。
