# Rokid Glasses 能力アーカイブ（公式ソース版）

[中文](CAPABILITIES.md) | [English](CAPABILITIES.en.md) | 日本語

中文版（最終更新 2026-10-29）からの翻訳。齟齬がある場合は中文版が優先する。

> 整理日：2026-10-24、最終更新：2026-10-29
> 資料の原則：**Rokid 公式ソースのみを採用する**（公式製品ページ、公式ドキュメントサイト、公式 GitHub リポジトリ `yodaos-project/AIUI` およびそれに内蔵される `aiui-dev` skill リファレンス）。自明でない結論にはすべて出典を明記する。
> 表記約定：**** = 公式ページ／ドキュメントの原文に明記；**** = 公式 API ドキュメントの存在／不在から合理的に推論したもので、その旨を明示する；**公式未公表** = 調査した公式ソースのいずれにも見当たらず、決して推測しない。
> ローカル skill リファレンスの統一出典：公式リポジトリ `skills/aiui-dev`（https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev）。以下、引用は `skill: references/…` と表記する。

---

## 1. ハードウェア仕様

データソースは公式グローバル製品ページを正とする：https://global.rokid.com/products/b-h-rokid-glasses-with-display
（英国公式サイト https://gb.rokid.com/collections/rokid-ai-lineup のパラメータと相互に裏付けが取れる。）

| 項目 | 仕様 | 備考 |
|---|---|---|
| SoC | Snapdragon AR1（Qualcomm） | 製品ページの Performance 欄には "Snapdragon AR1" とだけあり、世代の接尾辞はなし；製品ページには別途 "Dual-Chip Performance" の宣伝文句があるが、公式仕様表に第 2 のチップの型番は記載されていない |
| RAM / ストレージ | 2 GB / 32 GB | |
| ディスプレイ技術 | 両眼 Micro LED + 回折導波路（ウェーブガイド）（Binocular Micro LED waveguide）、光学設計は "1 Micro LED + waveguide" | |
| ディスプレイ色 | **単色グリーン**（Single green display） | フルカラーではない；AIUI の設計規範でも単一のグリーン発光チャネルとして定義されている（`skill: references/design/monochrome-green.md`） |
| ディスプレイ解像度 | **480 × 400** | ⚠️ AIUI ランタイムの基準キャンバス 480 × 352 と一致しない。第 5 節を参照 |
| FOV | 30° | |
| 輝度 | 1500 nits | |
| カメラ | 12 MP、写真解像度 3024 × 4032、絞り F2.25 | 製品ページのマーケティング文案は "Sony sensor" と称するが、仕様表にセンサーの型番は記載されていない；カメラの FOV は公式未公表 |
| 写真フォーマット | 4K 3:4、4K 9:16、3K 4:3 | |
| 動画フォーマット | 最大 3K 30fps（9:16）；ほかに 2.5K 30fps（3:4 / 4:3）、2K 30fps（9:16 / 9:19.5） | |
| マイク | **4 マイクアレイ**（4-microphone array） | |
| スピーカー | デュアルリニア指向性ハイファイスピーカー（Dual linear directional high-fidelity speakers） | |
| センサー | IMU：Supported | 公式製品ページには IMU の軸数／型番は公表されていない；AIUI 側で呼び出せるセンサーは 2.7 を参照 |
| バッテリー | 210 mAh | 連続使用時間の口径は一様でない。下記参照 |
| 連続使用時間 | FAQ では日常使用で約 **8–10 時間**；同ページの比較表では **up to 6 h mixed use**、充電ケース併用で **up to 30 h** | |
| 充電 | マグネット式充電；急速充電で 20 分で 80% まで；充電ケースでメガネを約 10 回フル充電可能；ほかにオプションの Power Capsule アクセサリあり | |
| ワイヤレス接続 | Wi-Fi 6、Bluetooth 5.3（BT 5.3） | |
| 重量 | 49 g | |
| 寸法 | テンプル長 155.5 mm、ヒンジ間隔 146.3 mm、レンズ幅 49 mm、フレーム高 44.4 mm | フレーム素材 TR90、ヒンジはチタン合金 |
| 防塵防水等級 | IPX4 | |
| ウェイクワード | "Hi Rokid" | 中国語のウェイクワードは 3.1（ランタイムドキュメント）を参照 |
| 度付き対応 | 屈折度数 +15 から −15 まで対応、公式の度付きサービス + マグネット式度付きフレーム | |
| システム / OS | **公式未公表** | 製品ページにもドキュメントにもメガネの OS 名／バージョンは記載されていない；判明しているのは、エージェントのランタイムが自社開発の Ink コンテナ（QuickJS + Skia）であること。第 2.1 節および https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md を参照 |
| カメラインジケータ | 対応（Camera indicator: supported） | 撮影時に点灯する、プライバシー設計 |

### 1.1 公式機能リスト（製品レベル、Agent API ではない）

公式製品ページに列挙された本機の機能：リアルタイム翻訳（89 言語対応）、UI 言語 13 種、AI アシスタント（Voice AI + Vision AI、モデルとして Qwen + ChatGPT などに言及）、通知（表示＋音声）、ナビゲーション、プロンプター、メモ、会議の文字起こし、SDK サポート。
注意：これらは**メガネのシステム／公式アプリの機能**であり、AIUI Agent が呼び出せる API とは等しくない（第 2 節を参照）。

---

## 2. AIUI ランタイム機能（Agent が実際に呼び出せる API）

ランタイム環境：Rokid Glasses 上では、エージェントのロジック層とビュー層は **QuickJS**（JS エンジン）と **Skia**（レンダリング）で構築された自社開発コンテナ **Ink** の中で動作し、ウェアラブルデバイスの低消費電力／メモリ／CPU に最適化されている。出典：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
API 契約は以下の skill リファレンスを正とする（`skill: references/apis/*.md`）。この skill は公式リポジトリに付属する開発契約ドキュメントである。

### 2.1 デバイス情報とシステム状態（`navigator`）

出典：`skill: references/apis/navigator.md`

