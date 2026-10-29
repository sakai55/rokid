# Kairanban Relay（町内回覧板リレー）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-kairanban-relay
```

JP13・日本ローカライズシリーズ。インタラクション哲学：**町内リレー Neighborhood Relay**。本 Agent は回覧板の「今どこにあるか」だけを守る帳簿：4 軒の順番を一本の線にし、今持っている家を大きく表示する。受け取ったら STAMP で押印を記し、PASS で次の家へ回す。押印していないのに回そうとすると止めて声で知らせる。一周回って町内会へ戻れば周回数を数える。板の中身・お知らせの内容は一切読まず、期限は各町内会の決まりに従う（界面明示）。

## プレビュー画像

![プレビュー-index](<../../screenshots/kairanban-relay/preview-kairanban-relay-index.png>)
![プレビュー-s2](<../../screenshots/kairanban-relay/preview-kairanban-relay-s2.png>)
![プレビュー-s3](<../../screenshots/kairanban-relay/preview-kairanban-relay-s3.png>)
![プレビュー-s4](<../../screenshots/kairanban-relay/preview-kairanban-relay-s4.png>)

## 地域性

回覧板（かいらんばん）は日本の町内会・自治会の連絡制度：区役所や町内会のお知らせを一枚の板・冊子に挟み、家から家へ順番に回して全員が目を通し、最後に町内会へ戻す。回し忘れ・押印漏れが起きると「回ってこない家」が出て連絡が止まる。眼鏡は板の中身を読まない——「今どの家にあって、押印は済んだか、次はどの家か」だけを外から守る。

## 機能フロー（閉ループ）

- 順番保持：佐藤家→鈴木家→高橋家→田中家の順を線で表示し、今の家だけを満亮ドットで示す
- 押印確認：受け取った家の STAMP を本人が押して初めて PASS が進む。未押印のまま回そうとすると声で止める
- 周回計数：一周して町内会へ戻るたびに周回数 +1。板の内容は読まず、期限は町内会の決まりに従う

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（README の機能フローと画面の guide 行を参照） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある、この Agent 固有の定義を参照 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | この Agent の主確認（PASS と等価。guide 行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンはすべて上記ジェスチャのミラーで、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態機械のデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | この Agent は権限を一切申請しない；TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ（該当する場合） |

## 誠実な境界

- 回覧板の中身・お知らせ文面は Agent は読まないし記録しない。押印の有無は本人の確認結果だけを記す
- 順番・期限・回収先は各町内会の決まりに従う。本 Agent は決まりを作らないし、回収日を自動で知らせない
- 家名は仮の表示順であり、実際の町内順番は本人が町内会の名簿で確認すること

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式に効果なしと明記）。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/kairanban-relay
~/tools/bin/aix pack . -o ../dist/kairanban-relay.aix
~/tools/bin/aix list ../dist/kairanban-relay.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Kairanban Relay（インポート後に記入） |
| Version / Build | 1.0.0 / インポート後に記入 |
| App Category | Life |
| Intent Description | At home in a Japanese neighbourhood: tracks which house currently holds the kairanban circular board and whether it has been stamped. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 回覧板リレー：町内の回覧板を軌道に保ちます。4 軒が 1 本の線の上に順番に並び、現在の保持者を大きく表示し、受け取った家に押印を記録し、押印が済んで初めて板は次へ進みます。板に書いてある内容は決して読みません。日程は町内会のもので、この Agent のものではありません。

### Opening Message

> ## Kairanban Relay
> 
> 回覧板が機能するのは、順番のすべての家が実際にそれを見るときだけです。私が守るのは 1 つ：板が今どこにあるか。4 軒が線の上に並び、現在の家を大きく、受け取ったら押印、そして押印の後に初めて板は進みます。板の内容は決して読みません——それは町内のもので、私のものではありません。

### Preview Media

- `preview-kairanban-relay-index.png` — 初期状態
- `preview-kairanban-relay-s2.png` — デモ状態 2
- `preview-kairanban-relay-s3.png` — デモ状態 3
- `preview-kairanban-relay-s4.png` — デモ状態 4

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO の実機テスト時に追加録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：町内リレー Neighborhood Relay；町内のルート線：家並みのドット ＋ 現在の家を大きな文字で ＋ 押印の行

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）
