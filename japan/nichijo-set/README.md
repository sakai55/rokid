# Nichijo Set（日常生活セット）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-nichijo-set
```

**AIX 直接ダウンロード**（最新版）：[nichijo-set.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/nichijo-set.aix)

JP22 · 日本ローカル × 注意力 × カーブカット（日常生活セット）。ブティックラインでの統合作り直し：CC11 `left-home-proof`（外出時の存証リプレイ、日本向けローカライズ）＋ JP18 `coin-laundry`（ランドリーのカウントダウン見守り）＋ JP19 `origami-steps`（うなずきで進める折り紙）を統合したもの。元の3つの Agent はそのまま封存し、削除も変更もしない。ワンセンテンスの場面：日本の家庭の日常で、外出前に一つずつ存証して不安を防ぎ、コインランドリーで取り忘れず、両手がふさがっているときも折り紙を中断しない——3つの家事がそれぞれ自分のクローズドループを完走し、進捗はすべて端末に残る。

## プレビュー画像

![プレビュー-index](<../../screenshots/nichijo-set/preview-nichijo-set-index.png>)
![プレビュー-proof](<../../screenshots/nichijo-set/preview-nichijo-set-proof.png>)
![プレビュー-proof-s2](<../../screenshots/nichijo-set/preview-nichijo-set-proof-s2.png>)
![プレビュー-laundry](<../../screenshots/nichijo-set/preview-nichijo-set-laundry.png>)
![プレビュー-laundry-s2](<../../screenshots/nichijo-set/preview-nichijo-set-laundry-s2.png>)
![プレビュー-origami](<../../screenshots/nichijo-set/preview-nichijo-set-origami.png>)
![プレビュー-origami-s2](<../../screenshots/nichijo-set/preview-nichijo-set-origami-s2.png>)

## 構造と機能（クローズドループ）

4ページ構成（家事タイルの概要 / 存証スタンプリスト / ランドリーの機器パネル / 折り紙のステップカード）。共有状態はセッションをまたいで永続化される（wx storage `nichijoSetV1`）。

- **概要（pages/index）**：3モードのタイルと今日の実数サマリー（存証が完了したか、ランドリーの稼働台数、折り紙の完成作品数）。すべて永続化データから読み取る。
- **存証（pages/proof）**：チェックポイントのコンテンツセット5か所（ガスコンロ / 玄関の鍵 / 窓の鍵 / 水道 / エアコン）。各ポイントはカメラの実写で存証する（`ImageCapture.takePhoto`、CAMERA 権限は宣言済み）か、本人が手動で確認する。方式（写真 / 手動）と時刻を正直に記録する。5点がそろえば今日の記録として保存し、家を出た後は REPLAY で時刻付きで読み上げる——CC11 の「外出後の不安から証拠リプレイでループを断つ」を引き継ぐ。
- **ランドリー（pages/laundry）**：機器のコンテンツセット3台（洗濯機A / B、乾燥機）。所要時間のプリセットは 30 / 45 / 60 分。終了時刻はタイムスタンプで永続化され、ページやアプリを離れても計算が続き、終了は一度だけ読み上げる。
- **折り紙（pages/origami）**：作品のコンテンツセット3点、合計21ステップ（つる 8ステップ / かぶと 6ステップ / ふうせん 7ステップ）。うなずきか NEXT で一歩ずつ進み、各ステップを永続化する。完成を記録すると自動で次の作品に移る。

方向の分担：注意力が3つの家事の見守りとリプレイを担い、カーブカットは CC11 の認知面のバリアを先に立てる場面（存証で不安のループを断つ）を核とし、日本ローカルがコインランドリーと折り紙の日常場面を担う。

## ジェスチャー対応表

| ジェスチャー（テンプルタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 存証ページで現在のポイントを手動確認 / ランドリーページで開始 / 折り紙ページで次へ |
| 上スワイプ / 下スワイプ | ArrowUp / ArrowDown | チェックポイント、機器、ステップを切り替える |
| うなずき | `onHeadGesture('nod')` | 存証ページで次のポイントへ / 折り紙ページで次へ |
| ダブルタップ | Backspace | システムの戻る（子ページの BACK キーでも可） |

## 権限

CAMERA（存証モードの撮影のみに使用、app.json で宣言済み）。TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない。

## 誠実な境界

- 撮影に失敗した場合（カメラなし / 権限拒否）は失敗を明示し、手動確認のみを提供する。手動記録は正直に「手動」と表示し、決して写真のふりをしない（プレビュー画像 proof-s2 は Web ランタイムにカメラがないときの実際の失敗提示である）。
- 存証が証明するのは「本人がその時刻に確認した」ことだけであり、識別判定はせず、機器の状態そのものを保証しない（慧眼識別との違い）。

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio name | Nichijo Set（インポート後に記入） |
| Version / Build | 1.0.0 |
| App Category | Life（インポート時に確認） |
| Intent Description | 出かける前の存証、ランドリー守候、おりがみ手順の日常生活セット |
| Agent ID | インポート後に記入 |
| 状態 | パッケージ済み、プッシュ済み。Studio 未インポート、実機テスト未実施、審査未提出 |

## 審査提出資料 (Review Submission)

### Feature Description (≤500 chars)

日本向け日常生活セット。3つの完全なモードを備えます。外出時の存証は、5か所をカメラの実写か正直な手動確認で証明し、時刻付きで保存して外出後にリプレイします。ランドリー見守りは3台分で、終了時刻をタイムスタンプで永続化し、セッションをまたいでカウントダウンします。折り紙は3作品21ステップをうなずきで進め、進捗を保存します。

### Opening Message (≤500, Markdown)

**日常生活セットへようこそ。** 出かける前の存証、ランドリーの守候、おりがみの手順——今日の用事を三つ守ります。

### Preview Media

画像7点（本ページのプレビュー画像。審査提出時は3–5点を選ぶ）。動画は実機フェーズで追加する（審査要件は画像1点以上、動画1点以上）。

### Change Log

#### Build 1.0.0
- Features added: 4ページの新作（概要 / 存証 / ランドリー / 折り紙）。CC11 + JP18 + JP19 を統合して作り直し、チェックポイント5か所、機器3台、折り紙3作品21ステップ、カメラ存証の配線、状態のセッション間永続化。
- Improvements: なし（初版）。
- Fixes: なし（初版）。

## パッケージとプレビュー

- パッケージ：`~/tools/bin/aix pack . -o nichijo-set.aix`（リポジトリのコピーは `aix/nichijo-set.aix`）
- プレビュー：`~/tools/bin/aix preview . --html-out artifacts/preview.html` の後、ローカルのスクリーンショットパイプラインを使う（ポート 8902）
