# Bosai Kit（防災バッグカバー点検）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-bosai-kit
```

**AIX 直接ダウンロード**（最新版）：[bosai-kit.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/bosai-kit.aix)

JP04・日本ローカライズシリーズ。インタラクション哲学：**畳のカバーグリッド Coverage Grid**。この Agent は防災バッグを 1 枚のカバーグリッドにする：8 品目が 1 品目 1 セル、確認したら ●、期限切れや交換が必要なら △、未確認は ○。8 セルすべてが ○ を離れて初めて「点検完了」と言う。期限は telephoto で包装の日付を撮って LLM に年月を読ませる（暫定。原文を表示して確認を待つ）か、自分で直接 FLAG する。災害を判別せず、情報を放送せず、避難所へ案内もしない——それはプラットフォームと自治体の仕事。これは 1 つだけを証明する：このバッグは今日、本当に一通り確認された、ということ。

## プレビュー画像

![プレビュー-index](<../../screenshots/bosai-kit/preview-bosai-kit-index.png>)
![プレビュー-s2](<../../screenshots/bosai-kit/preview-bosai-kit-s2.png>)
![プレビュー-s3](<../../screenshots/bosai-kit/preview-bosai-kit-s3.png>)
![プレビュー-s4](<../../screenshots/bosai-kit/preview-bosai-kit-s4.png>)

## 地域性

日本の家庭にとって防災は選択肢ではない：自治体はどこも防災マニュアルを配り、スーパーには防災用品の棚があり、防災バッグは「そろっている＋期限切れでない」ことが求められる。水・非常食・薬には有効期限があり、点検の難しさは品目を知っているかどうかではなく、8 品目のうちどのセルを確認済みで、どれが期限切れか、にある。

## 機能フロー（閉ループ）

- カバー：8 品目のグリッド（水／非常食／電灯／ラジオ／電源／常備薬／軍手／笛）、スワイプでセル選択
- 点検：OK で ●、FLAG で △（期限切れ／要交換）、うなずき = OK；SCAN で期限を撮って暫定メモにする
- 締め：8/8 が ○ でなくなって初めて完了を報せ、△ のリストを別途示して交換を促す

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 状況に応じた GO（README の機能フローと画面の guide 行を参照） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 画面の guide 行にある、この Agent 固有の定義を参照 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | この Agent の主確認（OK と等価。guide 行を参照） |
| ダブルタップ | Backspace | システムの戻る（横取りしない） |

画面上のボタンはすべて上記ジェスチャのミラーで、ほかに SPEAK（いつでも現在の状態を聞ける）と DEMO（状態機械のデモ、終了後は実際の状態がそのまま復元される）がある。

## 権限

| 権限 | 用途 |
|---|---|
| `CAMERA` | 撮影による照合の経路（機能フローを参照。失敗したら SKIP） |

## 誠実な境界

- 期限の読み取りは撮影＋LLM 由来の暫定情報：必ず包装の原文と照合し、読み違えたら包装が正。SCAN が失敗したら SKIP し、手作業の点検には影響しない
- 品目は東京で一般的な防災バッグの構成。各自治体のマニュアルに合わせた増減は今後の課題。この Agent は避難判断を一切提供しない

- TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない（公式に効果なしと明記）。

## パッケージ化とプレビュー

```bash
cd ~/workspace/rokid/bosai-kit
~/tools/bin/aix pack . -o ../dist/bosai-kit.aix
~/tools/bin/aix list ../dist/bosai-kit.aix
```

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Bosai Kit（インポート後に記入） |
| Version / Build | 1.0.3 / インポート後に記入 |
| App Category | Life |
| Intent Description | At home before disaster season: sweeps a Japanese emergency kit grid, flagging expired items. |
| Agent ID | インポート後に記入 |
| 状態 | ローカルビルド完了、Studio へのインポート待ち |

## 審査提出資料 (Review Submission)

### Feature Description

> 防災バッグのカバー点検：8 つの品目をグリッドにし、すべて確認済みか、期限切れ・要交換に印を付け終えるまで「点検完了」とは言いません。telephoto カメラで包装の日付を撮れば暫定の期限メモが付き、自分で印を付けることもできます。今日そのバッグを本当に点検したことだけを証明します。災害の助言も避難案内もしません。

### Opening Message

> ## Bosai Kit
> 
> 防災バッグが使えるのは、期限まで含めて全品目を実際に確認したときだけです。8 つのセル——水・非常食・電灯・ラジオ・電源・薬・軍手・笛——をすべて埋めてください。全部埋まって初めて「準備完了」と言います。

### Preview Media

- `preview-bosai-kit-index.png` — 初期状態
- `preview-bosai-kit-s2.png` — デモ状態 2
- `preview-bosai-kit-s3.png` — デモ状態 3
- `preview-bosai-kit-s4.png` — デモ状態 4

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO の実機テスト時に追加録画する。

### Change Log（Build 1.0.0）

**Features added**

- 初版：畳のカバーグリッド Coverage Grid；グリッド：8 セルの大きな印の配列＋現在のセルの説明行

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

### Change Log（Build 1.0.3）

**Features added**

- なし

**Improvements**

- なし

**Fixes**

- FileReader 削除（Ink ランタイムに存在せず、実機で必ず失敗する）：写真 Blob→dataURL を公式ドキュメントの経路 `blob.arrayBuffer()` + 分割 `btoa` に変更し、失敗時は全艦隊エラーコード E2005 を表示する。
