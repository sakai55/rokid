# skills/ — Rokid プロジェクトの Skill ライブラリ

[中文](README.md) | [English](README.en.md) | 日本語
中文版（2026-10-29 時点）からの翻訳。齟齬がある場合は中文版が優先する。

Coding Agent 向けのスキルパッケージ（`SKILL.md` ＋ 参考資料）。どの Agent を開発する時も、まず対応する skill を入れること。Web やミニプログラムの経験をもとに、AIUI の API が存在すると決めつけてはいけない。

| ディレクトリ | 内容 | 出典 |
|---|---|---|
| [`aiui-dev/`](aiui-dev/) | 公式 AIUI 開発スキル：フレームワーク、.ink ページ、コンポーネント、WXSS、ランタイム API の契約、単色グリーンのデザイン規範、パッケージング時のチェックリスト | 公式リポジトリ [yodaos-project/AIUI](https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev) の vendored コピー（2026-10-24 同期）。上流が更新されたら、ここへ上書き同期する |
| [`rokid-agent-sop/`](rokid-agent-sop/) | 本プロジェクトの生産 SOP：能力のレッドライン → 開発 → 静的チェック → パッケージング → プレビュー → README（審査提出資料を含む）→ GitHub 同期（main ＋ aix/ パッケージ ＋ スクリーンショット ＋ `agent-<slug>` ブランチ）→ 登録。同じディレクトリの `API-AUDIT.md` は、2026-10-29 に公式ドキュメント全体を監査した作業記録（API 規律の根拠：利用可能な範囲 / 存在しないものの一覧 / Ink バージョン別の到着表 / 権限の全表） | 本プロジェクト独自 |
| [`rokid-preview-screenshots/`](rokid-preview-screenshots/) | ローカルプレビューのスクリーンショット用パイプライン：`aix preview` で HTML を出力 → ローカルの Ink ランタイム → headless Chrome で 480×352 のキャンバスを撮る | 本プロジェクト独自 |
| [`cc/`](cc/) | カーブカット効果シリーズのデザイン層（`rokid-curb-cut`）：企画時の三つの問い（スロープそのもの / チャネルの改造 / 波及マップ）、障害ごとのチャネル改造、慧眼を除外する際の判断句、波及の規律と薄めない原則。`rokid-agent-sop` と併用し、バージョン付きで更新する | 本プロジェクト独自 |
| [`rokid-conflict-audit/`](rokid-conflict-audit/) | 標準搭載能力との衝突チェック：標準搭載機能 7 項目のベースライン ＋ 3 段階の判定（直接衝突 / 高度の重なり / 要テスト）。ルート README の衝突バッジの唯一のデータ源。バージョン付きで更新する（現在 v1.0.1） | 本プロジェクト独自 |
| [`rokid-boutique-acceptance/`](rokid-boutique-acceptance/) | ブティックラインのバッチ検収（rokid-boutique-acceptance）：作られたファイルに基づいてページ数と同型かどうかを確認し、コンテンツ集合を 1 項目ずつ数え、クローズドループは API 接続を調べ、セッションをまたぐものは永続化コードを調べ、プレースホルダは決して数に入れず、合格したものだけを数える。バージョン付きで更新する | 本プロジェクト独自 |
| [`rokid-head-games/`](rokid-head-games/) | 頭部動作ミニゲームのデザイン層（rokid-head-games）：絶対に回らないという原則（区切った動作、必ず正面に戻る）、安全ライン、センサーについての正直さ（方向の記号はキャリブレーションで学ぶ、手勢イベントは nod のみ）、判定パターンのライブラリと GA の生産で得た教訓。バージョン付きで更新する（現在 v1.0.1） | 本プロジェクト独自 |
| [`rokid-directional/`](rokid-directional/) | 指向性シリーズのデザイン層（rokid-directional）：グラス対胸装着デバイスという企画時の三つの問い、6 つのデザイン原語（GAZE 見ることが指すこと / HEAD 向きの登録と相対方向 / 凝視による確認 / マイクアレイの正直な位置付け / SCAN 頭を回して音を探す / GEO 東西南北と位置情報）、2026-10-24 の監査で得た正直な境界と再利用パターンのライブラリ（向きの登録簿 / 振り返り確認 / 読み取り値の照合 / 相対方位のロック）。バージョン付きで更新する（現在 v1.0.1） | 本プロジェクト独自 |
| [`jp/`](jp/) | 日本ローカライズのスキル（rokid-jp-localization）：JP シリーズの在地性の判定基準、日本語の純度ルールと機械チェック、中国語文案の落とし穴、環境ゲート。バージョン付きで更新する | 本プロジェクト独自 |
| [`kr/`](kr/) | 韓国ローカライズのスキル（rokid-kr-localization）：KR シリーズの在地性の判定基準、韓国語の純度ルールと機械チェック（仮名と漢字 = 0）、日本語文案の落とし穴、環境ゲート。バージョン付きで更新する | 本プロジェクト独自 |

## 使い方

```bash
# このリポジトリから現在のプロジェクトへ skill を 1 つ入れる
npx skills add https://github.com/sakai55/rokid/tree/main/skills/aiui-dev

# またはディレクトリをプロジェクトの .agents/skills/ へ直接コピーする
cp -r skills/aiui-dev <agent-project>/.agents/skills/
```

> 注意：Agent プロジェクトをパッケージングする時、`.aixignore` で `.agents/` を必ず除外すること。除外しないと skill のファイルが .aix パッケージに入ってしまう。
