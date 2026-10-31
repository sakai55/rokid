# 病院受付

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-byouin-uketsuke
```

**AIX 直接ダウンロード**（最新版）: [byouin-uketsuke.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/byouin-uketsuke.aix)

JP44・日本在地 × 路縁坡 × 注意力。初めての病院で受診する高齢者が、受付と問診票と会計を忘れず受診を終える

## プレビュー画像

![preview-byouin-uketsuke-index.png](../screenshots/byouin-uketsuke/preview-byouin-uketsuke-index.png)
![preview-byouin-uketsuke-check.png](../screenshots/byouin-uketsuke/preview-byouin-uketsuke-check.png)
![preview-byouin-uketsuke-record.png](../screenshots/byouin-uketsuke/preview-byouin-uketsuke-record.png)
![preview-byouin-uketsuke-check-s2.png](../screenshots/byouin-uketsuke/preview-byouin-uketsuke-check-s2.png)

## 方向構成

日本在地 × 路縁坡 × 注意力。

## 構造と機能

3 ページ：`pages/index/` 受付手順一覧（手順 6つ：初診受付をする、再診受付をする、問診票を書く、検査受付をする、会計をする、処方箋を受け取る）；`pages/check/` 受付チェック（5 項目：保険証を持った、診察券を持った、問診票を書いた、お薬手帳を持った、会計を確認した——項目ごとに切替え、5 つそろったときに音声で知らせて記録を残す）；`pages/record/` 記録（直近 6 件と合計）。

内容集の数：手順 6つ；チェック項目 5つ；記録は実際の条数で数える。セッションをまたぐ永続化：ストレージキー `byouinUketsukeV1`（選択手順、チェック状態、記録の配列、`lastError`）。

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

## - 受診の判断や診断は Agent はしない。生活の受付しおりであり、医療の助言ではない。
- 完了の記録は本人の確認だけが記す。病院の受付を代行することはない。

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

Feature Description: 初めての病院で受診する人のしおりです。受付6つの手順と確認項目を確かめ、5つそろったら受診完了の記録を残します。

Opening Message: 病院の受付を確認しましょう。保険証と問診票を一つずつ、忘れずにそろえます。

Preview Media:
- `preview-byouin-uketsuke-index.png`
- `preview-byouin-uketsuke-check.png`
- `preview-byouin-uketsuke-record.png`
- `preview-byouin-uketsuke-check-s2.png`

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO が実機で録画した後に追加する。

Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: なし（初版）
- Fixes: なし（初版）
