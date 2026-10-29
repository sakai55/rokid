---
name: "rokid-preview-screenshots"
description: "ホスト型プレビューへ到達できない環境向けに、自己完結型の Ink ランタイムとヘッドレス Chrome を使って、`aix preview --html-out` の出力から AIUI エージェントのプレビュースクリーンショットをローカルで描画する手順（キャンバスは 480x352）。エージェントの全ページ分のプレビュー画像が必要なときに使う。"
---

# AIUI Preview Screenshots (local pipeline)

[中文](SKILL.md) | [English](SKILL.en.md) | 日本語
本書は中文版（2026-10-29 時点）を正本とする。解釈に食い違いが生じた場合は中文版を優先する。

なぜローカルで描画するのか。`aix preview` はローカルサーバーを立てるものの、生成される `preview.html` は Ink ランタイムを CDN から読み込む。その CDN にはこの環境から安定して到達できず、リモートブラウザ側もループバック URL を開けない。このパイプラインは描画をすべてローカルで完結させる。実績のあるツール一式は `~/workspace/preview-tools/` に置いてある（保守担当者のマシン上）。

## Steps

1. エージェントのディレクトリで、プレビュー用 HTML を書き出す：
   ```bash
   ~/tools/bin/aix preview . --html-out artifacts/preview.html
   ```
2. importmap の参照先を CDN ではなく**ローカル**の Ink ランタイムへ差し替えた、描画用のコピーを作る：
   ```bash
   npm i @yodaos-pkg/ink@<version matching the preview>   # 自己完結型、相対インポート + WASM
   sed 's#https://ga.jspm.io/[^"]*#/ink/index.js#' preview.html > www/preview.html
   ```
   Ink のバージョンは、プレビュー生成時に使われたランタイムと一致させること（生成された HTML と `.aix/agent-id` の情報で確認する）。バージョンが食い違うと、エラーも出ないままキャンバスが空白になる場合がある。
3. WASM の MIME を正しく返す形で `www/` を配信する：
   ```bash
   node server.js   # ~/workspace/preview-tools/server.js、ポート 8902、application/wasm
   ```
4. puppeteer で撮影する（`~/workspace/preview-tools/shot.js`）。グラスのキャンバス枠は正確に **480×352** であり、ブラウザウィンドウではなく、この枠に合わせて切り抜く。状態が複数あるページでは、先に UI を操作して目的の状態へ移してから撮る（例：ベンチマークのページで、キャンバス座標およそ (88,103) にある RUN ALL をクリックする）。状態ごとに PNG を分けること。
5. 完成した画像は `preview-<slug>-<page-or-state>.png` という名前でリポジトリの `screenshots/<slug>/` へ保存し、エージェントの README の「预览截图」セクションへ埋め込む。

## Gotchas

- リモート / ホスト型ブラウザを使う経路（preview.html をビューアサイトへアップロードする方法）は、HTML を再生成するたびにファイル付与時のサイズチェックで失敗する。このローカル経路を優先すること。
- 時間で遷移する対話状態は、撮影する前に元の状態へ戻ってしまう場合がある（例：約1秒で切り戻る挨拶表示）。保存した PNG を読み返し、狙った状態が実際に写っているか必ず確認する。保存された状態同士がバイト単位で同一だった場合は、2つ目の状態を作り込まず、その事実をそのまま報告する。
- ハードウェアに依存する項目（カメラ / マイク / センサー）は、Web ランタイムでは設計上 FAIL または SKIP になる。プレビュースクリーンショットでは想定どおりの結果であり、誤りではない。実際の挙動は実機で検証する。
