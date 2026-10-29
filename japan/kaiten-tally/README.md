# Kaiten Tally（回転寿司の皿数帳）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-kaiten-tally
```

**AIX 直接ダウンロード**（最新版）：[kaiten-tally.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/kaiten-tally.aix)

JP12・日本ローカライズシリーズ。インタラクション哲学：**コンベヤーの皿数 Conveyor Tally**。この Agent はコンベヤーの脇の皿数帳：白皿 110 円、赤皿 220 円、黒皿 330 円、1 皿食べるごとに色で 1 皿加え、合計がそのままリアルタイムの会計の目安になる。寿司を判別せず、美味しいかどうかも判断せず、皿を数えるだけ；会計のときに GO を 1 回で合計をロックし、もう 1 回 GO で次の客のためにゼロに戻す。ラストオーダーの時刻は必ず店員に聞くこと。画面にも、代わりに報せないと明記する。

## プレビュー画像

![プレビュー-index](<../../screenshots/kaiten-tally/preview-kaiten-tally-index.png>)
![プレビュー-s2](<../../screenshots/kaiten-tally/preview-kaiten-tally-s2.png>)
![プレビュー-s3](<../../screenshots/kaiten-tally/preview-kaiten-tally-s3.png>)
![プレビュー-s4](<../../screenshots/kaiten-tally/preview-kaiten-tally-s4.png>)

## 地域性

回転寿司の価格は皿の色で決まる：色ごとに単価が違い、食べ終えたら皿を重ね、店員が皿を数えて会計する。最も乱れやすいのは「結局何皿食べたか、色ごとに何皿か」で、特に 1 テーブルの面々が一緒に食べ、皿が混ざっているとき。

## 機能フロー（閉ループ）

- 色ごとに数える：白／赤／黒の 3 色の皿に各 1 キー、1 皿食べるごとに 1 皿加え、合計と総皿数がリアルタイムに更新される
- コンベヤーの帯：上部に皿数の帯が 1 本、皿数が一目で分かり、空のテーブルのときは「まだ皿はありません」と明記する
- 会計のロック：GO で合計をロックして TTS で読み上げ、もう一度 GO で次の客のためにゼロに戻す。ロック中は皿の追加は無効

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（README の機能フローと画面の guide 行を参照） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある、この Agent 固有の定義を参照 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | この Agent の主確認（WHITE と等価。guide 行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンはすべて上記ジェスチャのミラーで、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態機械のデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | この Agent は権限を一切申請しない；TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ（該当する場合） |

## 誠実な境界

- 皿の価格（白 110／赤 220／黒 330）はこの帳簿の目安の価格表で、店ごとに価格は違う。店内の表示価格が正で、画面にも明示する
- 皿は本人が色ごとに手動で加える。Agent はカメラで皿を数えず、数え間違えたら会計の前に見直すこと
- ラストオーダーと店内のルールは店員と店内の掲示が正で、Agent はリアルタイムの照会をしない

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式に効果なしと明記）。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/kaiten-tally
~/tools/bin/aix pack . -o ../dist/kaiten-tally.aix
~/tools/bin/aix list ../dist/kaiten-tally.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Kaiten Tally（インポート後に記入） |
| Version / Build | 1.0.0 / インポート後に記入 |
| App Category | Life |
| Intent Description | At a kaiten sushi counter: tallies plates by colour into a bill estimate and locks it at checkout. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 回転寿司の皿数帳：白皿 110 円、赤皿 220 円、黒皿 330 円——色ごとに 1 キー、食べた皿ごとに 1 タップ、走っている合計が会計の目安です。GO で会計をロックして読み上げ、もう一度 GO で次の客のためにテーブルを空にします。寿司を判別することは決してなく、ラストオーダーの時刻も調べません；それは店員に聞いてください。

### Opening Message

> ## Kaiten Tally
> 
> 回転寿司のカウンターでは、会計は色ごとの皿そのものです。私が数えます：白 110、赤 220、黒 330、皿ごとに 1 タップ、画面の合計が常にその時点の会計です。食べ終えたら、GO で会計をロックして読み上げます。ラストオーダーの時刻は店員のもので、私のものではありません。

### Preview Media

- `preview-kaiten-tally-index.png` — 初期状態
- `preview-kaiten-tally-s2.png` — デモ状態 2
- `preview-kaiten-tally-s3.png` — デモ状態 3
- `preview-kaiten-tally-s4.png` — デモ状態 4

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO の実機テスト時に追加録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：コンベヤーの皿数 Conveyor Tally；コンベヤーの横帯：皿数の帯 ＋ 大きな合計 ＋ 3 色の皿価格の行

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）
