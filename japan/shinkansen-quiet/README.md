# Shinkansen Quiet（新幹線静音ガード）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-shinkansen-quiet
```

JP01 ・ 日本ローカライズシリーズ。対話哲学：**沈黙の番人 Silence Keeper**。静音車両で最も自覚しにくいのは「自分の声がどれほど大きいか」だ。ヘッドホンを着けて話すと無意識に声量が上がり、電話が鳴って慌てて出た最初の数秒が最もうるさい。本 Agent は「自分が一線を越えたかどうか」をグラスに任せる。装着者の近距離の発声強度だけを監視し、普段は何も表示せず、越えたときだけ現れて、デッキへ行くよう促す。書き起こしも録音もせず、他人を評価することもしない——それはリアルタイム字幕や会議の書き起こし（ベース機能）の役割であり、本 Agent とは関係がない。

## プレビュー画像

![プレビュー-index](<../../screenshots/shinkansen-quiet/preview-shinkansen-quiet-index.png>)
![プレビュー-s2](<../../screenshots/shinkansen-quiet/preview-shinkansen-quiet-s2.png>)
![プレビュー-s3](<../../screenshots/shinkansen-quiet/preview-shinkansen-quiet-s3.png>)
![プレビュー-s4](<../../screenshots/shinkansen-quiet/preview-shinkansen-quiet-s4.png>)

## ローカル性

日本の新幹線には明確な車両マナーがある。携帯電話はマナーモードにし、通話は車両の連結部（デッキ）でし、会話は声量を抑える。これは漠然とした「静かに」ではなく、車両全体で守る明文化されたルールであり、1人が例外になれば車両全体に聞こえる。

## 機能の流れ（閉ループ）

- 見守り：Web Audio が近距離の音圧を分析する（強度だけを計算し、保存も書き起こしもしない）。音圧バーはリアルタイムに上下する
- 越線：設定したしきい値を超えたときだけ注意を点灯し、TTS で「デッキへどうぞ」と1回読み上げ、同時に越線を1回記録する
- 振り返り：ピークと越線回数は本ページのメモリに残り、うなずくと確認して消去する。降車してページを閉じれば忘れる

## ジェスチャー対応表

| ジェスチャー（テンプルタッチパッド） | キーイベント | 本 Agent での役割 |
|---|---|---|
| 1回タップ | Enter | 状況に応じた GO（README の機能の流れと画面の guide 行を参照） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある本 Agent 専用の定義を参照 |
| うなずき（頭が安定したとき） | `onHeadGesture('nod')` | 本 Agent の主確認（ARM と同等。guide 行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンは上記ジェスチャーのミラーであり、SPEAK（いつでも現在の状態を聞ける）と DEMO（状態遷移のデモ。終了後は実際の状態がそのまま復元される）を追加している。

## 権限

| 権限 | 用途 |
|---|---|
| `RECORD_AUDIO` | マイク／音声経路（強度分析または ASR。保存しない） |

## 誠実な境界

- 音圧は相対的な強度であり、校正されたデシベル値ではない。実機のマイクモード（wearer 近距離）の可用性はデバイスに依存し、使えない場合は正直に SKIP と報告する。中核の注意ロジックには影響しない
- 練習モード（PRACTICE）の音圧はシミュレーション値であり、手順に慣れるためだけに使う。画面と読み上げの両方で「練習」と明示する

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式に効果がないと明記されている）。

## パッケージングとプレビュー

```bash
cd ~/workspace/rokid/shinkansen-quiet
~/tools/bin/aix pack . -o ../dist/shinkansen-quiet.aix
~/tools/bin/aix list ../dist/shinkansen-quiet.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Shinkansen Quiet（インポート後に記入） |
| Version / Build | 1.0.2 / インポート後に記入 |
| App Category | Life |
| Intent Description | Worn on a Shinkansen quiet car: monitors the wearer voice level and reminds them to move to the deck when they get loud. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 新幹線の静音車両向けセルフガード。マイクで自分の声のレベルだけを監視する（レベルのみ。録音も書き起こしもしない）。普段は表示されず、自分で決めたしきい値を超えたときだけ現れ、通話はデッキへ移動するよう1回促す。ピークと越線回数はページメモリにのみ残り、ページを閉じれば消える。

### Opening Message

> ## Shinkansen Quiet
> 
> 静音車両で最も判断しにくい音は、自分の声だ。起動すれば、自分の声のレベルだけを見守る——録音も書き起こしもしない。しきい値以下なら何も表示しない。超えたら、言うことは1つだけ。通話はデッキでお願いします。

### Preview Media

- `preview-shinkansen-quiet-index.png` — 初期状態
- `preview-shinkansen-quiet-s2.png` — デモ状態 2
- `preview-shinkansen-quiet-s3.png` — デモ状態 3
- `preview-shinkansen-quiet-s4.png` — デモ状態 4

> 正式な審査提出には 3–5 個のメディアファイルが必要で、動画（≤60 s）を ≥1 本含む。動画は GO が実機で自己テストする際に後から録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：沈黙の番人 Silence Keeper。計器の横バー：中央の大きな読み値 + 音圧の横バー + しきい値の目盛り

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）

### Change Log（Build 1.0.1）

**Features added**

- なし

**Improvements**

- ボタンは本 Agent の UI 形態に合わせて個別に定めた（形態は設計契約を参照）。シリーズ全体で同じボタンの組を共用しない

**Fixes**

- 色を実機のモノクロ緑パネルに合わせた：元の純白 #ffffff を緑の階調に変更した（最も明るい緑 #7dff9e）。明暗は緑だけで表す

### Change Log（Build 1.0.2）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- 言語の純化：画面と音声の文案を現地の言語に統一した（日本＝日本語／韓国＝韓国語）。混入していた日本語と中国語の文案（SCAN のプロンプトを含む）を1つずつ確認して取り除いた
