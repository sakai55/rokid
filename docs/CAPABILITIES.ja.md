# Rokid Glasses 能力アトミックレジストリ

[中文](CAPABILITIES.md) | [English](CAPABILITIES.en.md) | 日本語

中文版 v2.0.0（2026-10-29）からの翻訳。齟齬がある場合は中文版が優先する。

> 作成日：2026-10-24；現在のバージョン v2.0.0、2026-10-29
> 資料原則：**Rokid 公式ソースのみを採用する**（公式製品ページ、公式ドキュメントサイト、公式 GitHub リポジトリ `yodaos-project/AIUI` とその内蔵 `aiui-dev` skill リファレンス）。これに加えて、本レジストリのメンテナ自身による実機およびビルドの検証があり、検証結論は条目の中に個別に明示する。公式リポジトリの `skills/aiui-dev` が API 契約の主ソースであり、以下の根拠は `skill: references/…` と表記する。

## はじめに

本レジストリは 1 人の Rokid AIUI 開発者が維持するもので、Rokid の公式文書ではない。Rokid Glasses の基盤能力をアトミックな条目に分解する。1 条目は基盤プリミティブ 1 件だけを述べ、安定した番号、1 文の結論、公式根拠と検証状態を持つ。Agent を設計する前に、まずここで、使おうとするプリミティブが存在するかどうか、境界がどこにあるかを調べる。

本表にはプリミティブだけを登録し、アプリケーションシナリオは登録しない。シナリオはプリミティブの組み合わせであり、その書き方は無限にあって、1 件ずつ収録していけば際限のない Q&A 集になる。どのシナリオの問いにも同じ道筋で答える。シナリオを必要なプリミティブに分解し、本表を 1 件ずつ引く。プリミティブがあれば組み合わせは成立する。プリミティブがなければ、答えは「できない」であり、その問いのために条目を 1 件開く必要はない。公式 API リファレンスそのものが閉じたリストであり、リストにない API は存在しない。これが本表の大半の項目の判定根拠である。

維持の方法はエラーコード表 `ERROR-CODES.md` と同型である。条目は段の末尾にだけ追加し、番号は二度と使い回さない。結論が覆った条目は結論を書き換えて変更履歴に痕跡を残し、番号は消さない。結論に変化があればバージョンを上げ、旧版は `base/capabilities/` にアーカイブして索引を付ける。中文版が正本であり、英日版は翻訳である。齟齬がある場合は中文版が優先する。

## 1. 番号とガバナンス

番号は `C2003` の形で、文字 C に 4 桁の数字が続き、千の位が段番号、段の中では連番である。

| 段 | 領域 |
|---|---|
| C1xxx | ハードウェアと表示 |
| C2xxx | カメラと画像 |
| C3xxx | オーディオ、音声、大規模モデル |
| C4xxx | センサーと測位 |
| C5xxx | 表示ランタイムとページ |
| C6xxx | ストレージ、ファイル、ネットワーク |
| C7xxx | 権限 |
| C8xxx | インタラクションとホスト |
| C9xxx | 配布と審査提出 |

検証状態は 4 種の値だけを使う。**文書**：公式文書の根拠だけがあり、実機ではまだ検証していない。**実機検証済み**：実機から返ってきた結果や挙動の証拠がある。**ビルド検証済み / Studio 検証済み**：パッケージングや Studio のフローの中で検証した。**検証待ち**：プローブは既にあるがデータが戻ってきておらず、プローブは第 4 節にある。バージョン規則：条目の追加または条目の結論の変化で MINOR を上げ、構造や規則の変化で MAJOR を上げ、文言の修正で PATCH を上げる。

## 2. 総則

総則は条目ではなく、シナリオの答えを導くときに条目と同等に適用される規則である。

- **R1 クローズドループの位置づけ**（公式見解、2026-10-29）：Agent は本質的にクローズドループを完結させる。1 つの Agent は、自ら宣言した権限と呼び出し可能な API によって、自分の内部で 1 件の物事を入口から結果までやり遂げる。ループの外側にあるホストの能力、すなわちシステム設定、他の Agent、ホストの構成は、Agent には委ねられない。出典：公式回答。本レジストリのメンテナによる伝達。
- **R2 リストこそが境界**：公式 API リファレンスは閉じたリストである。見つからない API、パラメータ、列挙値はすべて存在しないものとして扱い、ブラウザや WeChat ミニプログラムの慣習で仮定しない。
- **R3 インタラクションゲート**：収集系と接続系の呼び出し（撮影、録音、ASR の開始、BLE 接続など）は、属するビューがインタラクティブな状態にあることを要求し、通常はユーザー操作によるトリガーも必要とする。インタラクティブでない状態での呼び出しはそのまま失敗する。リソースは使い終わったら解放しなければならない。マイクとカメラの track は stop し、BLE のスキャンと接続は切断し、watchPosition は clearWatch し、AudioContext は close する。
- **R4 宣言は認可ではない**：権限を app.json に書くのは宣言にすぎず、システムは呼び出しの地点でなお拒否できる。コードは拒否される分岐を処理しなければならない。
- **R5 シミュレータは実機ではない**：Web シミュレータではセンサーは模擬値であることが多く、性能と発熱は実機とは異なる。条目の検証状態が「文書」となっているものは、結論は実機での再検証を基準とする。

