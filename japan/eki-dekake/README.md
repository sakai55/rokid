# Eki Dekake（駅のお出かけ）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-eki-dekake
```

**AIX 直接ダウンロード**（最新版）：[eki-dekake.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/eki-dekake.aix)

JP20・日本在地 × カーブカット × 指向性。精品ラインの統合リメイク：JP14 `kasa-share`（駅前シェア傘帳簿）と JP16 `eki-barrier`（駅の昇降機の側の確認）を同一の場面で統合したもの。元の 2 つの Agent はそのまま封印され、削除も変更もしない。一文の場面：雨の日や初めての駅で、移動に困難のある人がグラス上で 1 回分の駅のお出かけを完了する——昇降機のある側を見つけ → シェア傘を借り → 返却期限を守り → 返却を確認し、セッションをまたぐお出かけ記録を残す。

## プレビュー画像

![プレビュー-index](<../../screenshots/eki-dekake/preview-eki-dekake-index.png>)
![プレビュー-kasa](<../../screenshots/eki-dekake/preview-eki-dekake-kasa.png>)
![プレビュー-kasa-s2](<../../screenshots/eki-dekake/preview-eki-dekake-kasa-s2.png>)
![プレビュー-record](<../../screenshots/eki-dekake/preview-eki-dekake-record.png>)

## 構造と機能（閉ループ）

3 ページ構造で、形状はそれぞれ異なる（駅の出発ボード／傘フローの時計／記録ログ）：

- **駅ボード（pages/index）**：6 駅の設備の内容集が「出発ボード」として常駐——各駅に昇降機の側（左／右／中央）、昇降機の位置、傘スポット、返却期限を含む（項目数：6 駅 × 4 項目）。上下スワイプで駅を選択；AbsoluteOrientationSensor が頭の向き（左／右／正面）をリアルタイムに読み、選択した駅の昇降機の側と照らして表示する；うなずき／GO で駅を確定し「前回駅」として書き込む。
- **傘フロー（pages/kasa）**：借りる登録（確定した駅の期限の時間数から締切時刻を生成）→ 期限の見守り（30 秒ごとに残り分数を更新、大きな文字の時計）→ 返却確認（本人のボタン／うなずきで確認し、お出かけ記録に書き込んで貸出状態を消す）。
- **記録（pages/record）**：お出かけ記録の直近 5 件 ＋ 最もよく使う駅の統計。セッションをまたいで永続化（wx storage `ekiDekakeV1`）し、本人が消去できる。

方向の分担：カーブカットが「移動に困難のある人の駅のお出かけ」本体を担い、指向性が昇降機の側との照合（頭の向きセンサーの実読み）を担い、日本在地が駅の設備とシェア傘の制度の場面を担う。寄せ集めではない：3 つのうち 1 つでも欠ければ、お出かけの連鎖が 1 環切れる。

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 駅を確定（駅ボード）／傘フローでは借りる・返却の主確認 |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 駅の選択（次／前） |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | システムの戻る（子ページの BACK キーでも可） |

## 権限

なし。AbsoluteOrientationSensor と wx storage には権限の宣言は不要；TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントに効果なしと明記）。

## 誠実な境界

- 設備集は内蔵の 6 駅データで、ネットワークには接続せず、リアルタイムの変更は保証しない；傘の在庫／貸出可否は Agent は知らず、代わりに判断しない。
- センサーが使えないときは「センサーなし（手動で確認してください）」と明示し、読み取りを装わない；返却済みは本人の確認だけが記す。

## デバイスのテスト情報

| 項目 | 値 |
|---|---|
| Studio name | Eki Dekake（インポート後に記入） |
| Version / Build | 1.0.0 |
| App Category | Life（インポート時に確認） |
| Intent Description | 駅で昇降機の側を確認し、シェア傘を借りて期限内に返す |
| Agent ID | インポート後に記入 |
| 状態 | パッケージ化済み、プッシュ済み；Studio 未インポート、実機テスト未実施、未提出 |

## 審査提出資料 (Review Submission)

### Feature Description (≤500 chars)

駅のお出かけを最初から最後まで：昇降機の側・傘スポット・返却期限を載せた 6 駅の出発ボード；カウントダウンを見守る、傘の貸出から返却までのフロー；そして最もよく使う駅とともに残るお出かけ記録。昇降機の側が必要で、傘の返し忘れが許されない旅人のために作りました。

### Opening Message (≤500, Markdown)

**駅のお出かけへようこそ。** まず駅を選んでください。昇降機の側を頭の向きと照らし合わせ、傘を借りたら期限をずっと見守ります。

### Preview Media

画像 4 枚（このページのプレビュー画像）；動画は実機の段階で追加（審査提出の要件はファイル 3〜5 点、画像 ≥1・動画 ≥1）。

### Change Log

#### Build 1.0.0
- Features added：3 ページの新作（駅ボード／傘フロー／記録）；JP14＋JP16 の統合リメイク、設備の内容集 6 駅、期限の見守り、セッションをまたぐお出かけ記録。
- Improvements：なし（初版）。
- Fixes：なし（初版）。

## パッケージ化とプレビュー

- パッケージ化：`~/tools/bin/aix pack . -o eki-dekake.aix`（リポジトリの複製は `aix/eki-dekake.aix`）
- プレビュー：`~/tools/bin/aix preview . --html-out artifacts/preview.html` の後、ローカルの撮影パイプラインを通す（ポート 8902）
