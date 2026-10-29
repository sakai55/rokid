# Matsuri Taiko（祭り太鼓リズム Festival Drum）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-matsuri-taiko
```

**AIX 直接ダウンロード**（最新版）：[matsuri-taiko.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/matsuri-taiko.aix)

JP15 ・ 日本在地 × 指向性 × ゲーム。夏祭りの待ち時間、家族が頭の動きだけで太鼓リズムを叩く。操作の考え方：**祭り太鼓リズム Festival Drum**。

## プレビュー画像

![プレビュー-index](<../../screenshots/matsuri-taiko/preview-matsuri-taiko-index.png>)
![プレビュー-s2](<../../screenshots/matsuri-taiko/preview-matsuri-taiko-s2.png>)
![プレビュー-s3](<../../screenshots/matsuri-taiko/preview-matsuri-taiko-s3.png>)
![プレビュー-s4](<../../screenshots/matsuri-taiko/preview-matsuri-taiko-s4.png>)

## 方向の構成

- 本 Agent の方向の構成：日本在地 × 指向性 × ゲーム。各方向は場面の中で替えの利かない役割を担い、機能の寄せ集めではない（日本組の概念はブティックラインの組合せ通則で判定し、自由組の概念は場面の核で主方向の番号を決める）。
- 場面を一言で表すと：夏祭りの待ち時間、家族が頭の動きだけで太鼓リズムを叩く。

## 機能の流れ（完結した流れ）

- 入る：開くと現在の項目と進み具合が表示され、現在の項目が視線の中央に大きな文字で出る。
- 進める：NEXT で次の項目を選び、DONE で現在の項目を承認し、PREV で前の項目に戻る。うなずき（頭が安定しているとき）は主な承認操作と同等。SPEAK で現在の状態をいつでも読み上げる。
- 結果：全項目を承認すると 1 周として数え（周回 / 完了数 +1）、繰り返し使える。DEMO は状態遷移のデモであり、終了後は実際の状態がそのまま復元される。

## ジェスチャー対応表

| ジェスチャー（テンプル側タッチパッド） | キーイベント | 本 Agent での役割 |
|---|---|---|
| 1 回タップ | Enter | 状況に応じた GO（現在の項目の承認 / 読み上げ） |
| 上スワイプ / 下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある本 Agent 専用の定義を参照 |
| うなずき（頭が安定しているとき） | `onHeadGesture('nod')` | 本 Agent の主な承認操作（DONE と同等） |
| 2 回タップ | Backspace | システムの戻る操作（横取りしない） |

画面のボタンは上記ジェスチャーの鏡像であり、ほかに SPEAK（現在の状態をいつでも聞ける）と DEMO（状態遷移のデモ。終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | 本 Agent は権限を申請しない。TTS とセンサーにマニフェスト権限は不要で、カメラは一切呼び出さない |

## 正直な境界

- 採点は本人の完了確認による。Agent はリズムの正確さを自動判定しない。
- 動きは分段のみ：中心→一方向→戻る→次方向。首を回す動きは一切使わない。

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントに効果がないと明記されている）。
- 緑の階調：CSS は緑の階調だけを使い、純白と白色の rgba は使わない。ボタンの形は本 Agent の UI 形態に合わせて決め、共通の既定ボタンは使わない。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/git-rokid/japan/matsuri-taiko
~/tools/bin/aix pack . -o ../../aix/matsuri-taiko.aix
~/tools/bin/aix list ../../aix/matsuri-taiko.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Matsuri Taiko（インポート後に記入） |
| Version / Build | 1.0.0 / インポート後に記入 |
| App Category | Life |
| Intent Description | Matsuri taiko: festival drum rhythms played with head movement only. Pick a song, beat it in segments with a return to centre between moves, and clear songs one by one. No circling the neck, ever. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 祭り太鼓：頭の動きだけで叩く祭り太鼓のリズムです。曲を選び、動きの合間に中心へ戻る分段の動きで叩き、曲を 1 つずつクリアします。首を回す動きは決して使いません。

### Opening Message

> ## Matsuri Taiko
>
> 祭り太鼓：頭の動きだけで叩く祭り太鼓のリズムです。曲を選び、動きの合間に中心へ戻る分段の動きで叩き、曲を 1 つずつクリアします。首を回す動きは決して使いません。

### Preview Media

- `preview-matsuri-taiko-index.png` — 初期状態
- `preview-matsuri-taiko-s2.png` — デモ状態 2
- `preview-matsuri-taiko-s3.png` — デモ状態 3
- `preview-matsuri-taiko-s4.png` — デモ状態 4

> 正式な審査提出には 3–5 件のメディアファイルが必要で、動画を 1 件以上（≤60 s）含めます。動画は GO の実機セルフテスト時に追加録画します。

### Change Log（Build 1.0.0）

**Features added**

- 初版：祭り太鼓リズム Festival Drum。夏祭りの待ち時間、家族が頭の動きだけで太鼓リズムを叩く

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）