| API | 機能 | 制限／説明 |
|---|---|---|
| `navigator.id` | エージェント＋デバイスに紐づく不透明な ID | 通常の再起動／アップグレードでは安定；認証情報として扱ってはならない |
| `navigator.userAgent` / `versions.ink` / `versions.skia` | ランタイムとレンダリングエンジンのバージョン文字列 | |
| `navigator.language` / `languages` / `region` | 言語設定（BCP 47）と地域 | 空文字列の場合がある |
| `navigator.renderingEnabled` | 現在のインスタンスが可視 UI をレンダリングできるか | |
| `navigator.onLine` / `navigator.connection` | オンライン状態と接続情報：`type`（none/wifi/ethernet/cellular/bluetooth/other/unknown）、`effectiveType`、`downlink`、`rtt`、`saveData`、および `change` イベント | あくまで推定値であり、サービスへの到達可能性を保証しない；スマートフォンの Bluetooth 経由で転送される場合、`type` は `bluetooth` と報告されることがある |
| `navigator.getBattery()` | `Promise<BatteryManager>` を返す | ホストにバッテリー機能がない場合、Promise は拒否される；⚠️ navigator リファレンスはバッテリー取得メソッドが device リファレンスにあるとするが、device リファレンスには実際にはバッテリーの章がない（第 5 節を参照） |
| `navigator.getDeviceSerialNumber()` | デバイスのシリアル番号 | **システムレベルエージェントのみ**取得可能、通常のエージェントには空文字列が返る |
| `navigator.requestDeviceToken()` | デバイストークン | **システムレベルエージェントのみ**、通常のエージェントは依存してはならない |

### 2.2 ディスプレイとウィンドウ（`window`）

出典：`skill: references/apis/window.md`、`skill: references/framework.md`

- `window.innerWidth` / `innerHeight`：読み取り専用のビューポート寸法（論理ピクセル）。
- フルスクリーン Page の基準キャンバス **480 × 352 px**（設計規範の定義、対象デバイス RokidGlasses1 / RokidGlasses2）、安全マージンは左右 16px、上下 12px、有効コンテンツ幅 448px。出典：`skill: references/design/monochrome-green.md`
- Widget（ホーム画面ウィジェット）のサイズファミリー：`1x1` = 239 × 140、`1x2` = 480 × 140；メガネには合計 **4 つの Widget グリッド枠**がある。`family` はあくまでサイズ区分であり、ルートノードをそのピクセル値に固定して書いてはならない。
- `window.open(url, '_widget')`：`app.json` で宣言済みの Widget のみ開ける（唯一の target `_widget`、`placement: 'overlay'` のオーバーレイ対応）；他の Page や外部 URL は開けない。
- `window.close()`：ホストに現在のエージェントインスタンスの終了を要求する。
- `window.atob/btoa`、グローバル `createImageBlob(bitmap, …)`（PNG/JPEG エンコード）。

### 2.3 カメラ（Camera）

出典：`skill: references/apis/media.md`、`skill: references/apis/wx.md`。`CAMERA` 権限の宣言が必要。

| API | 機能 | 主要パラメータ／制限 |
|---|---|---|
| `navigator.mediaDevices.getUserMedia({video})` | 映像ストリーム（MediaStream）を取得 | 制約として `facingMode`、`width`、`height`、`frameRate`、`deviceId` に対応；最終値は `track.getSettings()` で読む |
| `ImageCapture.takePhoto(options?)` | 撮影し、エンコード済みの `Blob` を返す | **3 つのモード**：`mode: 'wide'`（バーコードスキャン用広角）、`mode: 'telephoto'`（遠くの文字を読む望遠）、`mode: 'default'`（通常撮影）；ほかに `quality`、`enableSystemPreview` オプション |
| 撮影のデフォルト出力サイズ | wide = 2016 × 2688；telephoto = 2016 × 1512；default = 3024 × 4032 | 映像ストリームのサイズと異なる場合がある；Blob 自体には幅・高さが含まれず、`createImageBitmap()` でデコードする必要がある |
| `ImageCapture.grabFrame()` | 未エンコードの `ImageBitmap` ピクセルフレームを返す | 使用後は bitmap を close すること |
| `wx.media.createCameraContext().takePhoto()` | wx スタイルの撮影、`{ data: ArrayBuffer, mimeType}` を返す | インタラクティブゲート（interactive）内の呼び出し地点からトリガーしなければならない；モード選択パラメータはない（モード選択は Web の ImageCapture で行う） |
| `MediaRecorder` | 音声・映像ストリームを録画 | `video/webm;codecs=vp8,opus`、`video/mp4` などに対応（事前に `isTypeSupported()` で確認） |

### 2.4 マイクと録音

出典：`skill: references/apis/media.md`。`RECORD_AUDIO` 権限の宣言が必要であり、収録は必ず有効なユーザー操作から開始しなければならない。

| API／パラメータ | 機能 | 主要な制限 |
|---|---|---|
| `getUserMedia({audio:{captureSource}})` | 録音ソースの選択：`'microphone'`（マイク）または `'system-audio'`（デバイス再生のミックス、すなわちシステム音声の内部録音） | system-audio は `echoCancellation: true` や `microphoneMode` と組み合わせられず、組み合わせると `OverconstrainedError`；システム音声はマイクへ自動フォールバックしない |
| `microphoneMode`（マイクモード） | **4 つのモード**：`'wearer'`（デフォルト、装着者の声を優先）、`'far-field'`（遠くの音声）、`'near-field'`（近くの音声）、`'omnidirectional'`（全指向、方向を偏重しない） | マイクソースにのみ有効；各モードへのデバイスの対応は保証されず、非対応の場合は `OverconstrainedError`；実際に効いている値は track の `getSettings()` で読む |
| `MediaRecorder` | 録音エンコード | `audio/wav`、`audio/ogg;codecs=opus` に対応 |
| `wx.media.getRecorderManager()` | wx スタイルの録音（start/pause/resume/stop、フレームコールバックなど） | **デフォルトのマイクを使用し、ソース／モード選択パラメータは提供されない**；モードを選ぶには Web の getUserMedia を使う必要がある |