## 3. 条目

### 3.1 ハードウェアと表示

根拠：公式グローバル製品ページ https://global.rokid.com/products/b-h-rokid-glasses-with-display 。英国公式サイトの同じスペックで相互に裏付ける。

| 番号 | プリミティブ | 結論 | 実測 |
|---|---|---|---|
| C1001 | メインチップ | Snapdragon AR1。製品ページには別に「デュアルチップ」のうたい文句があるが、公式スペック表には 2 つ目のチップの型番は載っていない | 文書 |
| C1002 | メモリとストレージ | 2 GB / 32 GB | 文書 |
| C1003 | 表示技術 | 両眼 Micro LED と回折導波路 | 文書 |
| C1004 | 表示色 | モノクロ緑、単一の緑色発光チャネルであり、フルカラーではない | 文書 |
| C1005 | パネル解像度 | 480 × 400、製品スペックとしての数値。ランタイムキャンバス C5002 の数値と併存する。未明事項の第 1 項を参照 | 文書 |
| C1006 | 視野角 | 30° | 文書 |
| C1007 | 輝度 | 1500 nits | 文書 |
| C1008 | カメラハードウェア | 12 MP、写真 3024 × 4032、F2.25。センサーの型番とカメラの視野角は公式には公表されていない | 文書 |
| C1009 | マイクハードウェア | 4 マイクアレイ | 文書 |
| C1010 | スピーカー | デュアルリニア指向性ハイファイスピーカー | 文書 |
| C1011 | バッテリーと充電 | 210 mAh。駆動時間は公式でも複数の数値があり、未明事項の第 4 項を参照。磁気吸着充電、20 分で 80% まで充電、充電ケースで約 10 回満充電できる | 文書 |
| C1012 | ワイヤレス接続 | Wi-Fi 6、Bluetooth 5.3 | 文書 |
| C1013 | 本体パラメータ | 49 g、IPX4。テンプル長 155.5 mm、ヒンジ間隔 146.3 mm、フレームは TR90 とチタン合金ヒンジ | 文書 |
| C1014 | 度付きレンズ | 度数 +15 から −15 まで対応、公式の度付きレンズサービスと磁気吸着式の度付きフレーム | 文書 |
| C1015 | カメラインジケータランプ | 対応し、撮影時に表示される | 文書 |
| C1016 | オペレーティングシステム | 名称とバージョンは公式には公表されていない。ランタイムは Ink コンテナであることが分かっている。C5001 を参照 | 文書 |
| C1017 | 製品レベルの本体機能 | リアルタイム翻訳 89 言語、AI アシスタント、通知、ナビゲーション、テレプロンプター、メモ、会議の文字起こしなどは、メガネのシステムと公式 App の機能であり、Agent が呼び出せる API ではない。Agent が使えるのは本表に登録されたプリミティブだけである | 文書 |

### 3.2 カメラと画像

根拠：`skill: references/apis/media.md`、`skill: references/apis/wx.md`。権限 C7002 が必要。

| 番号 | プリミティブ | 結論 | 実測 |
|---|---|---|---|
| C2001 | ビデオストリーム getUserMedia | MediaStream を取得できる。制約は facingMode、width、height、frameRate、deviceId をサポートし、最終値は track の getSettings で読み取る | 文書 |
| C2002 | 撮影 ImageCapture.takePhoto | エンコード済みの Blob を返す。モードは 3 種：wide はバーコードスキャン用の広角、telephoto は遠くの文字を読む用、default は通常撮影。ほかに quality、enableSystemPreview のオプションがある | 文書 |
| C2003 | 撮影の出力サイズ | wide 2016 × 2688、telephoto 2016 × 1512、default 3024 × 4032。Blob 自体には幅と高さが含まれないため、createImageBitmap でデコードする必要がある | 文書 |
| C2004 | フレーム取得 ImageCapture.grabFrame | 未エンコードの ImageBitmap 画素フレームを返す。使用後は close が必要 | 文書 |
| C2005 | wx 撮影 CameraContext.takePhoto | ArrayBuffer と mimeType を返す。モード選択のパラメータはなく、モードは C2002 による。インタラクションゲートの呼び出し地点でトリガーしなければならない | 文書 |
| C2006 | 録画 MediaRecorder | オーディオ・ビデオストリームを録画する。ビデオの mime は isTypeSupported での照会が基準で、判明しているのは video/webm;codecs=vp8,opus と video/mp4 | 文書 |
| C2007 | バーコード検出 BarcodeDetector | 対応するコード形式はまず getSupportedFormats で調べる。detect の入力は ImageData、エンコード済み画像 Blob、ImageBitmap に限られ、format、rawValue、boundingBox、cornerPoints を返す | 文書 |
| C2008 | OCR インターフェース | 存在しない。文字を読む道筋は telephoto 撮影と大規模モデルへの画像入力である。C3016 を参照 | 文書 |
| C2009 | 持続フレームストリーム | 文書には持続的にフレームを取得する際の頻度の上限とバックグラウンドでの挙動が示されていない。getUserMedia ストリームと grabFrame の持続的な可用性はプローブで検証する。第 4 節を参照 | 検証待ち |
| C2010 | 文字と顔の検出 | TextDetector、FaceDetector は存在せず、公式リストにこの条目は載っていない | 文書 |

