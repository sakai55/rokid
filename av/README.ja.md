# 映像・音声キャプチャ（av/）

[中文](README.md) | [English](README.en.md) | 日本語
中国語版（2026-10-29 時点）の翻訳。

映像・音声キャプチャシリーズ。AV01–AV11。撮影・動画・音声対話まわりの Agent で、各台が基盤側の制約を1つずつ担う（撮影3モード / grabFrame サンプリング / MediaRecorder の分割録画 / マイク4モードと内部録音 / 外部ストリーム ASR / TTS の生成側 / バーコード検出 / LLM マルチモーダル / 映像と音声の同時収録 / 内部録音の文字起こしチェーン）。流れは「登録 → 照合・検証 → 締め・再生」で、やり取りの中心は映像と音声。AV11 は後から足した検証版で、中核の流れを先に通し、細部の機能は後回しにしている。

- AV01 [tri-shot-lab](tri-shot-lab/) — 3つの撮影モードで同じ場面を連写し、デコードを実測して使えるレンズを判定する
- AV02 [motion-frame-watch](motion-frame-watch/) — grabFrame で定期的にフレーム差分をサンプリングして定点を見守り、変化があれば証拠として保存して読み上げる
- AV03 [chunk-rec-studio](chunk-rec-studio/) — まず録画形式と実際の上限を調べ、それから分割して本番録画する
- AV04 [mic-mode-arena](mic-mode-arena/) — 4つのマイクモードで同じ場面を録音テストし、環境ごとに最適なモードを選ぶ
- AV05 [hotword-forge](hotword-forge/) — まず ASR の能力を確認してからホットワードと区切りパラメータを作り、ヒットを実測する
- AV06 [voice-subtitle-lab](voice-subtitle-lab/) — synthesize で単語単位の字幕を作り、声の種類と速度を選んで A/B 比較し、お気に入りに残す
- AV07 [barcode-rally](barcode-rally/) — 連続スキャンを目標リストと照合し、コードの規格ごとに締める
- AV08 [dual-shot-verify](dual-shot-verify/) — 広角と望遠の二重撮影をペアにして、互いに照合してから記録する
- AV09 [av-sync-check](av-sync-check/) — 映像と音声を同時に収録して同時に検査し、手拍子のイベントで同期のずれを算出する
- AV10 [system-audio-capture](system-audio-capture/) — デバイスの再生音だけを録音し、内部録音を分割して文字起こしして保存する
- AV11 [stop-motion-studio](stop-motion-studio/) — 定格の検証版：1フレームずつ撮影し（オニオンスキン）、フレームレートで合成再生して検証値を出す

全リストはルートの [README](../README.md) 末尾にある Agent リストを参照。