### 2.5 音声再生と Web Audio

出典：`skill: references/apis/media.md`

- `AudioPlayer`：汎用プレーヤー（ローカルパッケージ内ファイルまたはネットワーク URL）。`pcm` / `ogg_opus` のストリーミング `append()` 再生、字幕テキストトラック（`TextTrack`/`VTTCue`）に対応。
- `Sound`：ローカル効果音の短い再生（ローカルファイルのみ、http(s) URL は拒否）。
- Web Audio：`AudioContext` + `createBuffer/Oscillator/Gain/BiquadFilter/Analyser/MediaStreamSource`、`decodeAudioData` など、マイクの波形／スペクトル分析が可能。

### 2.6 音声合成 TTS

出典：`skill: references/apis/ai.md`

| API | 機能 | 主要な制限 |
|---|---|---|
| `speechSynthesis.speak(utterance, mode?)` | 直接合成して再生（ランタイムの統一プレーヤーがキューイング） | `mode`: `'enqueue'`（デフォルト）/ `'immediate'` |
| `speechSynthesis.synthesize(utterance, options?)` | 生成のみで再生せず、`SpeechSynthesisTask` を返す（音声チャンクイベント、abort 可能、`SpeechAudioPlayer` による独立再生と併用） | オプション：字幕粒度 `subtitles: 'none'/'sentence'/'word'`、音声フォーマット `pcm/mp3/ogg_opus`、サンプルレート、チャンネル数、ビットレート、`AbortSignal` |
| `SpeechSynthesisUtterance` | text/lang/voice/volume/pitch/rate | **`lang` 属性は現状では効かない**（ドキュメントに非対応と明記されており、生成言語は変わらない）；pitch/rate/volume のデフォルトは 1 |
| 公式ボイス ID（全 11 種） | `female-tianmei`、`English_radiant_girl`、`English_expressive_narrator`、`male-qn-qingse`、`male-qn-jingying`、`female-yujie`、`Chinese (Mandarin)_News_Anchor`、`Chinese (Mandarin)_Radio_Host`、`clever_boy`、`lovely_girl`、`English_Trustworthy_Man` | `getVoices()` はなく、`cancel()/pause()/resume()` もない（ドキュメントに未公開と明記） |
| `wx.speech.playTTS(text)` | wx スタイルの一文読み上げ | 文字列（リクエスト ID）を返し、失敗時は空文字列を返す |

### 2.7 センサー（IMU）

出典：`skill: references/apis/device.md`、公式ガイド https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md

| API | データ | イベント／説明 |
|---|---|---|
| `new Accelerometer({frequency?})` | 3 軸加速度 `x/y/z` + `timestamp` | イベント `activate`/`reading`/`error`；`frequency` はホストへのベストエフォートのヒントにすぎない（best-effort hint） |
| `new Gyroscope({frequency?})` | 3 軸角速度 `x/y/z` + `timestamp` | 同上 |
| `new AbsoluteOrientationSensor({frequency?})` | 絶対方位クォータニオン `quaternion`（[x,y,z,w]）+ `timestamp` | 利用可否はデバイスのハードウェア対応に依存 |
| サンプリング周波数 | 公式ガイドの例では 60 を使用、30–60 Hz から始めて必要に応じて上げることを推奨 | 公式に公表された最大周波数／精度の数値はない |

注：API 層が公開するのは以上の 3 種のセンサーのみ；公式 API リファレンスには、地磁気／光／近接センサー単独の API は現れていない。

### 2.8 音声認識 ASR

出典：`skill: references/apis/ai.md`。**独立した `SPEECH_RECOGNITION` 権限はない**（ドキュメントに廃止済みと明記）；マイクを開くには依然として `RECORD_AUDIO` が必要。

| API | 機能 | 主要な制限 |
|---|---|---|
| `new SpeechRecognition()` | ホストマイクによる認識：`lang`、`continuous`、`interimResults`、`maxAlternatives`；イベントには `result`/`nomatch`/`error` など Web Speech 風イベント一式を含む | `start()` は所属ビューがインタラクティブ状態を保っていることを要求し、非インタラクティブ状態では直ちに `InvalidStateError`；`lang` が空の場合はホストがデフォルト言語を選ぶ |
| `new SpeechRecognitionSession(options?)` | 外部音声ストリームの認識（MediaRecorder で音声チャンクを自ら `session.audio` 書き込みストリームへ供給する。セッション自体はマイクを開かない） | オプションにはホットワード `phrases: [{phrase, boost}]`、セグメンテーション `segmentation: 'auto'/'vad'/'semantic'/{mode:'vad', silenceDurationMs}`、`updateContext(messages)` による動的コンテキストを含む |
| `SpeechRecognitionSession.getCapabilities()` | ホストの実能力を照会：音声フォーマット／サンプルレート、`maxChunkBytes`、interim／ホットワード／コンテキスト対応の有無、VAD しきい値の範囲 | 能力はホストによって異なるため、必ず先に照会してから使うこと |

### 2.9 大規模言語モデル LLM

出典：`skill: references/apis/ai.md`

| API | 機能 | 主要な制限 |
|---|---|---|
| `LanguageModel.availability()` | `'available'/'unavailable'` を返す | プロバイダ、モデル一覧、エンドポイント情報は**公開されない** |
| `LanguageModel.create({model?, initialPrompts?, tools?})` | セッションを作成；モデルの解決順序：明示的な `model` → ホストの `defaultModel` | 基盤はホストの **OpenAI 互換 chat-completions ストリーミングチャネル**；`system` は initialPrompts の先頭にのみ置ける |
| マルチモーダル入力 | user メッセージの content 配列は `{type:'text'}` と `{type:'image_url', image_url:{url}}`（data: URL を含む）に対応 | 構造化 content は user ロールに限る |
| ツール呼び出し | `tools`（function 型）はプロバイダのリクエストボディへ転送される；ツール呼び出しはセッションの `toolcall` イベントとして返ってくる（callId/functionName/arguments） | **自動実行ではない**：JS 側で自らイベントを処理する必要があり、構造化されたツールコールの往復プロトコルの保証はない |
| `session.prompt(input)` / `promptStreaming(input)` | 一括回答／ストリーミング回答（ポーリング式の `read()`、WHATWG Stream でも async iterator でもない） | 同一セッションでは同時に 1 件のリクエストのみ進行可能；`destroy()` 後は再利用不可 |
| `wx.speech.startRecognition()` | wx スタイルで認識を開始（文字列を返す） | 2.8 とは別の入口 |

