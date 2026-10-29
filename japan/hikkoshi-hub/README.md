# 引越し手帳ハブ

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-hikkoshi-hub
```

**AIX 直接ダウンロード**（最新版）：[hikkoshi-hub.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/hikkoshi-hub.aix)

JP37 ・ 日本在地 × 集合総控 × 路縁坡 × 注意力。引越しをする人が、20の手続きと道具をひとつの手帳で進める

## プレビュー画像

![preview-hikkoshi-hub-index.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-index.png)
![preview-hikkoshi-hub-t01.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t01.png)
![preview-hikkoshi-hub-t02.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t02.png)
![preview-hikkoshi-hub-t03.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t03.png)
![preview-hikkoshi-hub-t04.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t04.png)
![preview-hikkoshi-hub-t05.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t05.png)
![preview-hikkoshi-hub-t06.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t06.png)
![preview-hikkoshi-hub-t07.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t07.png)
![preview-hikkoshi-hub-t08.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t08.png)
![preview-hikkoshi-hub-t09.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t09.png)
![preview-hikkoshi-hub-t10.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t10.png)
![preview-hikkoshi-hub-t11.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t11.png)
![preview-hikkoshi-hub-t12.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t12.png)
![preview-hikkoshi-hub-t13.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t13.png)
![preview-hikkoshi-hub-t14.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t14.png)
![preview-hikkoshi-hub-t15.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t15.png)
![preview-hikkoshi-hub-t16.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t16.png)
![preview-hikkoshi-hub-t17.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t17.png)
![preview-hikkoshi-hub-t18.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t18.png)
![preview-hikkoshi-hub-t19.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t19.png)
![preview-hikkoshi-hub-t20.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t20.png)
![preview-hikkoshi-hub-t01-s2.png](../../screenshots/hikkoshi-hub/preview-hikkoshi-hub-t01-s2.png)

## 方向構成

- 本 Agent の方向構成：日本在地 × 集合総控 × 路縁坡 × 注意力。各方向は場面の中で替えの利かない役割を担い、機能の寄せ集めではない。
- 日本在地：転出届・転入届、電気・ガス・水道、郵便転送、運転免許、健康保険、学校の転校、粗大ごみといった、日本の引越しに固有の手続きを扱う。
- 集合総控：20の道具をひとつのハブに集め、道具ごとの進み具合と全体の進み具合を一覧で示す。
- 路縁坡：手続きを小さな項目に分け、順番に確認できる形にすることで、初めての人や手順の多い人が取り残されないようにする。
- 注意力：進み具合と記録を手帳に残し、次に何をすればよいかを一目で分かるようにする。
- 場面を一言で表すと：引越しをする人が、20の手続きと道具をひとつの手帳で進める。

## 構造と機能

21 ページ：`pages/index/` ハブ（20の道具名を5件ずつ窓表示し、道具ごとの完了数と全体の進み具合を示す。上下で選び、Enter で開く）。道具ページはそれぞれ異なる仕組みを持つ。

- チェックリスト 8 ページ：t01 転出届チェック（5項目）、t02 転入届チェック（5項目）、t08 銀行住所変更（5項目）、t11 学校転校手続き（5項目）、t12 粗大ごみ申込（6項目）、t13 部屋別荷造り（6部屋）、t16 ご近所挨拶リスト（6軒）、t17 防災確認（6項目）。項目をひとつずつ切り替え、保存で手帳に記録する。
- 手順ページ 7 ページ：t03 電気手続き（4手順）、t04 ガス手続き（4手順）、t05 水道手続き（4手順）、t06 インターネット移転（4手順）、t07 郵便転送（4手順）、t09 運転免許住所変更（4手順）、t10 健康保険手続き（4手順）。手順を順番に進め、最後で完了する。
- t14 業者見積比較：3社の見積メモ（A社 85000円、B社 72000円、C社 98000円）から1社を選び、確定して保存する。
- t15 新居採寸メモ：6部屋の採寸メモを部屋ごとに確認して記録する。
- t18 当日タイムライン：8つの時間帯を順番に進める。
- t19 費用計算：業者費とその他費用を5000円ずつ調整し、合計を表示して保存する。
- t20 引越し記録：直近の記録5件と、完了した道具の数、費用合計を示し、集計を保存する。

収録内容の数：道具 20 件。チェック項目 5＋5＋5＋5＋6＋6＋6＋6＝44 項目。手順 7 ページ × 4 手順＝28 手順。見積 3 社。採寸メモ 6 部屋。時間帯 8 つ。費用項目 2 つ。セッションをまたぐ保存：保存キー `hikkoshiHubV1`（選択中の道具、道具ごとの完了数と状態、記録の配列、費用計算、見積の選択、`lastError`）。

## ジェスチャー対応表

| ジェスチャー（テンプル側タッチパッド） | キーイベント | 本 Agent での役割 |
|---|---|---|
| 1 回タップ | Enter | 主な承認操作（各ページの主ボタン） |
| 上スワイプ / 下スワイプ | ArrowUp / ArrowDown | 選択肢の切り替え / 上下の項目への移動（費用計算では金額の増減） |
| うなずき（頭が安定しているとき） | `onHeadGesture('nod')` | 主な承認操作と同等 |
| 2 回タップ | Backspace | 前のページに戻る（子ページ） |

## 権限

なし。TTS にマニフェスト権限は不要で、カメラは一切呼び出さない。

## 誠実な境界

- 手続き内容は一般的な手順の目安であり、役所・事業者の最新案内が優先です。実際の窓口、受付時間、必要書類は、利用する役所・事業者の案内で確認してください。
- 金額は利用者が入力・調整した目安であり、業者の見積そのものではありません。実際の費用は業者の見積書が正です。
- 完了数は利用者自身の確認操作による記録であり、役所や事業者への届出が済んだことの証明にはなりません。

## エラーコード

失敗した場合は眼鏡の画面に裸のコードを表示し、TTS はコードだけを読み上げ、直近のエラーを保存データの `lastError` に書き込む（含まれるのはコード、本 Agent の slug、バージョン、原文）。本 Agent で出る可能性があるコード：

- `E5001` 記録の保存に失敗（保存の書き込みで例外）
- `E5002` 記録の読み取りに失敗（読み取り / 解析で例外）
- `E3005` 読み上げに失敗（TTS の speak で例外）
- `E8001` ページ切り替えに失敗（navigateTo / navigateBack で例外）

## デバイスのテスト情報

| 項目 | 内容 |
|---|---|
| Studio 名 | 未記入 |
| Version | 1.0.0 |
| App Category | 未記入 |
| Intent Description | 未記入 |
| Agent ID | 未記入 |
| 状態 | 実機未検証 |

## 提審資料 (Review Submission)

Feature Description: 引越し手帳ハブ：引越しの手続きをひとつの手帳に集めた Agent です。転出・転入手続き、電気・ガス・水道、郵便転送などの20の道具を備え、チェックリスト、手順、見積比較、費用計算、記録で進み具合を管理します。

Opening Message: 引越しの手続きですね。20の道具をひとつの手帳に集めました。ひとつずつ進めていきましょう。

Preview Media:
- `preview-hikkoshi-hub-index.png`
- `preview-hikkoshi-hub-t01.png`
- `preview-hikkoshi-hub-t02.png`
- `preview-hikkoshi-hub-t03.png`
- `preview-hikkoshi-hub-t04.png`
- `preview-hikkoshi-hub-t05.png`
- `preview-hikkoshi-hub-t06.png`
- `preview-hikkoshi-hub-t07.png`
- `preview-hikkoshi-hub-t08.png`
- `preview-hikkoshi-hub-t09.png`
- `preview-hikkoshi-hub-t10.png`
- `preview-hikkoshi-hub-t11.png`
- `preview-hikkoshi-hub-t12.png`
- `preview-hikkoshi-hub-t13.png`
- `preview-hikkoshi-hub-t14.png`
- `preview-hikkoshi-hub-t15.png`
- `preview-hikkoshi-hub-t16.png`
- `preview-hikkoshi-hub-t17.png`
- `preview-hikkoshi-hub-t18.png`
- `preview-hikkoshi-hub-t19.png`
- `preview-hikkoshi-hub-t20.png`
- `preview-hikkoshi-hub-t01-s2.png`

> 正式な審査提出には 3–5 件のメディアファイルが必要で、動画を 1 件以上（≤60 s）含めます。動画は GO の実機録画のあとで追加します。

Change Log — Build 1.0.0:

- Features added: 初版。引越しをする人が、20の手続きと道具をひとつの手帳で進める
- Improvements: なし（初版）
- Fixes: なし（初版）
