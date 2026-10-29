# 宅配便受け取り

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-takkyubin-uketori
```

**AIX 直接ダウンロード**（最新版）：[takkyubin-uketori.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/takkyubin-uketori.aix)

JP34・日本在地 × カーブカット × 注意力。両手がふさがった人が、不在票から再配達と受取方法までを決める

## プレビュー画像

![preview-takkyubin-uketori-index.png](../screenshots/takkyubin-uketori/preview-takkyubin-uketori-index.png)
![preview-takkyubin-uketori-check.png](../screenshots/takkyubin-uketori/preview-takkyubin-uketori-check.png)
![preview-takkyubin-uketori-record.png](../screenshots/takkyubin-uketori/preview-takkyubin-uketori-record.png)
![preview-takkyubin-uketori-check-s2.png](../screenshots/takkyubin-uketori/preview-takkyubin-uketori-check-s2.png)

## 方向構成

- この Agent の方向構成：日本在地 × カーブカット × 注意力。各方向が場面の中で代替のきかない一環を担い、機能の寄せ集めではない。
- 日本在地：日本の宅配便の不在票、再配達、受取方法（対面、宅配ボックス、コンビニ、置き配）に沿う。
- カーブカット：両手がふさがった人でも、うなずきと音声案内で手続きを進められる。
- 注意力：荷物 6 件の状態を見守り、再配達の手続き漏れを防ぐ。
- 一文の場面：両手がふさがった人が、不在票から再配達と受取方法までを決める。

## 構造と機能

3 ページ：`pages/index/` 荷物一覧（荷物 6 件と受取状態）；`pages/check/` 再配達手続き（再配達時間帯 6 枠、受取方法 4 種類から選び、確認して保存すると受取記録を残す）；`pages/record/` 受け取り記録（直近 6 件＋総数）。

内容集の数：荷物 6 件；再配達時間帯 6 枠；受取方法 4 種類（対面、宅配ボックス、コンビニ、置き配）；完了記録は実際の条数で数える。セッションをまたぐ永続化：ストレージキー `takkyubinUketoriV1`（選択荷物、時間帯、受取方法、完了記録の配列、`lastError`）。

## ジェスチャ対応

| ジェスチャ（テンプルのタッチパッド） | キーイベント | この Agent での役割 |
|---|---|---|
| シングルタップ | Enter | 主確認（各ページの主ボタン） |
| 上スワイプ／下スワイプ | ArrowUp / ArrowDown | 選択肢の切替／前後の項目 |
| うなずき（頭が静止したとき） | `onHeadGesture('nod')` | 主確認と等価 |
| ダブルタップ | Backspace | 前のページに戻る（子ページ） |

## 権限

なし。TTS とセンサーにマニフェストの権限は不要で、カメラの呼び出しはゼロ。

## 誠実な境界

- 表示する荷物と状態は本人の確認用であり、配送会社のシステムとは連動しない。
- 再配達の保存は本人の手続きメモであり、配送会社への申込み完了を証明するものではない。
- 配送時刻の確約は行わない。

## エラーコード

失敗時はグラスの画面に裸のコードを表示し、TTS はコードだけを読み上げ、直近のエラーは永続データの `lastError` に書く（コード、本機の slug、バージョン、原文を含む）。本機で起こりうるコード：

- `E5001` 記録の保存に失敗（ストレージ書き込みで例外）
- `E5002` 記録の読み取りに失敗（読み取り／解析で例外）
- `E3005` 読み上げに失敗（TTS の speak で例外）
- `E8001` ページ遷移に失敗（navigateTo/navigateBack で例外）

## デバイスのテスト情報

| 項目 | 内容 |
|---|---|
| Studio 名 | 未記入 |
| Version | 1.0.0 |
| App Category | 未記入 |
| Intent Description | 未記入 |
| Agent ID | 未記入 |
| 状態 | 未実施 |

## 審査提出資料 (Review Submission)

Feature Description: 宅配便受け取り：不在票から再配達まで。荷物 6 件の状態を確認し、再配達時間帯 6 枠と受取方法 4 種類から選んで保存し、受け取り記録を永続的に残します。

Opening Message: 宅配便の受け取りを確認しましょう。不在票から再配達と受取方法まで、一緒に決めます。

Preview Media:
- `preview-takkyubin-uketori-index.png`
- `preview-takkyubin-uketori-check.png`
- `preview-takkyubin-uketori-record.png`
- `preview-takkyubin-uketori-check-s2.png`

> 正式な審査提出にはメディアファイル 3〜5 点（うち動画 ≥1 本、≤60 秒）が必要。動画は GO が実機で録画した後に追加する。

Change Log — Build 1.0.0:

- Features added: 初版；両手がふさがった人が、不在票から再配達と受取方法までを決める
- Improvements: なし（初版）
- Fixes: なし（初版）
