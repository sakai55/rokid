---
name: "rokid-preview-screenshots"
description: "到達できないホスト型プレビューの代わりに、自己完結型の Ink ランタイムとヘッドレス Chrome を使い、`aix preview --html-out` の出力から AIUI Agent のプレビュースクリーンショットをローカルで（480x352 キャンバス）レンダリングする。Agent の全ページのプレビュー画像が必要なときに使う。"
---

# AIUI Preview Screenshots (local pipeline)

[中文](SKILL.md) | [English](SKILL.en.md) | 日本語
中文版（2026-10-29 時点）からの翻訳。齟齬がある場合は中文版が優先する。

理由：`aix preview` はローカルサーバーを起動するが、生成される `preview.html` は、この環境から安定して到達できない CDN から Ink ランタイムを読み込み、リモートブラウザはループバック URL を開けない。このパイプラインは完全にローカルでレンダリングする。動作するツールは `~/workspace/preview-tools/` にある（保守担当者のマシン上）。

## Steps

1. Agent のディレクトリからプレビュー HTML を書き出す：
   ```bash
   ~/tools/bin/aix preview . --html-out artifacts/preview.html
   ```
2. importmap が CDN ではなく**ローカル**の Ink ランタイムを指すレンダリング用のコピーを作る：
   ```bash
   npm i @yodaos-pkg/ink@<version matching the preview>   # 自己完結型、相対インポート + WASM
   sed 's#https://ga.jspm.io/[^"]*#/ink/index.js#' preview.html > www/preview.html
   ```
   Ink のバージョンは、プレビューの生成に使われたランタイムと一致しなければならない（生成された HTML / `.aix/agent-id` のコンテキストを確認する）。一致しないランタイムでは、キャンバスが何も言わずに空白でレンダリングされることがある。
3. 正しい WASM MIME で `www/` を配信する：
   ```bash
   node server.js   # ~/workspace/preview-tools/server.js、ポート 8902、application/wasm
   ```
4. puppeteer でスクリーンショットを撮る（`~/workspace/preview-tools/shot.js`）：グラスのキャンバスの枠はちょうど **480×352** であり、ブラウザウィンドウではなくこの枠に合わせて切り取る。複数状態のページでは、先に UI を操作し（例：ベンチマークページでキャンバス座標およそ (88,103) にある RUN ALL をクリックする）、各状態をそれぞれ PNG としてキャプチャする。
5. 最終成果物を `preview-<slug>-<page-or-state>.png` としてリポジトリの `screenshots/<slug>/` に保存し、Agent の README の「预览截图」セクションに埋め込む。

## Gotchas

- リモート／ホスト型ブラウザの経路（preview.html をビューアサイトにアップロードする）は、HTML が再生成されるたびにファイル付与のサイズチェックで失敗する。このローカル経路を優先する。
- 時間で切り替わる対話状態は、キャプチャ前に戻ってしまうことがある（例：約1秒後に元に戻る挨拶）。保存した PNG を読み返して、意図した状態が実際に写っているかを確認する。保存した状態同士がバイト単位で同一であれば、2つ目の状態を偽造せず、その旨を述べる。
- ハードウェア依存の項目（カメラ／マイク／センサー）は、Web ランタイムでは設計上 FAIL または SKIP になる。これはプレビュースクリーンショットでは想定内である。本当の挙動は実機で検証する。