### 2.10 位置情報（Geolocation）

出典：`skill: references/apis/geo/geolocation.md`。`GEOLOCATION` 権限の宣言が必要（宣言してもシステムが拒否する場合がある）。

- `navigator.geolocation.getCurrentPosition(success, error?, options?)` / `watchPosition(...)`（数値型の watch ID を返し、`clearWatch` で解放）。
- オプション：`enableHighAccuracy`（デフォルト false）、`timeout`、`maximumAge`（省略時はホストが決定）。
- 結果：`coords` には `latitude`、`longitude`、`accuracy`（メートル）と、nullable な `altitude`、`altitudeAccuracy`、`heading`、`speed` を含む；エラーコード 1/2/3（拒否／利用不可／タイムアウト）。
- 付随する `GPXDocument` API（`'gpx'` モジュール）：GPX ルートの解析、作成、エクスポート（setStartPoint/addWaypoint/appendTrackPoint/toString/toBlob）。`<map>` / `<map-gpx>` コンポーネントと組み合わせて軌跡表示を行う。出典：`skill: references/apis/geo/gpx-document.md`、`skill: references/components.md`

### 2.11 Bluetooth BLE（クライアント）

出典：`skill: references/apis/device.md`

- `navigator.bluetooth`：`getAvailability()`、`getDevices()`、`requestDevice({acceptAllDevices?, optionalServices?, filters?:[{name?, services?}]})`、`scanDevices(options?)`（Ink 独自、標準の Web Bluetooth ではない）。
- GATT：`device.gatt.connect()/disconnect()/getPrimaryService(s)/…`、キャラクタリスティックの `readValue()`（`Promise<number[]>` を返す）、`writeValue(With/WithoutResponse)`、`startNotifications()` + `characteristicvaluechanged` イベント。
- 制限：`requestDevice`、`scanDevices`、`gatt.connect()`、`startNotifications()` はいずれも所属ビューが**インタラクティブ状態**を保っていることを要求する；`getAvailability/getDevices` はこの限りではない。役割は BLE の**セントラル（client）**；公式 API リファレンスには BLE ペリフェラル（周辺機器／アドバタイジング）の機能はない。

### 2.12 ストレージとファイル

出典：`skill: references/apis/web.md`、`skill: references/apis/wx.md`、`skill: references/apis/navigator.md`、`skill: references/framework.md`

- `localStorage`：現在のエージェントに隔離された文字列 KV（getItem/setItem/removeItem/clear）。
- wx ストレージ：`wx.setStorage/getStorage/removeStorage/clearStorage` および `Sync` 同期版。データは JSON シリアライズされる。
- `navigator.storage`：StorageManager。ドキュメントでは "Persistent file storage entry point"（永続ファイルストレージへの入口）と定義されている——⚠️ skill リファレンスにはそのメソッドの詳細が示されていない（第 5 節を参照）。
- ファイルモデル：リソースはすべて**プロジェクト内のパス**から解決される（例：`/assets/icon.png` は .aix にパッケージされる）；公式フレームワークドキュメントは、**デバイスのファイルシステムへ任意にアクセスできると想定しないこと**を明確に注意している。公式 API リファレンスには汎用ファイルシステム API は存在しない（任意パスへの読み／書き／ディレクトリ一覧のインターフェースはない）。
- ⚠️ **FileReader は存在しない（実機で実証、2026-10-28、グローバルエラーコード E2005）**：Ink ランタイムに `FileReader` はなく、aiui-dev 公式リファレンス全文にもこの API はない。`Blob → dataURL` は `blob.arrayBuffer()` + チャンク分割した `btoa` 変換で行う（あるいはビットマップを直接保存する）必要がある；いかなる `new FileReader()` / `readAsDataURL` も実機では必ず `FileReader is not defined` を投げ、フレームごとに失敗する。開発時は公式 API リファレンスのリストを正とすること：リストにない API は存在しない。ブラウザの習慣で想定してはならない。

### 2.13 ネットワーク

出典：`skill: references/apis/web.md`、`skill: references/apis/wx.md`、公式ガイド https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md

- `fetch` / `Headers` / `Response`（`body` の ReadableStream によるストリーミング読み込み、BYOB を含む）、`WebSocket`、`File`/`FormData`、`URL`/`URLSearchParams`、Streams 一式（Readable/Writable/Transform）。
- `wx.request`（タイムアウトの解決順序：options.timeout → app.json の設定 → デフォルト 60000 ms）、`wx.createSocket/connectSocket`、`wx.createEventSource`（SSE）。
- `crypto`：`randomUUID`、`getRandomValues`（上限 65,536 バイト）；`crypto.subtle` は SHA-1/256/384/512 ダイジェストと HMAC（generateKey/importKey/exportKey/sign/verify）**のみ**——暗号化／復号、RSA、ECDSA、JWK は**非対応**。
- **モバイルプロキシ経由の通信（Mobile Proxy）**：メガネが Wi-Fi に接続していなくても、Bluetooth でスマートフォンアプリ（Rokid AI App / Hi Rokid）とつながっていれば、`fetch`/`wx.request` は自動的にスマートフォンの回線経由で転送され、開発者には透過的で、消費電力も抑えられる。
- **HTTPS 必須**：本番環境のネットワークリクエストは HTTPS でなければならない；ストア公開前に、リクエスト先ドメインを開発者バックエンドで**ホワイトリストとして事前に届け出る**必要がある。
- **LAN 直接接続：非対応**（公式ガイドでは「開発中」とされ、ドキュメント目次では LAN の節に `status: unsupported` と標記）。

