# 高齢者暮らし手帳

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-senior-kurashi-hub
```

**AIX 直接ダウンロード**（最新版）: [senior-kurashi-hub.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/senior-kurashi-hub.aix)

JP47・日本在地 × 集合総控 × 路縁坡 × 注意力。高齢者が一日の暮らし道具20本を一冊の手帳で回し終える

## プレビュー画像

![preview-senior-kurashi-hub-index.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-index.png)
![preview-senior-kurashi-hub-t01.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t01.png)
![preview-senior-kurashi-hub-t02.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t02.png)
![preview-senior-kurashi-hub-t03.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t03.png)
![preview-senior-kurashi-hub-t04.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t04.png)
![preview-senior-kurashi-hub-t05.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t05.png)
![preview-senior-kurashi-hub-t06.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t06.png)
![preview-senior-kurashi-hub-t07.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t07.png)
![preview-senior-kurashi-hub-t08.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t08.png)
![preview-senior-kurashi-hub-t09.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t09.png)
![preview-senior-kurashi-hub-t10.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t10.png)
![preview-senior-kurashi-hub-t11.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t11.png)
![preview-senior-kurashi-hub-t12.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t12.png)
![preview-senior-kurashi-hub-t13.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t13.png)
![preview-senior-kurashi-hub-t14.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t14.png)
![preview-senior-kurashi-hub-t15.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t15.png)
![preview-senior-kurashi-hub-t16.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t16.png)
![preview-senior-kurashi-hub-t17.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t17.png)
![preview-senior-kurashi-hub-t18.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t18.png)
![preview-senior-kurashi-hub-t19.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t19.png)
![preview-senior-kurashi-hub-t20.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t20.png)
![preview-senior-kurashi-hub-t01-s2.png](../../screenshots/senior-kurashi-hub/preview-senior-kurashi-hub-t01-s2.png)

## 方向構成

日本在地 × 集合総控 × 路縁坡 × 注意力。

## 構造と機能

21 ページ：`pages/index/` 暮らし手帳一覧（道具 20本を 5 本ずつ窓に表示、上下で選び Enter で開く、記録件数を表示）。道具ページは各一つの機能：確認チェックリスト 10 ページ（項目ごとに切替え、全部そろったら完了記録）、数える 4 ページ（目標に届いたら完了記録）、言葉 6 ページ（選んだ言葉を音声で読み上げ、記録に残す）。各道具ページの機能と内容集は互いに異なり、状態の変形をページ数に数えない。

内容集の数：暮らし道具 20本；チェックリスト 10 ページ 40 項目；数える 4 ページ（目標 5・4・4・5 箇所）；言葉 6 ページ 24 文；使用記録は実際の条数で数える。セッションをまたぐ永続化：ストレージキー `seniorKurashiHubV1`（選択道具、チェック状態、完了記録の配列、`lastError`）。

| 道具 | 種類 | 項目数 |
|---|---|---|
| t01 朝の薬 | 確認チェックリスト | 4 |
| t02 血圧メモ | 数える | 5 |
| t03 買い物リスト | 確認チェックリスト | 4 |
| t04 ゴミ出し確認 | 確認チェックリスト | 4 |
| t05 散歩コース | 数える | 4 |
| t06 友人電話 | 言葉 | 4 |
| t07 趣味の時間 | 確認チェックリスト | 4 |
| t08 昼食メニュー | 言葉 | 4 |
| t09 午後の体操 | 数える | 4 |
| t10 孫への手紙 | 確認チェックリスト | 4 |
| t11 銀行・年金メモ | 確認チェックリスト | 4 |
| t12 予定確認 | 確認チェックリスト | 4 |
| t13 天気と服装 | 言葉 | 4 |
| t14 夕食メニュー | 言葉 | 4 |
| t15 入浴準備 | 確認チェックリスト | 4 |
| t16 明日の持ち物 | 確認チェックリスト | 4 |
| t17 連絡先 | 言葉 | 4 |
| t18 緊急連絡 | 言葉 | 4 |
| t19 日記 | 確認チェックリスト | 4 |
| t20 暮らし記録 | 数える | 5 |

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

## - 各道具の案内と文は収録済みの定型内容である。実際の手続きと機関の案内が基準である。
- 言葉の読み上げは本人が選んだ定型文だけを読む。現場で新しく作った言葉ではない。

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

Feature Description: 高齢者の一日の暮らし手帳です。暮らし道具20本を一冊にまとめ、チェック・数える・言葉の各道具を使い終えたら記録します。

Opening Message: 今日の暮らしを確認しましょう。道具を一つずつ、忘れずに回します。

Preview Media:
- `preview-senior-kurashi-hub-index.png`
- `preview-senior-kurashi-hub-t01.png`
- `preview-senior-kurashi-hub-t02.png`
- `preview-senior-kurashi-hub-t03.png`
- `preview-senior-kurashi-hub-t04.png`
- `preview-senior-kurashi-hub-t05.png`
- `preview-senior-kurashi-hub-t06.png`
- `preview-senior-kurashi-hub-t07.png`
- `preview-senior-kurashi-hub-t08.png`
- `preview-senior-kurashi-hub-t09.png`
- `preview-senior-kurashi-hub-t10.png`
- `preview-senior-kurashi-hub-t11.png`
- `preview-senior-kurashi-hub-t12.png`
- `preview-senior-kurashi-hub-t13.png`
- `preview-senior-kurashi-hub-t14.png`
- `preview-senior-kurashi-hub-t15.png`
- `preview-senior-kurashi-hub-t16.png`
- `preview-senior-kurashi-hub-t17.png`
- `preview-senior-kurashi-hub-t18.png`
- `preview-senior-kurashi-hub-t19.png`
- `preview-senior-kurashi-hub-t20.png`
- `preview-senior-kurashi-hub-t01-s2.png`

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO が実機で録画した後に追加する。

Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: なし（初版）
- Fixes: なし（初版）
