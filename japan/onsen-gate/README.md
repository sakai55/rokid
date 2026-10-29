# Onsen Gate（温泉入浴ゲート）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-onsen-gate
```

**AIX 直接ダウンロード**（最新版）：[onsen-gate.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/onsen-gate.aix)

> **引退して保持（2026-10-25、GO の判断）**：温泉では誰も眼鏡をかけて入浴せず、浴場も電子機器の持ち込みを許可しておらず、高温の蒸気自体が眼鏡を壊してしまう——この Agent の場面は生活の常識の中で成り立たない。本日付けで日韓シリーズの現役ラインナップから外れ、JP05 は `coin-locker`（駅のロッカーへの預け入れ帳簿）が引き継ぐ。プロジェクトとインポートアドレスは参照用に保持し、削除しない。

JP05 · 日本ローカライズシリーズ。対話の哲学：**入浴ゲート Threshold Gates**。この Agent は入浴前の3つの関門である。体を洗う、髪を束ねタオルをお湯から出す、静かに入る——前の関門を通過しなければ次の関門は開かず、画面は3つの門の枠そのものである。3つの関門を全て通過して初めて、入浴タイマーに切り替わる（10分が目安で、過ぎたら静かに締める）。浴室の場面ではカメラを断固として使わない。権限表に CAMERA は全くなく、コードにもカメラの呼び出しはゼロであり、README に設計上の約束として記す。浴場を識別したり掲示を翻訳したりはしない（それは基盤の仕事である）。守るのはこの3つの関門だけである。

## プレビュー画像

![プレビュー-index](<../../screenshots/onsen-gate/preview-onsen-gate-index.png>)
![プレビュー-s2](<../../screenshots/onsen-gate/preview-onsen-gate-s2.png>)
![プレビュー-s3](<../../screenshots/onsen-gate/preview-onsen-gate-s3.png>)
![プレビュー-s4](<../../screenshots/onsen-gate/preview-onsen-gate-s4.png>)

## ローカル性

日本の温泉・銭湯には、壁に書かれていなくても誰もが知っている決まりがある。湯船の前に体を洗う、タオルは湯船に入れない、髪は束ねる。初めて行く人（そして外国の友人を連れて行く人）にとって、いちばん緊張するのは浸かることではなく、「入ってからお湯に入るまでの間に恥をかかないこと」である。

## 機能フロー（クローズドループ）

- ゲート管理：3つの関門が左から右に並び、現在の関門は枠いっぱいに表示される。通過すると門の枠が点灯して「開く」
- 通過の方法：PASS キー / シングルタップ / うなずき。本人が確認すれば通過する（体を洗ったかどうかを証明できるセンサーはないため、自分で確認したと正直に表示する）
- 入浴：3つの関門を全て通過すると自動で 10:00 のタイマー区間に入り、終了時に「上がりましょう」と読み上げる。BACK で前の関門に戻って直すこともできる

## ジェスチャー対応表

| ジェスチャー（テンプルタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（README の機能フローと画面のガイド行を参照） |
| 上スワイプ / 下スワイプ | ArrowUp / ArrowDown | 画面のガイド行にあるこの Agent 固有の定義を参照 |
| うなずき（頭が安定しているとき） | `onHeadGesture('nod')` | この Agent の主な確認（PASS と同等。ガイド行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面のボタンはいずれも上記ジェスチャーのミラーであり、ほかに SPEAK（いつでも現在の状態を聞く）と DEMO（デモ用ステートマシン。終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| （なし） | この Agent はどの権限も申請しない。TTS とセンサーにマニフェスト権限は不要であり、カメラは一切呼び出さない（該当する場合） |

## 誠実な境界

- 全ての関門は本人による確認であり、Agent が本当に体を洗ったかどうかを検証できるわけでも、できると主張するわけでもない。守るのは順序と注意喚起であり、監視ではない
- タイマーはペースの目安であり、医療上の助言ではない。体調が悪ければ直ちにお湯から出ること。この Agent は健康状態の判断をしない

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式ドキュメントで効果がないと明記されている）。

## パッケージとプレビュー

```bash
cd ~/workspace/rokid/onsen-gate
~/tools/bin/aix pack . -o ../dist/onsen-gate.aix
~/tools/bin/aix list ../dist/onsen-gate.aix
```

## 実機テスト情報

| フィールド | 値 |
|---|---|
| Studio 名 | Onsen Gate（インポート後に記入） |
| Version / Build | 1.0.1 / インポート後に記入 |
| App Category | Life |
| Intent Description | At a Japanese onsen or sento changing room: sequences the pre-bath etiquette gates, then times the soak. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了。Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 温泉の入浴ゲートです。お湯の前に3つの関門——先に体を洗う、髪を束ねタオルをお湯に入れない、静かに入る。前の関門を自分で確認しないと次は開きません。3つ全てを通過すると、穏やかな10分の入浴タイマーに変わります。設計上、この Agent のどこにもカメラはありません。権限リストは空です。

### Opening Message

> ## Onsen Gate
> 
> お湯の前に3つの関門があります。洗うこと、髪を束ねタオルを入れないこと、静かに入ること。順番に通過すれば、入浴タイマーになります。ここは浴室ですから、カメラは決して使いません。関門はセンサーではなく約束です。

### Preview Media

- `preview-onsen-gate-index.png` — 初期状態
- `preview-onsen-gate-s2.png` — デモ状態 2
- `preview-onsen-gate-s3.png` — デモ状態 3
- `preview-onsen-gate-s4.png` — デモ状態 4

> 正式な審査提出には3–5点のメディアファイルが必要で、動画1点以上（60秒以内）を含むこと。動画は GO の実機セルフテスト時に追加で録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：入浴ゲート Threshold Gates。門の形を横に並べる：底辺のない門の枠3つが一つずつ開き、入浴後はタイマーに変わる

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）

### Change Log（Build 1.0.1）

**Features added**

- なし

**Improvements**

- ボタンをこの Agent の UI 形態に合わせて個別に形作りした（形態は設計契約を参照）。シリーズ全体で同じボタンのセットを共用しない

**Fixes**

- 実機のモノクロ緑パネルに合わせて色を調整した。元の純白 #ffffff を緑の階調に変え（最も明るい緑 #7dff9e）、明暗は緑だけで表現する