### 2.14 Canvas 2D とバーコード検出

出典：`skill: references/apis/canvas.md`

- `CanvasRenderingContext2D`：パス／矩形／テキスト（`measureText` を含む）／変換／グラデーション／パターン／画像データ／`drawImage`（3/5/9 引数の 3 形式のみ）など；入口はページ内 `<canvas>`（`wx.createCanvasContext(id)`）またはスクリプトで生成する `new Canvas(w,h)`。
- 色の解析は限定的：`#rrggbb`、`#rgb`、`rgb()`、`rgba()` と black/white/red/green/blue/yellow/transparent など少数の名前付き色のみ。
- 出力：`canvas.convertToBlob({type, quality})`（PNG がデフォルト、JPEG の品質は 0–1；透明ピクセルは JPEG では黒背景に合成される）、グローバル `createImageBlob()`。
- `BarcodeDetector`（`'barcode'` モジュールまたはグローバル）：`getSupportedFormats()` で対応するバーコード形式を照会（規範名は `qr_code`、`code_128`、`ean_13` など）；`detect(image)` は ImageData、エンコード済み画像 Blob、ImageBitmap を受け取り、`format`、`rawValue`、`boundingBox`、`cornerPoints` を返す。OffscreenCanvas/VideoFrame/HTML 要素系の入力には非対応。

### 2.15 インタラクションイベント（ランタイム層）

出典：`skill: references/events.md`。詳細は第 3 節のインタラクションモデルを参照。

- テンプレートイベント：`bindtap`/`catchtap` など `bind<event>` バインディング；アニメーションイベント `bindanimationstart/iteration/end/cancel`。
- キーイベント：Page の `onKeyDown/onKeyUp(event)`、`event.code` で振り分け（Rokid Glasses のマッピングは 3.2 を参照）。
- 音声ウェイクアップコールバック：`onVoiceWakeup(event)`。
- 環境認識（Page 内で `enableWorldAwareness()` を有効化する必要あり）：`onHeadGesture(event)`（ジェスチャ値の例 `'nod'`）、`onOrientationStabilityChange(event)`（`event.stable` 頭部の安定性）。
- ネットワーク状態：App/Page の `onNetworkStatus(event)`。

### 2.16 フレームワークとコンポーネント面

出典：`skill: references/framework.md`、`skill: references/components.md`、`skill: references/apis/agent-worker.md`

- プロジェクト構成：`app.json` + `app.js` + `AGENTS.md` + `pages/`（`.ink` 単一ファイル、または `.json/.wxml/.wxss/.js` の 4 点セット）+ 任意の `widgets/`、`workers/`、`components/`、`assets/`。
- 組み込みコンポーネントは合計 **37 の記述可能なタグ**：コンテナ／テキスト／フォーム（button/input/textarea/switch）／メディア（image/video/lottie-view）／地図（map、map-gpx）／キャンバスとチャート（canvas/chart）／AI 生成 UI（a2ui）など。
- Agent Worker：UI を持たないスクリプト（open でトリガー、`lifetime: 'instant'|'foreground'`、`background` は予約済みで無効）；タイマー、Promise、Crypto、Wasm、符号化ストリームはあるが、`window/document/fetch`、ルーティング、レンダリング、メディア収録は**ない**。
- TypeScript エントリと WebAssembly モジュールに対応（プロジェクトのパッケージング手順を経由）。

### 2.17 権限リスト（app.json.permissions、正確な名称）

出典（2026-10-29 の全量監査で訂正）：`documentation/1-framework/open-agent-format/app-json.md` の権限表、全 **7 個**。名称は**大文字小文字を区別し**、認識されない名称にはいかなる能力も付与されない；リストへの宣言 ≠ システムの許可であり、呼び出し側では依然として拒否を処理する必要がある。注：aiui-dev Skill の `references/framework.md` は依然として最初の 3 つのみを列挙しており、これは上流ドキュメント内部の不整合である。framework ドキュメントを正とする。

| 権限名 | 用途 |
|---|---|
| `GEOLOCATION` | 現在位置の取得／位置変化の監視 |
| `CAMERA` | カメラへのアクセス、画像または動画の撮影 |
| `RECORD_AUDIO` | マイクへのアクセス、音声の収録（ASR のマイク開放、録音はいずれもこれに依る；独立した ASR 権限はなく、旧 `SPEECH_RECOGNITION` 権限は Ink 0.19 で削除された） |
| `READ_MEDIA_IMAGES` | システムのメディアライブラリ内の画像の一覧表示と読み取り |
| `CREATE_MEDIA_IMAGES` | システムのメディアライブラリへの画像の追加（既存リソースの変更／上書きは含まない） |
| `READ_MEDIA_AUDIO` | システムのメディアライブラリ内の音声の一覧表示と読み取り |
| `CREATE_MEDIA_AUDIO` | システムのメディアライブラリへの音声の追加（既存リソースの変更／上書きは含まない） |

補足：審査提出の段階（Studio／ストア）には別途**宣言型のチェック項目**——ネットワーク、カメラ、マイク、スピーカー、Rokid アカウント情報など——があり、項目ごとに用途を記入する必要がある。リスト権限とは別の仕組みである。出典：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md

---

## 3. インタラクションモデル

### 3.1 ウェイクアップ

- 製品レベルのウェイクワード：**"Hi Rokid"**。
- ランタイムの `onVoiceWakeup(event)`：音声でもタッチでもトリガーできる；既知の `event.keyword` の値には `乐奇`（中国語のウェイクワード）、`Hi Rokid`、`clickAiAssist`（タッチによるウェイクアップ）がある。デフォルトでは keyword でフィルタしないこと；`event.preventDefault()` でホストのデフォルト動作を引き継げる。

### 3.2 テンプルのタッチとキーマッピング

ランタイムは**キーイベント**の形で配信する（`onKeyDown/onKeyUp` + `event.code`）。Rokid Glasses のマッピングは以下の通り：

