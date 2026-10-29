# Kasa Share（駅前シェア傘帳簿 Umbrella Ledger）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-kasa-share
```

**AIX 直接ダウンロード**（最新版）：[kasa-share.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/kasa-share.aix)

JP14・日本在地 × カーブカット × 注意力（HOLD/WATCH）。雨天駅前、片手・車椅子の人がシェア傘を借りて返し忘れない。インタラクション哲学：**駅前シェア傘帳簿 Umbrella Ledger**。

## プレビュー画像

![プレビュー-index](<../../screenshots/kasa-share/preview-kasa-share-index.png>)
![プレビュー-s2](<../../screenshots/kasa-share/preview-kasa-share-s2.png>)
![プレビュー-s3](<../../screenshots/kasa-share/preview-kasa-share-s3.png>)
![プレビュー-s4](<../../screenshots/kasa-share/preview-kasa-share-s4.png>)

## 方向構成

- この Agent の方向構成：日本在地 × カーブカット × 注意力（HOLD/WATCH）。各方向が場面の中で代替のきかない一環を担い、機能の寄せ集めではない（日本組のコンセプトは精品ラインの複合通則で判定し、自由組のコンセプトは場面の核で主方向の番号を決める）。
- 一文の場面：雨天駅前、片手・車椅子の人がシェア傘を借りて返し忘れない。

## 機能フロー（閉ループ）

- 入る：開くと現在の項目と進捗が表示され、現在の項目が視線の中央に大きく出る。
- 過程：NEXT で次の項目を選び、RETURN で現在の項目を確認し、PREV で前の項目に戻る；うなずき（頭が静止したとき）は主確認と等価；SPEAK でいつでも現在の状態を読み上げる。
- 結果：すべての項目を確認すると 1 周（周回／完了数 +1）と数え、繰り返し使える；DEMO は状態機械のデモで、終了後は実際の状態がそのまま復元される。

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（現在の項目の確認／読み上げ） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある、この Agent 固有の定義を参照 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | この Agent の主確認（RETURN と等価） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンはすべて上記ジェスチャのミラーで、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態機械のデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | この Agent は権限を一切申請しない；TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ |

## 誠実な境界

- 返却先・期限は本人の登録だけを守る。駅の傘在庫や返却可否は Agent は知らないし決めない。
- 返却済みは本人の確認だけが記す。Agent が返却を代行することはない。

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントに効果なしと明記）。
- グリーンの階調：CSS はグリーンの階調のみを使い、純白と白色の rgba は禁止；ボタンのスタイルはこの Agent の UI 形状に合わせて決め、デフォルトのボタンを共有しない。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/git-rokid/japan/kasa-share
~/tools/bin/aix pack . -o ../../aix/kasa-share.aix
~/tools/bin/aix list ../../aix/kasa-share.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Kasa Share（インポート後に記入） |
| Version / Build | 1.0.0 / インポート後に記入 |
| App Category | Life |
| Intent Description | Kasa share: a borrowed station umbrella, kept on track. Register the return station, watch the return deadline, and mark it returned only when it is really back. It never guesses a station and never auto-returns anything. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 傘シェア：借りた駅の傘を、きちんと追跡する。返却する駅を登録し、返却期限を見守り、本当に戻ったときだけ返却済みと記します。駅を推測することは決してなく、何かを自動で返却することもありません。

### Opening Message

> ## Kasa Share
>
> 傘シェア：借りた駅の傘をきちんと追跡します。返却駅を登録し、返却期限を見守り、本当に戻ったときだけ返却済みと記します。駅を推測せず、自動返却もしません。

### Preview Media

- `preview-kasa-share-index.png` — 初期状態
- `preview-kasa-share-s2.png` — デモ状態 2
- `preview-kasa-share-s3.png` — デモ状態 3
- `preview-kasa-share-s4.png` — デモ状態 4

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO の実機テスト時に追加録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：駅前シェア傘帳簿 Umbrella Ledger；雨天駅前、片手・車椅子の人がシェア傘を借りて返し忘れない

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）
