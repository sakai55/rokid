# 駅待ち合わせ

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-eki-shuugou
```

**AIX 直接ダウンロード**（最新版）: [eki-shuugou.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/eki-shuugou.aix)

JP45・日本在地 × 指向性 × 路縁坡。駅で待ち合わせる人が、登録した待ち合わせ場所へ GPS の方角と距離で向かう

## プレビュー画像

![preview-eki-shuugou-index.png](../screenshots/eki-shuugou/preview-eki-shuugou-index.png)
![preview-eki-shuugou-guide.png](../screenshots/eki-shuugou/preview-eki-shuugou-guide.png)
![preview-eki-shuugou-record.png](../screenshots/eki-shuugou/preview-eki-shuugou-record.png)
![preview-eki-shuugou-record-s2.png](../screenshots/eki-shuugou/preview-eki-shuugou-record-s2.png)

## 方向構成

日本在地 × 指向性 × 路縁坡。

## 構造と機能

3 ページ：`pages/index/` 待ち合わせ場所一覧（場所 6つ：新宿駅南口、渋谷駅ハチ公前、東京駅丸の内南口、池袋駅西口、品川駅高輪口、上野駅公園口——「場所に登録」で今いる場所の緯度・経度をその場所名で保存する。未登録のときは未登録と表示し、場所を作り出さない）；`pages/guide/` 帰路案内（現在地を測り、8 方位の方角と 10m 単位の距離を表示する。未登録のときは未登録と表示し、場所を作り出さない。「到着した」で到着を記録する）；`pages/record/` 記録（直近 6 件の到着記録と合計件数）。

内容集の数：待ち合わせ場所 6つ；到着記録は実際の条数で数える。セッションをまたぐ永続化：ストレージキー `ekiShuugouV1`（待ち合わせ場所の緯度・経度・登録時刻、到着記録の配列、`lastError`）。

GPS 三件套の証拠：権限の宣言は `app.json` の `permissions` に `GEOLOCATION`。位置の取得は `pages/index/index.ink` の `saveTap` と `pages/guide/index.ink` の `primaryTap` の `navigator.geolocation.getCurrentPosition` 呼び出し。方角の換算は `pages/guide/index.ink` の `_calc`（`Math.atan2` による方位角から 8 方位の配列 `CARD` へ換算し、ハーバーサイン式で距離を 10m 単位に丸める）。

ジェスチャ対応

## | ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る |

権限

## `GEOLOCATION` のみ。位置の利用を拒否されたときは測位せず、測れないことを表示する。GPS が弱いときは測れた値だけを表示し、距離は概算として示す。TTS と頭センサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ。

誠実な境界

## - 待ち合わせ場所は本人の登録であり、公式の案内が優先される。
- 距離は誤差を含む概算であり、正確な道のりではない。
- 未登録のときは案内しない。場所を作り出したり、推測で補ったりしない。

エラーコード

失敗時はグラスの画面に裸のコードを表示し、TTS はコードだけを読み上げ、直近のエラーは永続データの `lastError` に書く（コード、本機の slug、バージョン、原文を含む）。本機で起こりうるコード：

- `E5001` 記録の保存に失敗（ストレージ書き込みで例外）
- `E5002` 記録の読み取りに失敗（読み取り／解析で例外）
- `E3005` 読み上げに失敗（TTS の speak で例外）
- `E8001` ページ遷移に失敗（navigateTo/navigateBack で例外）
- `E7002` 測位に失敗（GPS が使えない／測位エラー）
- `E7003` 測位を拒否された（位置の利用許可がない）

## 设备测试信息

| Studio 名 | 未記入 |
| Version | 1.0.0 |
| App Category | 未記入 |
| Intent Description | 未記入 |
| Agent ID | 未記入 |
| 状态 | 未真机验证 |

## 提审资料

Feature Description: 駅で待ち合わせる人の案内です。待ち合わせ場所を GPS で登録し、方角と距離で向かい、到着を記録します。

Opening Message: 待ち合わせ場所を確認しましょう。登録した場所へ、方角と距離で向かいます。

Preview Media:
- `preview-eki-shuugou-index.png`
- `preview-eki-shuugou-guide.png`
- `preview-eki-shuugou-record.png`
- `preview-eki-shuugou-record-s2.png`

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO が実機で録画した後に追加する。

Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: なし（初版）
- Fixes: なし（初版）