| `event.code` | 意味 | デフォルト動作（onKeyUp の後） |
|---|---|---|
| `Enter` | 確定／アクティブ化 | ナビゲーションモードに入る、または現在のターゲットをアクティブ化 |
| `Backspace` | 戻る | 一つ前の階層へ戻る；戻るページがない場合はエージェントの終了を要求 |
| `ArrowUp` / `ArrowDown` | 上／下方向 | 現在のナビゲーションパス内で移動、またはルートビューをスクロール |
| `GlobalHook` | **テンプルのボタンタッチ**に対するデバイス固有の信号（標準の Web キー値ではない） | デフォルト動作なし；ドキュメントでは onKeyDown でのみ高速応答に使い、戻る／確定の区別には Backspace/Enter を使うことが推奨されている |

製品側の補足：製品ページには "Quick Action Shortcuts — Tap to launch the features you use most"（テンプルをタップしてよく使う機能をクイック起動）と独立した撮影操作（"One word or one press" で撮影）があると記されている。

### 3.2.1 テンプルタッチパッド完全ジェスチャ表（実機で実証、Hi Rokid App「操作ガイド」）

出典：Hi Rokid App 内蔵の操作ガイド（実機の挙動であり、これを正とする；タッチ位置はテンプルの中段）。これは §3.2 のキーイベントに対する製品レイヤーの完全なマッピングであり、ランタイムの `Enter`/`Backspace`/`ArrowUp/Down` の発生源はこれらのジェスチャである。

**1 本指のインタラクション（汎用）**

| ジェスチャ | システムの挙動 | ランタイム対応 |
|---|---|---|
| シングルタップ | 確定 | `Enter` |
| ダブルタップ | 戻る | `Backspace` |
| タッチパッド長押し | アシスタントを起動（App で「メガネ AI アシスタント（デフォルト）」または「スマートフォンアシスタント」を選択可能） | `onVoiceWakeup`（keyword `clickAiAssist`） |
| スワイプ | 前方向スクロール（方向は App で変更可能） | `ArrowUp` / `ArrowDown` |

**1 本指・シナリオ別**：音楽——ホーム画面でのシングルタップ = なし；音楽アプリ内でのシングルタップ = 再生／一時停止；前／後スワイプ = 次の曲／前の曲。通話——着信中のダブルタップ = 拒否；通話中のシングルタップ = ミュート／ミュート解除；通話中のダブルタップ = 終話。

**2 本指のインタラクション（2 本指を開いてテンプル中段に触れる）**

| ジェスチャ | システムの挙動 |
|---|---|
| ダブルタップ | 画面オフ |
| 長押し | **AI クイック指令**：選択した「トリガー対象」へ固定の指令を送信する（下記参照） |
| 前後スワイプ | 音量の増減（デフォルト、変更可能） |

**AI クイック指令（2 本指長押し）**：App でオン／オフ可能；指令はプリセット（「看一下面前这是什么」「拍照翻译成中文」「今天天气」）から選ぶか、カスタムテキスト（500 字まで）が使える。重要な点：**トリガー対象には特定のカスタム／デバッグ Agent を選べる**——すなわち 2 本指長押し = ASR ゼロで、決定的に固定テキストを指定した Agent へ届ける手段であり、音声ウェイクアップの誤認識を回避するハードウェアレベルの入口である（実機で動作確認済み）。


### 3.3 「注視」とは実際には何か：頭部の向きであり、アイトラッキングではない

**結論：AIUI にアイトラッキング（eye tracking）API はない；いわゆる「注視」は頭部の姿勢で実現される。**

根拠：
1. 公式 API リファレンス（skill の全 apis ファイル）には、アイトラッキング／視線座標の API は一切存在しない；全文検索でも eye-tracking に関する項目はない。
2. 指向能力は IMU が提供する：`AbsoluteOrientationSensor` が頭部の向きのクォータニオンを与える（2.7）。
3. ワールド認識コールバックは 2 つのみ：`onHeadGesture(event)`（ドキュメント化されたジェスチャ値の例は `'nod'` うなずき）と `onOrientationStabilityChange(event)`（頭部の安定性の変化）——すなわち「対象を見て頭を静止させる → トリガー」というインタラクションパラダイムは**頭部の静止検出**に依拠しており、公式の例もまさに `event.gesture === 'nod'` のときに確定するものである。出典：`skill: references/events.md`
4. 製品ページとドキュメントは、アイトラッキング用ハードウェアを謳ったことがない；仕様表のセンサーは "IMU: Supported" とのみ記載。

したがって：「注視」系インタラクションの開発 = 頭部の向き（クォータニオン／方向）+ 頭部静止イベント + うなずきによる確定。**首振り（shake）など他のジェスチャ値は公式ドキュメントに列挙されていない**——`onHeadGesture` の完全なジェスチャ列挙は公式未公表である（第 5 節を参照）。

### 3.4 音声インタラクションのフロー


ウェイクワード／タッチウェイクアップ → `onVoiceWakeup` → Agent 内で `SpeechRecognition`（ホスト認識）または `SpeechRecognitionSession`（自前の音声ストリーム）による ASR → `LanguageModel` セッション推論（画像入力も可）→ `speechSynthesis.speak/synthesize` または `AudioPlayer` による読み上げ。会話フローカード（conversation-flow card）はデフォルトでは**表示のみ**であり、インタラクティブな UI には全画面 Page または Widget が必要である（`skill: SKILL.md` Core Rules）。

### 3.5 スマートフォンコンパニオンアプリの役割


- ネットワークプロキシ：メガネに Wi-Fi がないとき、Bluetooth 経由でスマートフォンアプリ（海外版 **Hi Rokid**、パッケージ名 `com.rokid.sprite.global.aiapp`）を介して通信する（2.13）。
- デバイス管理とリソース配信：メガネの接続／管理、設定の調整、メディアの管理、AI 機能の入口（翻訳／字幕／プロンプター／デバイス制御）——製品ページ FAQ。
- Agent の配信チェーン：Studio でパッケージしてクラウドへアップロード → App がメガネのリソースパッケージを更新 → メガネ側で実行（本プロジェクトの既定フロー；公式ガイドの公開フローは「ビルド → Web シミュレーション → AIX パッケージをクラウドへアップロード → 実機デバッグ」、出典：publish.md）。

