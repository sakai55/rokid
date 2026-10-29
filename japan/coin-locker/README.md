# Coin Locker（駅のコインロッカー預け帳）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-coin-locker
```

JP05・日本ローカライズシリーズ。インタラクション哲学：**預けロッカー帳 Locker Ledger**。この Agent がするのは 1 枚の預け帳だけ：預け入れのときにロッカー番号を登録し（スワイプで番号選択）、中身を 1 件（ITEM で切替）、場所は状態の中に固定で明記する；保管中はこの 3 つだけを表示する；取り出すときは先に中身の名前を提示して確認してもらい、TAKE で初めて取り出し完了と記録する。空きロッカーを探す手伝いはしない（それは駅のリアルタイム空き状況の表示を見ること）、ロッカーへの案内もしない（プラットフォームの仕事）、暗証番号の保管も代行しない——保証するのは、あなたが預けたその 1 つが、完全に記憶され、照合しながら取り出されることだけ。

## プレビュー画像

![プレビュー-index](<../../screenshots/coin-locker/preview-coin-locker-index.png>)
![プレビュー-s2](<../../screenshots/coin-locker/preview-coin-locker-s2.png>)
![プレビュー-s3](<../../screenshots/coin-locker/preview-coin-locker-s3.png>)
![プレビュー-s4](<../../screenshots/coin-locker/preview-coin-locker-s4.png>)

## 地域性

日本の駅のコインロッカーは旅行と通勤のインフラ：大きな駅では大・中・小に分かれ、Suica や現金で開錠し、超過すると日ごとに加算され、3 日取りに来なければ遺失物へ移される。預け入れの本当のリスクはロッカーが安全かどうかではなく、人が覚えていられないこと——何番のロッカーか、どの出口か、何階か、中に何を入れたか。帰りに何百ものロッカーの扉の前に立って呆然とする。

## 機能フロー（閉ループ）

- セル選択：スワイプでデモのロッカー番号を切り替え、STORE で預け入れを登録（ロッカー番号＋中身をロック）
- 保持：保管中はロッカー番号／中身／場所と加算の目安だけを表示し、急かさず邪魔しない
- 取り出し：TAKE の前に中身の名前を提示して照合し、確認後に取り出し完了と記録してセルを空にする

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（README の機能フローと画面の guide 行を参照） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある、この Agent 固有の定義を参照 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | この Agent の主確認（STORE と等価。guide 行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンはすべて上記ジェスチャのミラーで、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態機械のデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | この Agent は権限を一切申請しない；TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ（該当する場合） |

## 誠実な境界

- ロッカー番号と場所は本人が登録したメモであり、駅のシステムとのリアルタイム連動ではない；空き状況、料金、保管期限は駅の掲示が正
- デモのロッカー番号と場所は新宿駅西口の例の値。実機で使うときは実際のロッカー番号で登録すること

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式に効果なしと明記）。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/coin-locker
~/tools/bin/aix pack . -o ../dist/coin-locker.aix
~/tools/bin/aix list ../dist/coin-locker.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Coin Locker（インポート後に記入） |
| Version / Build | 1.0.1 / インポート後に記入 |
| App Category | Life |
| Intent Description | At a Japanese station: remembers coin-locker number and stored item until verified pickup. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> コインロッカー：日本向けの駅のコインロッカー帳。預けたロッカーの番号と、その 1 件の中身を登録すると、Agent はその番号・中身・場所だけを取り出しまで保持し、取り出しのときに中身の名前を示して確認してから、ロッカーが空になったと印を付けます。ロッカーの空き状況のライブ表示も、戻る案内も、暗証番号の保管もありません。

### Opening Message

> ## Coin Locker
> 
> 何百もの同じ扉、その中であなたのものは忘れてしまったその 1 つ。私に預けてください：ロッカーの番号、何を入れたか、ロッカーの列がどこにあるか。取り出しのときは先に中身の名前を示します——確認してから、取り出してください。

### Preview Media

- `preview-coin-locker-index.png` — 初期状態
- `preview-coin-locker-s2.png` — デモ状態 2
- `preview-coin-locker-s3.png` — デモ状態 3
- `preview-coin-locker-s4.png` — デモ状態 4

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO の実機テスト時に追加録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：預けロッカー帳 Locker Ledger；ロッカーのセル：扉番号の配列＋大きなロッカー番号＋中身／場所の行

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）

### Change Log（Build 1.0.1）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- 言語の純化：画面と音声の文言を現地言語に統一（日本＝日本語／韓国＝韓国語）し、混入していた日本語・中国語の文言（SCAN のプロンプトを含む）を 1 つずつ調べて除去
