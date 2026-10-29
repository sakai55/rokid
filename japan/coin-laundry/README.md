# Coin Laundry（コインランドリー見守り Laundry Watch）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-coin-laundry
```

JP18・日本在地 × カーブカット × 注意力（WATCH）。コインランドリーで終了音が聞こえにくい人が視覚カウントダウンで取り忘れを防ぐ。インタラクション哲学：**コインランドリー見守り Laundry Watch**。

## プレビュー画像

![プレビュー-index](<../../screenshots/coin-laundry/preview-coin-laundry-index.png>)
![プレビュー-s2](<../../screenshots/coin-laundry/preview-coin-laundry-s2.png>)
![プレビュー-s3](<../../screenshots/coin-laundry/preview-coin-laundry-s3.png>)
![プレビュー-s4](<../../screenshots/coin-laundry/preview-coin-laundry-s4.png>)

## 方向構成

- この Agent の方向構成：日本在地 × カーブカット × 注意力（WATCH）。各方向が場面の中で代替のきかない一環を担い、機能の寄せ集めではない（日本組のコンセプトは精品ラインの複合通則で判定し、自由組のコンセプトは場面の核で主方向の番号を決める）。
- 一文の場面：コインランドリーで終了音が聞こえにくい人が視覚カウントダウンで取り忘れを防ぐ。

## 機能フロー（閉ループ）

- 入る：開くと現在の項目と進捗が表示され、現在の項目が視線の中央に大きく出る。
- 過程：NEXT で次の項目を選び、TAKEN で現在の項目を確認し、PREV で前の項目に戻る；うなずき（頭が静止したとき）は主確認と等価；SPEAK でいつでも現在の状態を読み上げる。
- 結果：すべての項目を確認すると 1 周（周回／完了数 +1）と数え、繰り返し使える；DEMO は状態機械のデモで、終了後は実際の状態がそのまま復元される。

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（現在の項目の確認／読み上げ） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある、この Agent 固有の定義を参照 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | この Agent の主確認（TAKEN と等価） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンはすべて上記ジェスチャのミラーで、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態機械のデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | この Agent は権限を一切申請しない；TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ |

## 誠実な境界

- 終了時刻は本人の登録と確認だけによる。店舗の機械と連動しない。
- 取り出し済みは本人の確認だけが記す。

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントに効果なしと明記）。
- グリーンの階調：CSS はグリーンの階調のみを使い、純白と白色の rgba は禁止；ボタンのスタイルはこの Agent の UI 形状に合わせて決め、デフォルトのボタンを共有しない。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/git-rokid/japan/coin-laundry
~/tools/bin/aix pack . -o ../../aix/coin-laundry.aix
~/tools/bin/aix list ../../aix/coin-laundry.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Coin Laundry（インポート後に記入） |
| Version / Build | 1.0.0 / インポート後に記入 |
| App Category | Life |
| Intent Description | Coin laundry: a visual watch for people who cannot hear the finish buzzer. Register each machine, watch its state in sight, and mark it taken only when the laundry is really out. It never hears anything for you. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> コインランドリー：終了ブザーが聞こえない人のための視覚的な見守り。各機械を登録し、状態を視界の中で見守り、洗濯物が本当に出てきたときだけ「取り出し済み」と印を付けます。あなたの代わりに何かを聞き取ることは決してしません。

### Opening Message

> ## Coin Laundry
>
> コインランドリー：終了ブザーが聞こえない人のための視覚的な見守り。各機械を登録して状態を見守り、洗濯物が本当に出たときだけ取り出し済みと記します。代わりに聞き取ることはありません。

### Preview Media

- `preview-coin-laundry-index.png` — 初期状態
- `preview-coin-laundry-s2.png` — デモ状態 2
- `preview-coin-laundry-s3.png` — デモ状態 3
- `preview-coin-laundry-s4.png` — デモ状態 4

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO の実機テスト時に追加録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：コインランドリー見守り Laundry Watch；コインランドリーで終了音が聞こえにくい人が視覚カウントダウンで取り忘れを防ぐ

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）