---

## 4. プラットフォームの制限と制約（開発者の視点）

### 4.1 ディスプレイ／UI の制約

- 単一のグリーンチャネル：可視ピクセルはすべて同一のグリーンの異なる輝度でしかない（基調色 `#40ff5e`、6 段階の輝度階調）；**黒 = 透明な背景**であり、不透明な黒いパネルで現実の環境を遮蔽することは期待できない。
- 意味を色だけに依存させてはならない：状態／重要度にはアイコン、テキストラベル、線種、アニメーションなどの冗長な符号化を重ねる必要がある。
- 基準キャンバス 480 × 352、重要な情報は中央の快適な視野内に収めること；本文テキストの輝度は 72% 以上を推奨、装飾線は 24% 以下。

### 4.2.aix パッケージの制約

- AIX = "AI eXecutable"、AIUI が定義する独自の配布フォーマットで、内部は OAF（Open Agent Format）規範に準拠し、コード（WXML/WXSS/JS）、設定（JSON）、静的リソースを自己完結的に含む。
- パッケージング時に一意の UUID を持つ `VERSION` ファイルが自動生成され、バージョン検証／ホットアップデートに使われる；パッケージングは PNG/JPEG 圧縮と JSON の難読化圧縮に対応。
- **パッケージサイズの上限：公式未公表**（調査したドキュメントに数値なし）。
- プロジェクト側のレッドライン：`.aixignore` で `.agents/`、`.aix/`、`artifacts/`、`*.aix`、`skills-lock.json`、`node_modules/` を必ず除外すること。さもなければ開発ファイルがパッケージに入る（実測 2.3 KB → 107 KB）。出典：本プロジェクトのルート README（リポジトリ sakai55/rokid）。

### 4.3 AIUI が明確に公開しない／対応しない機能

| 機能 | 状態 | 根拠 |
|---|---|---|
| **OCR（文字認識）API** | **存在しない** | 公式 API リファレンスの全リスト（skill apis ディレクトリ）と公式ドキュメント目次に OCR の項目はない；「文字を読む」ための公式の経路は telephoto 撮影 + LLM 画像入力（2.3 / 2.9） |
| アイトラッキング | 存在しない | 3.3 を参照 |
| LAN 直接接続通信 | 非対応（開発中） | 公式ネットワークガイド + ドキュメント目次 `lan: status unsupported` |
| データのプリフェッチ prefetch | 非対応 | ドキュメント目次 `prefetch: status unsupported` |
| Source map デバッグ | 非対応 | ドキュメント目次 `sourcemap: status unsupported` |
| WXML `<template>` | 非対応 | ドキュメント目次に unsupported と標記 |
| Agent Worker のバックグラウンド常駐 | 非対応 | `lifetime: 'background'` は予約済みで無効；Worker には fetch もない |
| Web Crypto の暗号アルゴリズム | SHA ダイジェスト + HMAC のみ | `skill: references/apis/web.md` に RSA/ECDSA/暗号化・復号/JWK は非対応と明記 |
| TTS の言語切り替え | `lang` 属性が効かない | `skill: references/apis/ai.md` に明記 |
| TTS のキュー制御 | cancel/pause/resume/getVoices なし | 同上 |
| 汎用ファイルシステム | 任意パスへのファイル API なし | 2.12 |
| デバイスのシリアル番号／トークン | システムレベルエージェントのみ | 2.1 |
| LLM プロバイダ情報 | availability() は提供しない | 2.9 |

### 4.4 審査／公開の制約

> 注意：この公式ドキュメントが記述するのは **Rokid Ai エージェントストア（中国大陸）** への公開フローである；Global 版は Global AIUI Studio の Submit タブから行い、要求は概ね一致する（本プロジェクトで実測）。

- 名称：必須、20 文字以内、他者と重複不可、「测试/test/beta」、価格・販促、極端な表現を含めてはならない；コピーでは「官方/权威/推荐/TOP1」などの示唆的な語や「100% 准确」のような絶対的な訴求は禁止。
- アイコン：必須かつ**デフォルトアイコンは使用不可**、ぼやけ／引き伸ばし／透かし・QR コード入り／単色＋文字のみは不可。
- 機能紹介は 500 文字以内；オープニングメッセージは必須、300 字以内を推奨；バージョン番号と Agent ID はいずれもシステムが生成し、開発者は編集できない。
- 権限：実際に使用するすべての権限を正直にチェックし、項目ごとに用途を明記すること。「最小限必要 + 用途の真実性」に従う；未宣言なのに呼び出す、説明が曖昧、コードの挙動と一致しない場合は却下され得る。
- プレビュー素材：**3–5 ファイル**が必須、画像 1 点以上 + 動画 1 本以上；画像は JPG/PNG（1:1 を推奨）、動画は MP4（1:1 を推奨）、長さ 60 秒以内（15–45 秒を推奨）、単一ファイル 50 MB 以下を推奨；動画では 1–2 個のコアフローを完全にデモすること。
- コンテンツ安全：UGC には安全フィルタが必要；AI 生成・合成コンテンツには法令に従い標識を付すこと；エージェントは正常に起動、インタラクション、復帰ができ、頻繁にクラッシュしてはならない。
- フロー：ビルド → Web シミュレーション → AIX パッケージをクラウドへアップロード → 実機デバッグ → 審査資料の整備 → 審査提出 → 結果（却下の場合は修正して再パッケージのうえ再提出；承認後はストアに公開）。

### 4.5 ランタイムとインタラクティブゲートの制約

