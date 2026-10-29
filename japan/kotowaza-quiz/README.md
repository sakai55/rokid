# Kotowaza Quiz（ことわざ頭クイズ Proverb Quiz）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-kotowaza-quiz
```

JP17 ・ 日本在地 × 注意力 × ゲーム。通勤・通学の待ち時間、頭の左右でことわざクイズに答える。操作の考え方：**ことわざ頭クイズ Proverb Quiz**。

## プレビュー画像

![プレビュー-index](<../../screenshots/kotowaza-quiz/preview-kotowaza-quiz-index.png>)
![プレビュー-s2](<../../screenshots/kotowaza-quiz/preview-kotowaza-quiz-s2.png>)
![プレビュー-s3](<../../screenshots/kotowaza-quiz/preview-kotowaza-quiz-s3.png>)
![プレビュー-s4](<../../screenshots/kotowaza-quiz/preview-kotowaza-quiz-s4.png>)

## 方向の構成

- 本 Agent の方向の構成：日本在地 × 注意力 × ゲーム。各方向は場面の中で替えの利かない役割を担い、機能の寄せ集めではない（日本組の概念はブティックラインの組合せ通則で判定し、自由組の概念は場面の核で主方向の番号を決める）。
- 場面を一言で表すと：通勤・通学の待ち時間、頭の左右でことわざクイズに答える。

## 機能の流れ（完結した流れ）

- 入る：開くと現在の項目と進み具合が表示され、現在の項目が視線の中央に大きな文字で出る。
- 進める：NEXT で次の項目を選び、ANSWER で現在の項目を承認し、PREV で前の項目に戻る。うなずき（頭が安定しているとき）は主な承認操作と同等。SPEAK で現在の状態をいつでも読み上げる。
- 結果：全項目を承認すると 1 周として数え（周回 / 完了数 +1）、繰り返し使える。DEMO は状態遷移のデモであり、終了後は実際の状態がそのまま復元される。

## ジェスチャー対応表

| ジェスチャー（テンプル側タッチパッド） | キーイベント | 本 Agent での役割 |
|---|---|---|
| 1 回タップ | Enter | 状況に応じた GO（現在の項目の承認 / 読み上げ） |
| 上スワイプ / 下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある本 Agent 専用の定義を参照 |
| うなずき（頭が安定しているとき） | `onHeadGesture('nod')` | 本 Agent の主な承認操作（ANSWER と同等） |
| 2 回タップ | Backspace | システムの戻る操作（横取りしない） |

画面のボタンは上記ジェスチャーの鏡像であり、ほかに SPEAK（現在の状態をいつでも聞ける）と DEMO（状態遷移のデモ。終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | 本 Agent は権限を申請しない。TTS とセンサーにマニフェスト権限は不要で、カメラは一切呼び出さない |

## 正直な境界

- 正誤の判定は本人の確認による。Agent は答え合わせを自動採点しない。
- 意味は収録済みの定型文だけを読み上げる。新しいことわざの解説は生成しない。

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントに効果がないと明記されている）。
- 緑の階調：CSS は緑の階調だけを使い、純白と白色の rgba は使わない。ボタンの形は本 Agent の UI 形態に合わせて決め、共通の既定ボタンは使わない。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/git-rokid/japan/kotowaza-quiz
~/tools/bin/aix pack . -o ../../aix/kotowaza-quiz.aix
~/tools/bin/aix list ../../aix/kotowaza-quiz.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Kotowaza Quiz（インポート後に記入） |
| Version / Build | 1.0.0 / インポート後に記入 |
| App Category | Life |
| Intent Description | Kotowaza quiz: Japanese proverbs as a head-movement quiz for waiting time. A proverb appears, the player answers in their head, confirms with a nod, and hears the meaning. Progress and score are kept across the set. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> ことわざクイズ：日本のことわざを、待ち時間向けの頭の動きのクイズにしました。ことわざが表示され、頭の中で答え、うなずいて承認すると意味が聞けます。進み具合とスコアはセット全体を通して保持されます。

### Opening Message

> ## Kotowaza Quiz
>
> ことわざクイズ：日本のことわざを、待ち時間向けの頭の動きのクイズにしました。ことわざが表示され、頭の中で答え、うなずいて承認すると意味が聞けます。進み具合とスコアはセット全体を通して保持されます。

### Preview Media

- `preview-kotowaza-quiz-index.png` — 初期状態
- `preview-kotowaza-quiz-s2.png` — デモ状態 2
- `preview-kotowaza-quiz-s3.png` — デモ状態 3
- `preview-kotowaza-quiz-s4.png` — デモ状態 4

> 正式な審査提出には 3–5 件のメディアファイルが必要で、動画を 1 件以上（≤60 s）含めます。動画は GO の実機セルフテスト時に追加録画します。

### Change Log（Build 1.0.0）

**Features added**

- 初版：ことわざ頭クイズ Proverb Quiz。通勤・通学の待ち時間、頭の左右でことわざクイズに答える

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）
