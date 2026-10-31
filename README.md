# 郵便局手続き

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-yuubin-kyoku
```

**AIX 直接ダウンロード**（最新版）: [yuubin-kyoku.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/yuubin-kyoku.aix)

JP43・日本在地 × 路縁坡 × 注意力。郵便局で手続きする高齢者が、書類と手順を忘れず手続きを終える

## プレビュー画像

![preview-yuubin-kyoku-index.png](../screenshots/yuubin-kyoku/preview-yuubin-kyoku-index.png)
![preview-yuubin-kyoku-check.png](../screenshots/yuubin-kyoku/preview-yuubin-kyoku-check.png)
![preview-yuubin-kyoku-record.png](../screenshots/yuubin-kyoku/preview-yuubin-kyoku-record.png)
![preview-yuubin-kyoku-check-s2.png](../screenshots/yuubin-kyoku/preview-yuubin-kyoku-check-s2.png)

## 方向構成

日本在地 × 路縁坡 × 注意力。

## 構造と機能

3 ページ：`pages/index/` 手続き一覧（手続き 6つ：書留を出す、ゆうパックを送る、内容証明を出す、振込をする、切手を買う、転送届を出す）；`pages/check/` 手続きチェック（5 項目：本人確認書類を持った、あて名を確認した、料金を確認した、控えを受け取った、次回のメモを残した——項目ごとに切替え、5 つそろったときに音声で知らせて記録を残す）；`pages/record/` 記録（直近 6 件と合計）。

内容集の数：手続き 6つ；チェック項目 5つ；記録は実際の条数で数える。セッションをまたぐ永続化：ストレージキー `yuubinKyokuV1`（選択手続き、チェック状態、記録の配列、`lastError`）。

ジェスチャ対応

## | ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |

権限

## 無。TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ。

誠実な境界

## - 手続きの可否や料金は Agent は知らない。窓口の案内と料金表が正しい。
- 完了の記録は本人の確認だけが記す。郵便局の受付を代行することはない。

エラーコード

失敗時はグラスの画面に裸のコードを表示し、TTS はコードだけを読み上げ、直近のエラーは永続データの `lastError` に書く（コード、本機の slug、バージョン、原文を含む）。本機で起こりうるコード：

- `E5001` 記録の保存に失敗（ストレージ書き込みで例外）
- `E5002` 記録の読み取りに失敗（読み取り／解析で例外）
- `E3005` 読み上げに失敗（TTS の speak で例外）
- `E8001` ページ遷移に失敗（navigateTo/navigateBack で例外）

## 设备测试信息

| Studio 名 | 未記入 |
| Version | 1.0.0 |
| App Category | 未記入 |
| Intent Description | 未記入 |
| Agent ID | 未記入 |
| 状态 | 未真机验证 |

## 提审资料

Feature Description: 郵便局で手続きする人のしおりです。手続き6つと確認項目を確かめ、5つそろったら完了の記録を残します。

Opening Message: 郵便局の手続きを確認しましょう。書類と手順を一つずつ、忘れずにそろえます。

Preview Media:
- `preview-yuubin-kyoku-index.png`
- `preview-yuubin-kyoku-check.png`
- `preview-yuubin-kyoku-record.png`
- `preview-yuubin-kyoku-check-s2.png`

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO が実機で録画した後に追加する。

Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: なし（初版）
- Fixes: なし（初版）
