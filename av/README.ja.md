# 影音キャプチャ（av/）

[中文](README.md) | [English](README.en.md) | 日本語
中文版（2026-10-29 時点）からの翻訳。

影音キャプチャシリーズ · 番号 AV01–AV11：撮影・動画・音声対話を中心に、各台が基盤の境界を一つ担う（撮影3モード / grabFrame サンプリング / MediaRecorder 分割 / マイク4モードと内部録音 / 外部ストリーム ASR / TTS 生成側 / バーコード検出 / LLM マルチモーダル / 映像と音声の二重同時収録 / 内部録音の文字起こしチェーン）。「登録→検証・照合→決済・再生」の閉ループを構成し、影音が主たる対話チャネル。AV11 は追加の検証版（中核チェーンを先行し、深い機能は後回し）。

- AV01 [tri-shot-lab](tri-shot-lab/) — 3つの撮影モードで同じ場面を連写、デコードを実測して使えるレンズを判定
- AV02 [motion-frame-watch](motion-frame-watch/) — grabFrame で定時にフレーム差分をサンプリングして定点を見守り、変化があれば証拠として保存し読み上げ
- AV03 [chunk-rec-studio](chunk-rec-studio/) — まず録画形式と実際の上限を探り、それから分割して正式に録画
- AV04 [mic-mode-arena](mic-mode-arena/) — 4つのマイクモードで同じ場面を録音テストし、環境ごとに最適なモードを選ぶ
- AV05 [hotword-forge](hotword-forge/) — まず ASR 能力を確認してからホットワードと分割パラメータを作り、ヒットを実測
- AV06 [voice-subtitle-lab](voice-subtitle-lab/) — synthesize で単語単位の字幕を作り、声色と速度を選んで A/B 比較し、お気に入りに保存
- AV07 [barcode-rally](barcode-rally/) — 連続スキャンを目標リストで照合し、コード体系ごとに決済
- AV08 [dual-shot-verify](dual-shot-verify/) — 広角と望遠の二重撮影をペアにし、相互に確認してから記録
- AV09 [av-sync-check](av-sync-check/) — 映像と音声を同時収録・同時検査、手拍子イベントで同期のずれを算出
- AV10 [system-audio-capture](system-audio-capture/) — デバイスの再生音だけを録音、内部録音を分割して文字起こしし保存
- AV11 [stop-motion-studio](stop-motion-studio/) — 定格検証版：1フレームずつ撮影（オニオンスキン）、フレームレートで合成再生し検証値を出す

全リストは[リポジトリ ルート README](../README.md) 末尾の Agent リストを参照。