### 3.3 オーディオ、音声、大規模モデル

根拠：`skill: references/apis/media.md`、`skill: references/apis/ai.md`。録音には権限 C7003 が必要。

| 番号 | プリミティブ | 結論 | 実測 |
|---|---|---|---|
| C3001 | 録音ソース captureSource | microphone（マイク）または system-audio（システム音声の内部録音）。system-audio は echoCancellation や microphoneMode と組み合わせられず、組み合わせると OverconstrainedError になる。システム音声はマイクへ自動的にはフォールバックしない | 文書 |
| C3002 | マイクモード microphoneMode | 4 種：wearer（着用者優先）、far-field（遠距離）、near-field（近距離）、omnidirectional（全方向）。getUserMedia の収集ストリームにだけ有効で、デバイスの対応は保証されず、非対応なら OverconstrainedError を返す。実際に効いている値は getSettings で読み取る | 文書 |
| C3003 | マイクモードとホスト認識の関係 | モードは自分で収集したストリームにだけ作用し、ホストの音声認識には作用しない。ホスト認識はホストのマイクを使い、モード設定とは無関係である | 文書 |
| C3004 | 録音エンコード MediaRecorder | オーディオは audio/wav、audio/ogg;codecs=opus に対応する | 文書 |
| C3005 | wx 録音 RecorderManager | start、pause、resume、stop とフレームコールバック。既定のマイクを使い、ソースとモードを選ぶパラメータはない。モードを選びたい場合は C3001、C3002 を使う | 文書 |
| C3006 | 音声合成 speechSynthesis.speak | 直接合成して再生し、ランタイムの統一プレーヤーのキューを通る。mode は enqueue（既定）または immediate | 文書 |
| C3007 | 音声合成 speechSynthesis.synthesize | 生成だけを行い再生せず、abort 可能なタスクを返す。オプションには字幕の粒度 none、sentence、word、オーディオ形式 pcm、mp3、ogg_opus、サンプリングレート、チャネル数、ビットレートが含まれ、SpeechAudioPlayer と組み合わせて独立に再生する | 文書 |
| C3008 | 合成音声の音色 | 固定の音色 ID が計 11 個：female-tianmei、English_radiant_girl、English_expressive_narrator、male-qn-qingse、male-qn-jingying、female-yujie、Chinese (Mandarin)_News_Anchor、Chinese (Mandarin)_Radio_Host、clever_boy、lovely_girl、English_Trustworthy_Man。getVoices はない | 文書 |
| C3009 | 合成の制御面 | utterance の lang 属性は効かず、生成言語は変わらない。cancel、pause、resume はない。pitch、rate、volume の既定値はいずれも 1 | 文書 |
| C3010 | wx 読み上げ wx.speech.playTTS | 1 文の読み上げで、リクエスト ID の文字列を返し、失敗すると空文字列を返す | 文書 |
| C3011 | 音声認識 SpeechRecognition | ホストのマイクで認識する。属性は lang、continuous、interimResults、maxAlternatives。start はビューがインタラクティブな状態を保っていることを要求し、そうでなければ InvalidStateError になる。lang が空のときはホストが既定言語を選ぶ | 文書 |
| C3012 | 音声認識 SpeechRecognitionSession | 外部オーディオストリームを認識し、セッション自体はマイクを開かない。ホットワード phrases と boost、セグメンテーション auto、vad、semantic、updateContext による動的コンテキストに対応する。使用前に getCapabilities でホストの実際の能力を調べる | 文書 |
| C3013 | 認識エラーのカテゴリ | error イベントのエラーカテゴリの値について、公式は列挙表を示していない。カテゴリ別にエラー処理を分けるのは未検証の仮定であり、依存してはならない | 文書 |
| C3014 | 大規模モデルの可用性 LanguageModel.availability | available または unavailable だけを返し、提供元、モデルのリスト、エンドポイントは公開されない | 文書 |
| C3015 | 大規模モデルセッション LanguageModel.create | 基盤はホストの OpenAI 互換 chat-completions ストリーミングチャネルである。モデルの解決順序は明示した model、ホストの defaultModel の順。system は initialPrompts の先頭の 1 件にしか置けない | 文書 |
| C3016 | 大規模モデルのマルチモーダル入力 | user メッセージの content 配列は text と image_url に対応し、画像は data: URL でもよい。構造化された content は user ロールに限られる | 文書 |
| C3017 | 大規模モデルのツール呼び出し | tools は提供元のリクエストボディへ転送される。呼び出しはセッションの toolcall イベントで返ってきて、callId、functionName、arguments を含む。自動では実行されず、構造化された往復プロトコルの保証はない | 文書 |
| C3018 | 大規模モデルのリクエスト prompt と promptStreaming | ストリーミングはポーリング式の read であり、WHATWG Stream でも async iterator でもない。同一セッションでは進行中のリクエストは同時に 1 つだけ。destroy 後は使えない | 文書 |
| C3019 | オーディオ再生 AudioPlayer | 汎用プレーヤーで、ローカルパッケージ内のファイルまたはネットワーク URL を扱う。pcm、ogg_opus のストリーミング append 再生と字幕テキストトラックに対応する | 文書 |
| C3020 | 効果音 Sound | ローカルの効果音の短い再生で、ローカルファイルだけを受け付け、http と https の URL は拒否する | 文書 |
| C3021 | Web Audio | AudioContext と createBuffer、Oscillator、Gain、BiquadFilter、Analyser、MediaStreamSource、decodeAudioData などが使え、波形とスペクトラムの解析ができる | 文書 |

