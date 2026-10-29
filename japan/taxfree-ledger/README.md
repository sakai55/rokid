# Taxfree Ledger（免税ショッピング台帳）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-taxfree-ledger
```

JP11 ・ 日本ローカライズシリーズ。対話哲学：**免税台帳 Taxfree Ledger**。本 Agent は免税だけを記録する台帳だ。店舗ごとに一般物品と消耗品の2つの金額を記録し、合計が 5,000 円のライン以上になって初めてその店舗が達成とみなされ、達成後は自分自身の手で密封袋が封をされたことを確認する。店舗が変われば台帳もページを変える。達成した店舗数は別に数える。免税資格は判断しない（最終判断は店舗のレジであり、画面にも明記する）。バーコードのスキャンも商品の識別もせず、「ラインへの到達と袋の封」この2つだけを守る。

## プレビュー画像

![プレビュー-index](<../../screenshots/taxfree-ledger/preview-taxfree-ledger-index.png>)
![プレビュー-s2](<../../screenshots/taxfree-ledger/preview-taxfree-ledger-s2.png>)
![プレビュー-s3](<../../screenshots/taxfree-ledger/preview-taxfree-ledger-s3.png>)
![プレビュー-s4](<../../screenshots/taxfree-ledger/preview-taxfree-ledger-s4.png>)

## ローカル性

日本の免税ショッピング（Tax Free）は外国人旅行者が店舗でその場で適用を受ける制度だ。同じ店舗で同じ日に買い物をしてライン以上にならなければ免税にならず、消耗品は密封袋に入れなければならず、日本国内では開封できない。パスポートは店頭で提示する必要がある。最も間違えやすいのは価格ではなく、「この店舗で本当にラインに届いたか、密封袋が本当に封をされたか」だ。

## 機能の流れ（閉ループ）

- 店舗ごとの記録：同じ店舗内で一般物品と消耗品を分けて加える（それぞれ 1,000 円刻みで手動で加える）。合計をリアルタイムに 5,000 円のラインと照合する
- 密封袋の確認：合計がラインに達した後、GO／うなずきで初めて密封袋を封済みとして記録し、TTS で「日本国内では開けないでください」と1回読み上げる
- 店舗を変えての精算：店舗を変えるとき、その店舗がラインに達していれば達成店舗数 +1、達していなければ数えない。台帳ページはゼロにリセットして記録し直す

## ジェスチャー対応表

| ジェスチャー（テンプルタッチパッド） | キーイベント | 本 Agent での役割 |
|---|---|---|
| 1回タップ | Enter | 状況に応じた GO（README の機能の流れと画面の guide 行を参照） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある本 Agent 専用の定義を参照 |
| うなずき（頭が安定したとき） | `onHeadGesture('nod')` | 本 Agent の主確認（STORE と同等。guide 行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンは上記ジェスチャーのミラーであり、SPEAK（いつでも現在の状態を聞ける）と DEMO（状態遷移のデモ。終了後は実際の状態がそのまま復元される）を追加している。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | 本 Agent は権限を申請しない。TTS とセンサーはマニフェスト権限が不要で、カメラは一切呼び出さない（該当する場合） |

## 誠実な境界

- 5,000 円のラインは本台帳の目安としての合計の口径であり、実際に免税を受けられるか、分類の口径と還付手続きは店舗のレジの判断が優先する。画面にも明示する
- 密封袋が本当に封をされているか、パスポートを提示したかは、いずれも本人が確認する。Agent は確認結果を記録するだけであり、光学的な検証はしない
- 金額は手動登録（レジシステムとの連携はない）。入力を間違えたら店舗を変える前に再確認すること。ページを閉じれば台帳は忘れる

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式に効果がないと明記されている）。

## パッケージングとプレビュー

```bash
cd ~/workspace/rokid/taxfree-ledger
~/tools/bin/aix pack . -o ../dist/taxfree-ledger.aix
~/tools/bin/aix list ../dist/taxfree-ledger.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Taxfree Ledger（インポート後に記入） |
| Version / Build | 1.0.0 / インポート後に記入 |
| App Category | Life |
| Intent Description | At a tax-free shop in Japan: tallies one store purchase toward the 5,000 yen line and records the sealed-bag confirmation. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 日本の免税ショッピング台帳。店舗ごとに、一般物品と消耗品を分けて集計し、5,000 円のラインと照合する。ラインに達したら、店舗を離れる前に自分で密封袋が封をされたことを確認する。店舗はラインに達したときだけ数える。免税資格は決して判断しない——それは店舗のレジの役割だ——し、商品のスキャンや識別もしない。

### Opening Message

> ## Taxfree Ledger
> 
> 免税ショッピングで失敗するのは2つの小さなことだ。この店舗がラインに達したか、密封袋が本当に封をされているか。私は店舗ごとに1ページを保持し、一般物品と消耗品の金額を 5,000 円のラインに向けて数え、袋の封を確認したときだけその店舗を完了として記録する。最終判断はレジが行い、私ではない。

### Preview Media

- `preview-taxfree-ledger-index.png` — 初期状態
- `preview-taxfree-ledger-s2.png` — デモ状態 2
- `preview-taxfree-ledger-s3.png` — デモ状態 3
- `preview-taxfree-ledger-s4.png` — デモ状態 4

> 正式な審査提出には 3–5 個のメディアファイルが必要で、動画（≤60 s）を ≥1 本含む。動画は GO が実機で自己テストする際に後から録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：免税台帳 Taxfree Ledger。パスポート型のページ：しきい値の横バー + 店舗の3行の台帳 + 大きな文字の合計

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）
