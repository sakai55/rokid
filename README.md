# だるま落とし

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-daruma-otoshi
```

**AIX 直接ダウンロード**（最新版）: [daruma-otoshi.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/daruma-otoshi.aix)

JP49・日本在地 × ゲーム × 指向性。正月の家族の集まりで、子どもが頭の向きとうなずきだけでだるま落としを遊ぶ

## プレビュー画像

![preview-daruma-otoshi-index.png](../screenshots/daruma-otoshi/preview-daruma-otoshi-index.png)
![preview-daruma-otoshi-play.png](../screenshots/daruma-otoshi/preview-daruma-otoshi-play.png)
![preview-daruma-otoshi-record.png](../screenshots/daruma-otoshi/preview-daruma-otoshi-record.png)
![preview-daruma-otoshi-play-s2.png](../screenshots/daruma-otoshi/preview-daruma-otoshi-play-s2.png)

## 方向構成

日本在地 × ゲーム × 指向性。

## 構造と機能

3 ページ：`pages/index/` 積み木一覧（積み木 6つ：一番下の台、二段目の積み木、三段目の積み木、四段目の積み木、五段目の積み木、だるまの頭）；`pages/play/` だるま落とし遊び（頭の向きで左・中央・右のたたく向きを決め、うなずいてたたく。6つたたいたら集計して記録に残す。センサーがないときはボタンで向きを変えて遊べる）；`pages/record/` 記録（直近 6 件と合計）。

内容集の数：積み木 6つ；遊びは 6 たたきで一局；記録は実際の条数で数える。セッションをまたぐ永続化：ストレージキー `darumaOtoshiV1`（記録の配列、`lastError`）。

眼鏡独占能力は視線と頭の向きの協調：`pages/play/index.ink` の `_startSensor` が `AbsoluteOrientationSensor`（存在性守衛つき）で yaw を読み、しきい値 ±0.35 で左・中央・右に分け、うなずき（`onHeadGesture`）がたたく操作そのものになる。センサーがなくてもボタンで遊べるが、頭の向きが遊びの必経路である。

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |

## 権限

無。TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ。

## 誠実な境界

- たたく向きの判定は頭の向きと本人のうなずきによる。積み木の実際の倒れ方を Agent は判定しない。
- 動きは分段のみ：中心→一方向→戻る→次方向。首を回す動きは一切使わない。

## エラーコード

失敗時はグラスの画面に裸のコードを表示し、TTS はコードだけを読み上げ、直近のエラーは永続データの `lastError` に書く（コード、本機の slug、バージョン、原文を含む）。本機で起こりうるコード：

- `E5001` 記録の保存に失敗（ストレージ書き込みで例外）
- `E5002` 記録の読み取りに失敗（読み取り／解析で例外）
- `E3005` 読み上げに失敗（TTS の speak で例外）
- `E8001` ページ遷移に失敗（navigateTo/navigateBack で例外）
- `E7001` 頭センサーに失敗（センサーが使えない／読み取りエラー。センサーがなくてもボタンで遊べる）

## 機器テスト情報

| Studio 名 | 未記入 |
| Version | 1.0.0 |
| App Category | 未記入 |
| Intent Description | 未記入 |
| Agent ID | 未記入 |
| 状態 | 未実機検証 |

## 審査提出資料

Feature Description: 正月に家族で遊ぶだるま落としです。頭の向きでたたく向きを決め、うなずいて6つの積み木をたたき、完成を記録します。

Opening Message: だるま落としを始めましょう。頭の向きで向きを決めて、うなずいてたたきます。

Preview Media:
- `preview-daruma-otoshi-index.png`
- `preview-daruma-otoshi-play.png`
- `preview-daruma-otoshi-record.png`
- `preview-daruma-otoshi-play-s2.png`

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 1 本以上、60 秒以内）が必要。動画は GO が実機で録画した後に追加する。

Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: なし（初版）
- Fixes: なし（初版）