### 3.4 センサーと測位

根拠：`skill: references/apis/device.md`、`skill: references/apis/geo/geolocation.md`、公式 IMU ガイド。測位には権限 C7001 が必要。

| 番号 | プリミティブ | 結論 | 実測 |
|---|---|---|---|
| C4001 | 加速度計 Accelerometer | 3 軸加速度 x、y、z と timestamp。イベントは activate、reading、error。コンストラクタパラメータ frequency はホストへのベストエフォートのヒントにすぎない | 文書 |
| C4002 | ジャイロスコープ Gyroscope | 3 軸角速度 x、y、z と timestamp。イベントと frequency の意味は C4001 と同じ | 文書 |
| C4003 | 絶対方位 AbsoluteOrientationSensor | 絶対方位のクォータニオン quaternion [x, y, z, w] と timestamp。可用性はデバイスのハードウェア対応に依存する | 文書 |
| C4004 | サンプリングレートの保証 | 最高頻度と精度について公式に公表された数値はない。公式ガイドの例では 60 を使い、30 から 60 Hz で始めることを勧めている | 文書 |
| C4005 | その他のセンサーインターフェース | 地磁気、光、近接の各センサーには単独の API はなく、公式リストには現れていない | 文書 |
| C4006 | 頭部ジェスチャ onHeadGesture | Page の中で enableWorldAwareness を有効にする必要がある。公式の例にあるジェスチャ値は nod（うなずき）だけで、完全な列挙は公表されていない。未明事項の第 8 項を参照 | 文書 |
| C4007 | 頭部の安定イベント onOrientationStabilityChange | 同じくワールドアウェアネスの有効化が必要。event.stable が頭部の安定性の変化を表す | 文書 |
| C4008 | アイトラッキング | 存在しない。いわゆる視線は、頭部の向き C4003 と頭部の安定 C4007、うなずき C4006 で実現する | 文書 |
| C4009 | 測位 geolocation | getCurrentPosition と watchPosition があり、clearWatch で解放する。coords には latitude、longitude、accuracy（メートル）と、null になりうる altitude、altitudeAccuracy、heading、speed が含まれる。オプションは enableHighAccuracy（既定 false）、timeout、maximumAge。エラーコードは 1 が拒否、2 が利用不可、3 がタイムアウト | 文書 |
| C4010 | GPX GPXDocument | GPX ルートの解析、作成、エクスポート：setStartPoint、addWaypoint、appendTrackPoint、toString、toBlob。map と map-gpx コンポーネントと組み合わせて軌跡を表示する | 文書 |
| C4011 | Bluetooth BLE | セントラル側の役割：getAvailability、getDevices、requestDevice、scanDevices（Ink 独自）、GATT connect、readValue、writeValue、startNotifications。requestDevice、scanDevices、connect、startNotifications はビューがインタラクティブな状態であることを要求する | 文書 |
| C4012 | Bluetooth のペリフェラルとアドバタイズ | 存在せず、公式リストに peripheral 能力は載っていない | 文書 |

### 3.5 表示ランタイムとページ

根拠：`skill: references/framework.md`、`skill: references/apis/window.md`、`skill: references/apis/canvas.md`、`skill: references/events.md`、公式ランタイム環境ドキュメント。

