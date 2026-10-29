# Origami Steps（折り紙手順送り Origami Steps）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-origami-steps
```

JP19 ・ 日本ローカル × 指向性 × 注意力（GUIDE）。自宅で折り紙をするとき、両手がふさがっている人がうなずきで手順を進め、鶴を1羽折るごとに数を数える。対話哲学：**折り紙手順送り Origami Steps**。

## プレビュー画像

![プレビュー-index](<../../screenshots/origami-steps/preview-origami-steps-index.png>)
![プレビュー-s2](<../../screenshots/origami-steps/preview-origami-steps-s2.png>)
![プレビュー-s3](<../../screenshots/origami-steps/preview-origami-steps-s3.png>)
![プレビュー-s4](<../../screenshots/origami-steps/preview-origami-steps-s4.png>)

## 方向構成

- 本 Agent の方向構成：日本ローカル × 指向性 × 注意力（GUIDE）。各方向は場面の中で代替できない役割を担い、機能の寄せ集めではない（日本グループの概念はブティックラインの組合せ通則で判定し、自由グループの概念は場面の中核によって主方向の番号を定める）。
- 一文の場面：自宅で折り紙をするとき、両手がふさがっている人がうなずきで手順を進め、鶴を1羽折るごとに数を数える。

## 機能の流れ（閉ループ）

- 開始：開くと現在の項目と進捗を表示し、現在の項目を視線の中央に大きな文字で示す。
- 進行：NEXT で次の項目を選び、DONE で現在の項目を確認し、PREV で前の項目に戻る。うなずき（頭が安定したとき）は主確認と同等。SPEAK でいつでも現在の状態を読み上げる。
- 結果：すべての項目を確認すると1ラウンドとして数える（周回／完了数 +1）。繰り返し使える。DEMO は状態遷移のデモであり、終了後は実際の状態がそのまま復元される。

## ジェスチャー対応表

| ジェスチャー（テンプルタッチパッド） | キーイベント | 本 Agent での役割 |
|---|---|---|
| 1回タップ | Enter | 状況に応じた GO（現在の項目の確認／読み上げ） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある本 Agent 専用の定義を参照 |
| うなずき（頭が安定したとき） | `onHeadGesture('nod')` | 本 Agent の主確認（DONE と同等） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンは上記ジェスチャーのミラーであり、SPEAK（いつでも現在の状態を聞ける）と DEMO（状態遷移のデモ。終了後は実際の状態がそのまま復元される）を追加している。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | 本 Agent は権限を申請しない。TTS とセンサーはマニフェスト権限が不要で、カメラは一切呼び出さない |

## 誠実な境界

- 手順は鶴の基本手順の定型セットのみ。新しい折り図の生成はしない。
- 手順の完了は本人のうなずき確認による。

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントに効果がないと明記されている）。
- 緑の階調：CSS は緑の階調のみを使い、純白と白色の rgba は使わない。ボタンのスタイルは本 Agent の UI 形態に合わせて定め、既定ボタンを共用しない。

## パッケージングとプレビュー

```bash
cd ~/workspace/rokid/git-rokid/japan/origami-steps
~/tools/bin/aix pack . -o ../../aix/origami-steps.aix
~/tools/bin/aix list ../../aix/origami-steps.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Origami Steps（インポート後に記入） |
| Version / Build | 1.0.0 / インポート後に記入 |
| App Category | Life |
| Intent Description | Origami steps: folding a paper crane with both hands busy. Steps advance by nod, one step at a time, and each finished crane is counted. The agent holds the steps and the count, not the hands. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 両手がふさがったまま折り紙で鶴を折るための手順送り。うなずきで1ステップずつ進め、鶴が1羽完成するごとに数を数える。本 Agent が保持するのは手順と数であり、手そのものではない。

### Opening Message

> ## Origami Steps
>
> 両手がふさがったまま折り紙で鶴を折るための手順送り。うなずきで1ステップずつ進め、鶴が1羽完成するごとに数を数える。本 Agent が保持するのは手順と数であり、手そのものではない。

### Preview Media

- `preview-origami-steps-index.png` — 初期状態
- `preview-origami-steps-s2.png` — デモ状態 2
- `preview-origami-steps-s3.png` — デモ状態 3
- `preview-origami-steps-s4.png` — デモ状態 4

> 正式な審査提出には 3–5 個のメディアファイルが必要で、動画（≤60 s）を ≥1 本含む。動画は GO が実機で自己テストする際に後から録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：折り紙手順送り Origami Steps。自宅で折り紙をするとき、両手がふさがっている人がうなずきで手順を進め、鶴を1羽折るごとに数を数える

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）