- **インタラクティブゲート（interactive gate）**：BLE の requestDevice/scanDevices/connect/startNotifications、SpeechRecognition.start、RecorderManager.start、CameraContext.takePhoto、getUserMedia による収録などはいずれも、所属ビューがインタラクティブ状態にあることを要求し、通常はユーザー操作によるトリガーも必要である；非インタラクティブ状態での呼び出しは直接エラー／失敗となる。
- リソースのライフサイクル：マイク／カメラの track は使い終わったら必ず stop；BLE スキャンは停止し、GATT は切断する；watchPosition は clearWatch；AudioContext は close する。公式チェックリストではこれらが納品のレッドラインとされている（`skill: references/checklist.md`）。
- シミュレータ ≠ 実機：DevTools 内のセンサーは多くが模擬値であり、性能／発熱／スロットリングは実機と異なる。公式は実機を正とするよう要求している（env.md）。

---

## 5. 矛盾と未確認事項

1. **ディスプレイ解像度の口径の不一致**：公式製品仕様表には **480 × 400** とある；AIUI の設計規範と Widget サイズファミリーは **480 × 352** の基準キャンバスに基づく（1x2 Widget の幅 480 もこれと一致）。いずれも公式ソースである——480×400 がパネルの物理解像度、480×352 がランタイムの安全キャンバスと推測されるが、公式はこの説明をしていない。
2. **FOV に関する第三者の説**：非公式のレビュー（Notebookcheck など）は 23° とするが、公式製品ページは **30°**。公式を正とし、23° は**公式未確認**と標記する。
3. **ディスプレイ解像度に関する第三者の説**：一部の非公式レビューは 640×480 とするが、公式の 480×400 と一致せず、**公式未確認**。
4. **連続使用時間の口径が複数**：公式の同一製品ページ内で、FAQ は日常使用 8–10 時間、比較表は混合使用 6 時間／ケース併用 30 時間と記載；統一されたテスト条件下での公称値は示されていない。
5. **第 2 のチップ**：製品ページには "Dual-Chip Performance" の宣伝文句があるが、公式仕様表の SoC は Snapdragon AR1 のみを列挙；第 2 のチップの型番（第三者が言う NXP RT600 など）は**公式仕様ページでは未確認**。
6. **カメラの詳細が欠落**：センサーの型番（マーケティング文案は Sony と称するが仕様表に型番なし）、カメラの FOV（第三者は 109° とする）はいずれも**公式未公表**。
7. **IMU の詳細が欠落**：製品ページは "IMU: Supported" のみ；軸数、型番、サンプリング周波数の上限、精度はいずれも公表されていない；API 側の frequency はベストエフォートのヒントにすぎず、保証値はない。
8. **頭部ジェスチャの列挙が未公表**：`onHeadGesture` の公式例は `'nod'` のみを示す；首振り、顔上げなど他のジェスチャ値が存在するか、名称は何かは、公式ドキュメントに完全には列挙されていない。
9. **`navigator.getBattery()` のダングリング参照**：navigator リファレンスはバッテリー取得メソッドを device リファレンスで参照するが、device リファレンスには BatteryManager の章がない——API の存在は navigator リファレンスを正とし、詳細（プロパティ／イベント）は skill には示されていない。
10. **`navigator.storage`（StorageManager）の詳細が欠落**：navigator リファレンスは "Persistent file storage entry point" の一文のみで、メソッドシグネチャはない；localStorage/wx ストレージとの境界は skill には説明されていない。
11. **デバイス世代間の差異が未検証**：events リファレンスは **Rokid Glasses 2** と**第 1 世代フルカラーメガネ**のキーマッピングが "remain unverified" であることを明記しており、Rokid Glasses（第 1 世代・単色グリーン）のマッピングを流用してはならない；設計規範の対象デバイスは RokidGlasses1 / RokidGlasses2 と記されている。
12. **ドキュメントのバージョンが二重化**：公式ドキュメントには現在 2 つのサイトがある——open.rokid.com/aiui（現行版）と js.rokid.com（旧版、AI 開発ガイドは /AIUI/guide/quickstart/ai-dev に所在）；本アーカイブの API 契約は公式リポジトリの現行 `documentation/` と `skills/aiui-dev` を正とし、両サイトの内容差異はページ単位では比較していない。
13. **OS は未公表**：メガネの OS 名／バージョンは公式製品ページにもドキュメントにも記載されていない（判明しているのはランタイムが Ink/QuickJS+Skia コンテナであることのみ）。
14. **.aix パッケージサイズの上限は未公表**；ドメインホワイトリストの届出先／審査所要時間も公開ドキュメントには詳述されていない。

---

## 6. 公式ソース一覧

**製品とプラットフォーム**
- Rokid Glasses 公式グローバル製品ページ（仕様の主たる出典）：https://global.rokid.com/products/b-h-rokid-glasses-with-display
- Rokid 英国公式サイト AI 製品ライン（仕様の相互裏付け）：https://gb.rokid.com/collections/rokid-ai-lineup
- 公式 Academy チュートリアル『3.6 Glasses AIUI』（Craft/Studio ワークフロー）：https://global.rokid.com/de/blogs/academy-glasses/glasses-3-6-aiui

**公式ドキュメントサイト**
- AIUI ドキュメント（現行版）：https://open.rokid.com/aiui
- AIUI ドキュメント（旧版）：https://js.rokid.com/AIUI/guide/quickstart/ai-dev

**公式 GitHub リポジトリ yodaos-project/AIUI（jsar-project/AIUI はここへリダイレクトされる）**
- リポジトリトップ／README（位置づけ、Samples 索引）：https://github.com/yodaos-project/AIUI
- Samples ディレクトリ（bluetooth / capabilities / cut-card / games / gyroscope-test / meal-card / navigator-info / realtime-voice-intelligence / scanner / tts）：https://github.com/yodaos-project/AIUI/tree/main/samples
- aiui-dev skill（本アーカイブの API 契約の主たる出典）：https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev
- 審査と公開：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md
- AIX とは：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/aix.md
- ランタイム環境：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
- IMU ガイド：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md
- ネットワーク利用説明（モバイルプロキシ / HTTPS / ドメインホワイトリスト / LAN）：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md
- ドキュメント目次（lan/prefetch/sourcemap などの unsupported 標記を含む）：https://github.com/yodaos-project/AIUI/blob/main/documentation/toc.json