| 番号 | プリミティブ | 結論 | 実測 |
|---|---|---|---|
| C5001 | ランタイム Ink | 論理層とビュー層は QuickJS と Skia で構築された独自コンテナ Ink の中で動く。ES2023、ESM | 文書 |
| C5002 | 基準キャンバス | フルスクリーン Page の基準キャンバスは 480 × 352。安全マージンは左右 16 px、上下 12 px で、有効なコンテンツ幅は 448 px | 文書 |
| C5003 | モノクロ緑の設計制約 | 基調色 #40ff5e、6 段階の輝度ステップ。黒は透明な背景と等しく、不透明な黒いパネルで現実を遮ることは期待できない。意味を色だけで担わせてはならず、アイコン、文字、線種を重ねる。本文の輝度は 72% 以上、装飾線は 24% 以下が推奨され、重要な情報は中央の快適な視野に置く | 文書 |
| C5004 | ビューポートサイズ | window.innerWidth、innerHeight は読み取り専用の論理ピクセル | 文書 |
| C5005 | Widget のサイズ | サイズファミリーは 1x1 が 239 × 140、1x2 が 480 × 140。メガネには Widget のグリッド位置が計 4 つある。family はサイズのカテゴリにすぎず、ルートノードをそのピクセル値に固定して書くことは禁止されている | 文書 |
| C5006 | 画面を開く window.open | app.json に宣言済みの Widget だけを開ける。target は _widget のみで、overlay の重ね表示に対応する。他の Page や外部 URL は開けない | 文書 |
| C5007 | インスタンスを閉じる window.close | ホストに現在の Agent インスタンスを閉じるよう要求する | 文書 |
| C5008 | Agent 間のジャンプ | 存在しない。公式リストに openAgent の類の条目はなく、wx.navigateTo は自 Agent 内のページに限られる。総則 R1 を参照 | 文書 |
| C5009 | ホスト設定ページを開くこと | 到達できない。そのような API はなく、「何々 の設定を開く」類のインテントは、ホストがアプリケーション自体を開くところまでしか実行しない。総則 R1 を参照 | 文書 |
| C5010 | プロジェクト構成 | app.json と app.js と AGENTS.md と pages。ページは .ink の単一ファイル、または .json、.wxml、.wxss、.js の 4 点セット。任意で widgets、workers、components、assets | 文書 |
| C5011 | 組み込みコンポーネント | 記述できるタグは計 37 個で、コンテナ、テキスト、フォーム、メディア、地図、キャンバス、チャートと、AI 生成 UI の a2ui を含む | 文書 |
| C5012 | Agent Worker | UI のないスクリプトで、open でトリガーされる。lifetime は instant または foreground で、background は予約されているが無効。タイマー、Promise、Crypto、Wasm、エンコーディングストリームがある。window、document、fetch、ルーティング、レンダリング、メディア収集はない | 文書 |
| C5013 | 言語とモジュール | TypeScript のエントリと WebAssembly モジュールに対応し、プロジェクトのパッケージングフローを通る | 文書 |
| C5014 | Canvas 2D | パス、矩形、measureText を含むテキスト、変換、グラデーション、パターン、drawImage は引数 3、5、9 個の 3 形式のみ。色の解析は #rrggbb、#rgb、rgb、rgba と少数の名前付き色のみ。出力は convertToBlob と createImageBlob を通り、canvas.toDataURL は存在しない | 文書 |
| C5015 | WXML テンプレート | template は未対応 | 文書 |
| C5016 | 会話フローカード | 既定では表示のみ。インタラクティブな画面にはフルスクリーン Page または Widget が必要 | 文書 |
| C5017 | デバイス情報 navigator | id は Agent とデバイスに結びついた不透明な ID で、認証情報として扱ってはならない。userAgent と versions.ink、versions.skia がバージョン文字列を与える。language、languages、region は空の場合がある。onLine と connection がオンライン状態と接続の推定値を与える。renderingEnabled は現在のインスタンスがレンダリングできるかどうかを表す | 文書 |
| C5018 | バッテリー getBattery | Promise を返す BatteryManager。ホストにバッテリー能力がない場合は Promise が拒否される。詳細の文書は不完全で、未明事項の第 9 項を参照 | 文書 |
| C5019 | シリアル番号とトークン | getDeviceSerialNumber と requestDeviceToken はシステムレベルの Agent だけが使え、通常の Agent では空文字列が返るか、依存してはならない | 文書 |
| C5020 | グローバルなエンコードツール | window.atob、btoa とグローバルの createImageBlob が使え、createImageBlob は PNG、JPEG のエンコードを行う | 文書 |

### 3.6 ストレージ、ファイル、ネットワーク

根拠：`skill: references/apis/web.md`、`skill: references/apis/wx.md`、公式ネットワークガイド。

