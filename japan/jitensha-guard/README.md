# Jitensha Guard（自転車の走行ロックアウト）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-jitensha-guard
```

**AIX 直接ダウンロード**（最新版）：[jitensha-guard.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/jitensha-guard.aix)

JP10・日本ローカライズシリーズ。インタラクション哲学：**モーション・ロックアウト Motion Lockout**。この Agent のインタラクション哲学は反インタラクション：停車中は点検表（ブレーキ／タイヤ／ライト／鍵を 1 項目ずつ確認）、走行中と判定した途端（GEO の速度またはジャイロの活動）、メイン画面は大きな 1 行「走行中 — 画面は見ないで」に崩れ、どのボタンを押しても LOCKED と返すだけ（機能はすべて無効）、状態が切り替わるときだけ TTS で一言話す。ナビゲーションせず、速度を測って自慢せず、軌跡も記録しない（それはプラットフォームのナビゲーションや運動アプリの仕事）；存在する意味は、あなたが自転車に乗っているときに使われることを拒むこと、そしてその拒否を堂々とやること。

## プレビュー画像

![プレビュー-index](<../../screenshots/jitensha-guard/preview-jitensha-guard-index.png>)
![プレビュー-s2](<../../screenshots/jitensha-guard/preview-jitensha-guard-s2.png>)
![プレビュー-s3](<../../screenshots/jitensha-guard/preview-jitensha-guard-s3.png>)
![プレビュー-s4](<../../screenshots/jitensha-guard/preview-jitensha-guard-s4.png>)

## 地域性

日本は自転車大国であり、ルールの大国でもある：ながらスマホ（走行中のスマホ操作）は既に罰則の対象で、傘さし、イヤホン、並進は交通ルールで名指しされている。走行中に「画面を一目見る」設計はすべて、違法行為を誘うもの。

## 機能フロー（閉ループ）

- 点検：停車状態で 1 項目ずつ CHECK（4 項目）、すべて通って初めて「出発できます」を表示
- ロックアウト：速度 >2.2m/s またはジャイロの活動が閾値を超える → 走行フェーズ：ボタンはすべて無効、画面は 1 行化、状態の切替だけを TTS で報せる
- 解除：3 秒止まっていれば自動で点検フェーズに戻る；センサーがすべてない場合は MODE で走行フェーズを手動で切り替える（SIM は練習用）

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（README の機能フローと画面の guide 行を参照） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある、この Agent 固有の定義を参照 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | この Agent の主確認（CHECK と等価。guide 行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンはすべて上記ジェスチャのミラーで、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態機械のデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| `GEOLOCATION` | 粗い位置／高度／速度の傍証（失敗したら SKIP） |

## 誠実な境界

- 走行の判定は GEO の速度／ジャイロに依存し、地下やトンネルでは効かないことがある；判定できないときは「判定不可」と正直に表示し、既定では停車フェーズとして扱うが読み上げで注意する
- この Agent は距離も速度も測って保存しない；交通ルールの条文は日本の現行の道路交通法が正で、罰則の詳細は公式を確認すること

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式に効果なしと明記）。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/jitensha-guard
~/tools/bin/aix pack . -o ../dist/jitensha-guard.aix
~/tools/bin/aix list ../dist/jitensha-guard.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Jitensha Guard（インポート後に記入） |
| Version / Build | 1.0.2 / インポート後に記入 |
| App Category | Life |
| Intent Description | Cycling in Japan: pre-ride checklist at standstill, full interaction lockout while riding. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> ロックアウトの哲学を持つ自転車ガード：停車中は 4 点の乗車前点検表；走行が検知された途端（GPS の速度またはジャイロの活動）、画面は 1 行——「走行中、見ないで」——に崩れ、すべてのボタンが死に、TTS だけが状態の変化を話します。走行中に使われることを、意図的に拒みます。

### Opening Message

> ## Jitensha Guard
> 
> あなたを拒むグラスの Agent。停車中、私はあなたの点検表：ブレーキ、タイヤ、ライト、鍵。動き出したら、私は 1 行の文字と死んだボタン——走行中に私を見ることは、法律と私が禁じるそのものだからです。

### Preview Media

- `preview-jitensha-guard-index.png` — 初期状態
- `preview-jitensha-guard-s2.png` — デモ状態 2
- `preview-jitensha-guard-s3.png` — デモ状態 3
- `preview-jitensha-guard-s4.png` — デモ状態 4

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO の実機テスト時に追加録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：モーション・ロックアウト Motion Lockout；最小の面：走行中は画面に大きな 1 行だけが残り、その他はすべて黒

**Improvements**

- なし（初版）

**Fixes**

- なし（初版）

### Change Log（Build 1.0.1）

**Features added**

- なし

**Improvements**

- ボタンをこの Agent の UI 形状に合わせて個別に造形（形状は設計契約を参照）し、シリーズ全員で同じボタンのセットを共有しない

**Fixes**

- 実機の単色グリーンパネルに色を合わせた：元の純白 #ffffff をグリーンの階調に変更（最も明るいグリーン #7dff9e）、濃淡はグリーンだけで表現

### Change Log（Build 1.0.2）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- 言語の純化：画面と音声の文言を現地言語に統一（日本＝日本語／韓国＝韓国語）し、混入していた日本語・中国語の文言（SCAN のプロンプトを含む）を 1 つずつ調べて除去
