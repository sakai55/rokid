# Eki Barrier（駅バリア最後の10m Station Barrier Scan）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-eki-barrier
```

**AIX 直接ダウンロード**（最新版）：[eki-barrier.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/eki-barrier.aix)

JP16・日本在地 × カーブカット × 指向性。初めての駅で車椅子利用者がエレベーターのある側を最後の10mで見つける。インタラクション哲学：**駅バリア最後の10m Station Barrier Scan**。

## プレビュー画像

![プレビュー-index](<../../screenshots/eki-barrier/preview-eki-barrier-index.png>)
![プレビュー-s2](<../../screenshots/eki-barrier/preview-eki-barrier-s2.png>)
![プレビュー-s3](<../../screenshots/eki-barrier/preview-eki-barrier-s3.png>)
![プレビュー-s4](<../../screenshots/eki-barrier/preview-eki-barrier-s4.png>)

## 方向構成

- この Agent の方向構成：日本在地 × カーブカット × 指向性。各方向が場面の中で代替のきかない一環を担い、機能の寄せ集めではない（日本組のコンセプトは精品ラインの複合通則で判定し、自由組のコンセプトは場面の核で主方向の番号を決める）。
- 一文の場面：初めての駅で車椅子利用者がエレベーターのある側を最後の10mで見つける。

## 機能フロー（閉ループ）

- 入る：開くと現在の項目と進捗が表示され、現在の項目が視線の中央に大きく出る。
- 過程：NEXT で次の項目を選び、CHECK で現在の項目を確認し、PREV で前の項目に戻る；うなずき（頭が静止したとき）は主確認と等価；SPEAK でいつでも現在の状態を読み上げる。
- 結果：すべての項目を確認すると 1 周（周回／完了数 +1）と数え、繰り返し使える；DEMO は状態機械のデモで、終了後は実際の状態がそのまま復元される。

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（現在の項目の確認／読み上げ） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある、この Agent 固有の定義を参照 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | この Agent の主確認（CHECK と等価） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンはすべて上記ジェスチャのミラーで、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態機械のデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | この Agent は権限を一切申請しない；TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ |

## 誠実な境界

- 側の判定は本人の頭振り確認だけによる。地図・経路案内 API は使わない。
- 設備の有無・稼働状況は Agent は知らない。現地の案内表示が正しい。

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントに効果なしと明記）。
- グリーンの階調：CSS はグリーンの階調のみを使い、純白と白色の rgba は禁止；ボタンのスタイルはこの Agent の UI 形状に合わせて決め、デフォルトのボタンを共有しない。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/git-rokid/japan/eki-barrier
~/tools/bin/aix pack . -o ../../aix/eki-barrier.aix
~/tools/bin/aix list ../../aix/eki-barrier.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Eki Barrier（インポート後に記入） |
| Version / Build | 1.0.0 / インポート後に記入 |
| App Category | Life |
| Intent Description | Eki barrier: the last ten metres in an unfamiliar station. A wheelchair user scans left and right with the head, records which side the lift or slope is on, and carries that record to the next station. It is not a map and it does not navigate. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 駅のバリア：初めての駅での最後の 10 メートル。車椅子の利用者が頭を左右に振って、エレベーターやスロープがどちらの側にあるかを記録し、その記録を次の駅まで持ち越します。地図ではなく、ナビゲーションもしません。

### Opening Message

> ## Eki Barrier
>
> 駅のバリア：初めての駅での最後の 10 メートル。車椅子の利用者が頭を左右に振り、エレベーターやスロープのある側を記録して、次の駅まで持ち越します。地図ではなく、案内もしません。

### Preview Media

- `preview-eki-barrier-index.png` — 初期状態
- `preview-eki-barrier-s2.png` — デモ状態 2
- `preview-eki-barrier-s3.png` — デモ状態 3
- `preview-eki-barrier-s4.png` — デモ状態 4

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO の実機テスト時に追加録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：駅バリア最後の10m Station Barrier Scan；初めての駅で車椅子利用者がエレベーターのある側を最後の10mで見つける

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）