| 番号 | プリミティブ | 結論 | 実測 |
|---|---|---|---|
| C6001 | ローカルストレージ localStorage | 現在の Agent に隔離された文字列 KV：getItem、setItem、removeItem、clear | 文書 |
| C6002 | wx ストレージ | setStorage、getStorage、removeStorage、clearStorage と Sync の同期版。データは JSON でシリアライズされる | 文書 |
| C6003 | StorageManager navigator.storage | 文書には「永続ファイルストレージへの入口」の 1 文だけがあり、メソッドの詳細は示されていない。未明事項の第 10 項を参照 | 文書 |
| C6004 | 汎用ファイルシステム | 存在しない。リソースはすべてプロジェクト内パスから解決され、任意パスの読み取り、書き込み、ディレクトリ一覧のインターフェースはない | 文書 |
| C6005 | FileReader | 存在せず、実機では必ず FileReader is not defined が投げられる。Blob から dataURL への変換は blob.arrayBuffer と分割した btoa で行う。関連エラーコード E2005 | 実機検証済み |
| C6006 | 存在しないブラウザ API | 以下はいずれも Ink ランタイムには存在せず、コードに書けば誤りになる：sessionStorage、XMLHttpRequest、URL.createObjectURL、DOMParser、structuredClone、queueMicrotask、Notification、クリップボード API、IntersectionObserver、MutationObserver、ServiceWorker、new Worker、OffscreenCanvas、getDisplayMedia、applyConstraints、getVoices、navigator.permissions | 文書 |
| C6007 | fetch と Web の機構 | fetch、Headers、body のストリーミング読み取りを含む Response、WebSocket、File、FormData、URL と URLSearchParams、Streams 一式が使える | 文書 |
| C6008 | wx ネットワーク | wx.request のタイムアウトの解決順序は options.timeout、app.json の設定、既定 60000 ms の順。wx.createSocket、connectSocket、SSE 用の wx.createEventSource | 文書 |
| C6009 | Web Crypto | randomUUID、getRandomValues（上限 65536 バイト）が使える。subtle は SHA-1、256、384、512 のダイジェストと HMAC のみ。暗号化、復号、RSA、ECDSA、JWK は未対応 | 文書 |
| C6010 | スマートフォン経由のプロキシ接続 | メガネが Wi-Fi に接続していないときでも、Bluetooth でスマートフォンの App とつながっていれば、fetch と wx.request は自動的にスマートフォンのリンク経由で転送されてインターネットに出る。開発者には透過的である | 文書 |
| C6011 | HTTPS とドメインのホワイトリスト | 本番環境でのネットワークリクエストは HTTPS でなければならない。ストアへ公開する前に、リクエスト先ドメインを開発者バックエンドでホワイトリストに登録する必要がある | 文書 |
| C6012 | LAN への直接接続 | 未対応。公式ガイドでは開発中とされ、ドキュメント目次には unsupported と記されている | 文書 |
| C6013 | データのプリフェッチ | prefetch は未対応 | 文書 |
| C6014 | ソースマップによるデバッグ | 未対応 | 文書 |

### 3.7 権限

根拠：公式 framework ドキュメント app-json.md の権限表。2026-10-29 の全量監査で訂正した。計 7 個で、名称は大文字小文字を区別し、認識されない名称はいかなる能力も付与しない。あわせて C7008 の上流側の不整合に注意する。

| 番号 | プリミティブ | 結論 | 実測 |
|---|---|---|---|
| C7001 | 権限 GEOLOCATION | 現在位置の取得と位置変化の監視。C4009 を参照 | 文書 |
| C7002 | 権限 CAMERA | カメラへのアクセス、画像や動画の撮影。3.2 節を参照 | 文書 |
| C7003 | 権限 RECORD_AUDIO | マイクへのアクセスとオーディオの収集。ASR のマイク開始もこれに依拠し、独立した ASR 権限はない。旧 SPEECH_RECOGNITION は Ink 0.19 で削除された | 文書 |
| C7004 | 権限 READ_MEDIA_IMAGES | システムのメディアライブラリ内の画像を列挙し読み取る | 文書 |
| C7005 | 権限 CREATE_MEDIA_IMAGES | システムのメディアライブラリへ画像を新規追加する。既存リソースの変更と上書きは含まない | 文書 |
| C7006 | 権限 READ_MEDIA_AUDIO | システムのメディアライブラリ内のオーディオを列挙し読み取る | 文書 |
| C7007 | 権限 CREATE_MEDIA_AUDIO | システムのメディアライブラリへオーディオを新規追加する。既存リソースの変更と上書きは含まない | 文書 |
| C7008 | 権限リストの文書上の口径 | aiui-dev skill の framework リファレンスには今も最初の 3 つの権限しか載っておらず、上流ドキュメント内部の不整合である。framework の正式ドキュメントの 7 名を基準とする | 文書 |

### 3.8 インタラクションとホスト

根拠：`skill: references/events.md`、Hi Rokid App 内蔵の操作ガイド（ジェスチャ部分。実機の挙動はこちらを基準とする）。

| 番号 | プリミティブ | 結論 | 実測 |
|---|---|---|---|
| C8001 | ウェイクアップ onVoiceWakeup | 音声でもタッチでもトリガーできる。event.keyword の判明している値：乐奇、Hi Rokid、clickAiAssist（タッチによるウェイクアップ）。既定では keyword でフィルタしない。event.preventDefault でホストの既定動作を引き継げる | 文書 |
| C8002 | キーイベント | Page の onKeyDown、onKeyUp は event.code で振り分けられる：Enter が確定、Backspace が戻る、ArrowUp と ArrowDown がスクロール、GlobalHook がテンプルタッチ専用のデバイス信号。ホストの既定動作は onKeyUp の後に発動する | 文書 |
| C8003 | 1 本指のシングルタップ | 確定、Enter に対応 | 文書 |
| C8004 | 1 本指のダブルタップ | 戻る、Backspace に対応。戻るページがない場合は Agent を閉じるよう要求する | 文書 |
| C8005 | 1 本指のスワイプ | スクロール、ArrowUp、ArrowDown に対応。スクロール方向は App で変更できる | 文書 |
| C8006 | 1 本指の長押し | アシスタントを起こす。App でメガネの AI アシスタントかスマートフォンのアシスタントかを選べる | 文書 |
| C8007 | 2 本指のダブルタップ | 画面消灯 | 文書 |
| C8008 | 2 本指の前後スワイプ | 音量の増減。既定ではこの割り当てで、App で変更できる | 文書 |
| C8009 | 2 本指長押し AI クイックコマンド | 選んだトリガー対象へ固定の指令を 1 件送る。テキストの上限は 500 字。トリガー対象には特定のカスタム Agent やデバッグ Agent を選ぶことができ、すなわち ASR を介さず、固定テキストを決定的に指定した Agent へ届ける | 実機検証済み |
| C8010 | シーン別ジェスチャ | 音楽シーン：シングルタップで再生または一時停止、前後スワイプで曲の切り替え。通話シーン：着信時のダブルタップで拒否、通話中のシングルタップでミュートの切り替え、ダブルタップで通話終了 | 文書 |
| C8011 | クリックだけをバインドしたボタン | bindtap だけをバインドしたボタンは、メガネ上ではジェスチャでトリガーできない。ページはキーと動作の対応付けを自前で行わなければならず、ボタンのクリックだけに頼ることはできない | 実機検証済み |
| C8012 | 音声ウェイクアップの失敗する層 | 固定文型によるウェイクアップの失敗は、音声認識の転写の層で起きるもので、テキストが正しく転写された後のマッチングの層ではない。Agent 名を短くしたり整えたりしても転写を緩和できるだけで、回避はできない。決定的な入口は C8009 を参照 | 実機検証済み |
| C8013 | スマートフォンのコンパニオン App の役割 | ネットワークプロキシは C6010 を参照。そのほか、デバイス管理と設定、メディア管理、AI 機能の入口、メガネ用リソースパッケージの配布を担う | 文書 |

### 3.9 配布と審査提出

根拠：公式の公開ドキュメント publish.md、AIX ドキュメント。インポートの挙動はメンテナが 2026-10-24 に Global AIUI Studio で実測したものである。

| 番号 | プリミティブ | 結論 | 実測 |
|---|---|---|---|
| C9001 | 配布形式 AIX | AI eXecutable で、Open Agent Format に準拠し、コード、構成、静的リソースを自己完結で含む。パッケージング時に一意な UUID の VERSION ファイルが自動生成され、バージョン検証に使われる | 文書 |
| C9002 | パッケージサイズの上限 | 公式には数値が公表されていない | 文書 |
| C9003 | パッケージング除外 .aixignore | .agents、.aix、artifacts、*.aix、skills-lock.json、node_modules を除外しなければならず、除外しないと開発用ファイルがパッケージに入り、実測では 2.3 KB から 107 KB へ膨らみうる | ビルド検証済み |
| C9004 | Studio のインポート挙動 | インポートダイアログには URL 入力欄が 1 つだけある。/tree/ より後ろの内容は全体が 1 つの ref として扱われ、サブディレクトリのアドレスではインポートに失敗する。リポジトリのルートのアドレスでインポートすると空のコードツリーが得られる。1 セグメントのブランチ名で、ブランチのルートに 1 つの Agent の全ファイルを置くと、完全なプロジェクトとしてインポートに成功する | Studio 検証済み |
| C9005 | 審査提出のレッドライン | 名称は必須で 20 文字以内、他者と重複してはならず、テストや test、beta などの語と最上級の表現を含んではならない。アイコンは必須で既定アイコンは使えない。機能紹介は 500 文字以内。オープニングメッセージは必須で 300 字以内が推奨される。プレビュー素材は 3 から 5 ファイルで、少なくとも画像 1 点と動画 1 点を含み、動画は 60 秒以内。各権限について用途を 1 件ずつ明記する | 文書 |
| C9006 | 審査提出の申告チェック | Studio の審査提出には別に申告系のチェック項目がある：ネットワーク、カメラ、マイク、スピーカー、Rokid アカウント情報など。3.7 節のリスト権限とは別の体系である | 文書 |
| C9007 | 公開フロー | ビルド、Web シミュレーション、AIX パッケージングとクラウドへのアップロード、実機デバッグ、審査提出資料の整備、審査への提出 | 文書 |
| C9008 | バージョンと ID の生成 | バージョン番号と Agent ID はいずれもシステムが生成し、開発者は編集できない | 文書 |

## 4. 未検証プローブ

プローブは条目を検証するために作られた検証装置である。本節にはプローブと、それが答えるべき条目番号だけを登録する。プローブのデータがそろったら、結論を対応する条目に書き戻してその検証状態を更新し、本節の該当行は削除する。

| プローブ | 検証する条目 | 状態 |
|---|---|---|
| 能力ベンチマーク Agent、23 項目で基盤を 1 件ずつ測る | C2002、C2004、C3002、C3011、C4001 から C4007、C5002 など | 構築済み、実機での再検証は未完了 |
| 映像・音声キャプチャシリーズ 10 Agent、それぞれ 1 件の映像・音声境界を担う | C2002、C2004、C2006、C2007、C3001、C3002、C3021 | 構築済み、ハードウェアチェーンは実機データの戻り待ち |
| ストップモーション Agent とログ返送クライアント | C6005 の再検証；エラーログを外部チャネルで返送することの実現可能性 | 構築済み、実機で 1 ラウンド回すのを待っている |
| なぞり書きプローブ、結印と手話の 2 件 | C3016 画像入力による静止画判定の可用性と命中率 | 構築済み、正式版への収録は実機データで決める |
| 連続ビデオストリームプローブ | C2009 | 企画済み、未実行 |
| 認識エラーカテゴリの収集 | C3013 | 実機で各種類のエラーを起こした後に原文と照合する |

## 5. 未明点と矛盾

以下は条目ではない。公式ソース自体の食い違い、あるいは公式が示していない点であり、関連する条目の下にぶら下げてある。公式の見解か検証で明らかになったら、条目に取り込むか削除する。

1. 表示解像度の二重の数値：製品スペック 480 × 400（C1005）とランタイムキャンバス 480 × 352（C5002）が併存し、両者の関係は公式には説明されていない。
2. FOV についての第三者の説 23° と、表示解像度についての第三者の説 640 × 480 は、いずれも公式には裏付けられておらず、C1006、C1005 を基準とする。
3. 駆動時間の数値が複数ある：同じ製品ページで、FAQ は日常使用で 8 から 10 時間、比較表は混合使用で 6 時間、充電ケース併用で 30 時間としており、統一した測定条件がない（C1011）。
4. 2 つ目のチップの型番は公式には裏付けられていない（C1001）。
5. カメラセンサーの型番と視野角は公式には公表されていない（C1008）。
6. IMU の軸数、型番、サンプリングレートの上限と精度は公式には公表されていない（C4001 から C4004）。
7. 頭部ジェスチャの完全な列挙は公式には公表されていない（C4006）。
8. getBattery の詳細な文書が不完全である：navigator リファレンスではバッテリーのメソッドは device リファレンスを見よとしているが、device リファレンスにその章がない（C5018）。
9. StorageManager のメソッドの詳細は公式には示されていない（C6003）。
10. デバイス世代の差異：Rokid Glasses 2 と第 1 世代のフルカラーメガネのキーマッピングは、公式 events リファレンスの中で未検証と注記されており、本表 3.8 節のマッピングを流用してはならない。
11. 公式ドキュメントの二重化：open.rokid.com/aiui が現行版、js.rokid.com が旧版であり、両サイトの差異はページ単位では照合していない。本表は公式リポジトリの documentation と aiui-dev skill を基準とする。
12. パッケージサイズの上限、ドメインのホワイトリスト登録の入口、審査にかかる時間は、公式には詳しく示されていない（C9002、C6011）。

## 6. 公式ソース一覧

**製品とプラットフォーム**

- Rokid Glasses 公式グローバル製品ページ（スペックの主ソース）：https://global.rokid.com/products/b-h-rokid-glasses-with-display
- Rokid 英国公式サイト AI 製品ライン（スペックの相互裏付け）：https://gb.rokid.com/collections/rokid-ai-lineup
- 公式 Academy チュートリアル『3.6 Glasses AIUI』：https://global.rokid.com/de/blogs/academy-glasses/glasses-3-6-aiui

**公式ドキュメントサイト**

- AIUI ドキュメント（現行版）：https://open.rokid.com/aiui
- AIUI ドキュメント（旧版）：https://js.rokid.com/AIUI/guide/quickstart/ai-dev

**公式 GitHub リポジトリ yodaos-project/AIUI**

- リポジトリのトップ：https://github.com/yodaos-project/AIUI
- aiui-dev skill（API 契約の主ソース）：https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev
- 審査提出と公開：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md
- AIX とは：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/aix.md
- ランタイム環境：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
- IMU ガイド：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md
- ネットワーク利用の説明：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md
- ドキュメント目次（lan、prefetch、sourcemap などの unsupported 表記を含む）：https://github.com/yodaos-project/AIUI/blob/main/documentation/toc.json

## 7. 変更履歴

### v2.0.0 2026-10-29

構造をアトミックレジストリへ再構成した。全文を 9 つの段に分けて 123 件の番号付き条目とし、各条目にプリミティブ、結論、検証状態を含めた。番号とガバナンス、総則、未検証プローブの 3 節を新設した。旧第 5 節の矛盾と未明点は、条目番号を付けて保持した。シナリオ類の問いは今後は個別に収録せず、条目と総則から導くことに統一した。

### v1.1.0 2026-10-29

第 4 節にプラットフォームの位置づけに関する公式見解「Agent は本質的にクローズドループを完結させる」を加え、4.3 の表に Agent 間のジャンプとホスト設定ページを開くことの 2 件を新規に追加した。全文の見出しから括弧書きの注記を取り除き、注記の内容は本文へ移した。はじめにと本変更履歴を新設した。

### v1.0.0 2026-10-29

リポジトリへの公開版。本アーカイブは 2026-10-24 に作成し、公式製品ページ、公式ドキュメントサイト、公式リポジトリの aiui-dev リファレンスをまとめたものである。リポジトリに入れるにあたり汎用化の処理を行い、開発者内部の作業方針と個人の使用痕跡を取り除いた。能力に関する事実は変えていない。
