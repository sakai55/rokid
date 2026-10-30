# Rokid Glasses 能力レジストリ

[中文](CAPABILITIES.md) | [English](CAPABILITIES.en.md) | 日本語

本書は中文版 v2.2.0（2026-10-30）に対応する日本語版である。内容に食い違いがある場合は中文版を正とする。

> 作成：2026-10-24／現行バージョン v2.1.0（2026-10-30）
> 資料の方針：**出典は Rokid 公式に限る**（公式製品ページ、公式ドキュメントサイト、公式 GitHub リポジトリ `yodaos-project/AIUI` および同梱の `aiui-dev` スキルリファレンス）。これに加えて、メンテナ自身による実機・ビルドでの確認結果があり、確認の裏付けがある結論はエントリ内に明記する。API 契約の一次資料は公式リポジトリの `skills/aiui-dev` で、根拠は以下 `skill: references/…` と記す。

## はじめに

本レジストリは Rokid 公式の文書ではない。Rokid AIUI の開発者であるメンテナが維持しているもので、Rokid Glasses のプラットフォーム能力を最小単位に分解したエントリ集である。各エントリはプリミティブ1件のみを扱い、安定した ID、結論、公式の根拠、検証ステータスを持つ。Agent を設計する際は、まず使いたいプリミティブがここにあるか、あるとすれば制約は何かを確認すること。

登録するのはプリミティブだけで、アプリケーションのシナリオは登録しない。シナリオはプリミティブの組み合わせであり、組み合わせは無数にある。1件ずつ収録していけば際限のない Q&A 集になる。シナリオに関する疑問への答え方はいつも同じで、シナリオを必要なプリミティブに分解し、本書で1件ずつ引く。プリミティブが揃えば実現でき、欠けていれば実現できない。その問い専用のエントリを増やす必要はない。公式 API リファレンス自体が閉じた一覧であり、一覧にない API は存在しない。これが本書の大半の判定の土台である。

運用ルールはエラーコード表 `ERROR-CODES.md` と同じである。エントリは各区分の末尾にのみ追加し、ID は再利用しない。結論が覆ったエントリは結論を書き換えて変更履歴に残し、ID は消さない。結論が変わればバージョンを上げ、旧版は `base/capabilities/` にアーカイブして索引を付ける。正本は中文版で、英日版は翻訳である。食い違いがある場合は中文版を正とする。

## 1. ID と運用ルール

ID は `C2003` の形式で、文字 C に4桁の数字が続き、千の位が区分を表す。区分内では連番を振る。

| 区分 | 領域 |
|---|---|
| C1xxx | ハードウェアと表示 |
| C2xxx | カメラと画像 |
| C3xxx | オーディオ・音声・大規模モデル |
| C4xxx | センサーと測位 |
| C5xxx | 表示ランタイムとページ |
| C6xxx | ストレージ・ファイル・ネットワーク |
| C7xxx | 権限 |
| C8xxx | インタラクションとホスト |
| C9xxx | 配布と審査提出 |

検証ステータスは次の4値のみを使う。**文書のみ**：公式ドキュメントの根拠だけがあり、実機ではまだ確認していない。**実機確認済み**：実機で得た結果や挙動の根拠がある。**ビルド確認済み／Studio確認済み**：パッケージング工程または Studio のフローの中で確認した。**未確認**：検証用プローブはあるがデータがまだ戻ってきていない。プローブは第4節に置く。バージョンの付け方は、エントリの追加または結論の変更で MINOR、構造やルールの変更で MAJOR、文言の修正のみで PATCH を上げる。

## 2. 総則

総則はエントリではない。シナリオへの答えを導く際に、エントリと同等に適用するルールである。

- **R1 自己完結**（公式見解、2026-10-29）：Agent は単体で完結する。1つの Agent は、自ら宣言した権限と呼び出し可能な API によって、物事の入口から結果までを自分の内部でやり遂げる。完結の外側にあるホストの能力、すなわちシステム設定、他の Agent、ホストの設定は、Agent には委譲されない。出典：公式の回答。メンテナが取り次いだ。
- **R2 一覧が境界である**：公式 API リファレンスは閉じた一覧である。一覧に見つからない API、パラメータ、列挙値は、すべて存在しないものとして扱う。ブラウザや WeChat ミニプログラムの慣例で補って仮定してはならない。
- **R3 インタラクションゲート**：取得系・接続系の呼び出し（撮影、録音、ASR の開始、BLE 接続など）は、対象のビューがインタラクティブな状態にあることを前提とし、通常はユーザー操作をトリガにする必要がある。インタラクティブでない状態で呼ぶと失敗する。リソースは使い終えたら解放すること。マイクとカメラのトラックは stop、BLE のスキャンと接続は切断、watchPosition は clearWatch、AudioContext は close する。
- **R4 宣言は許可ではない**：app.json に権限を書くのは宣言にすぎず、システムは実際の呼び出し時点でなお拒否できる。コード側は拒否されるケースを処理しなければならない。
- **R5 シミュレータは実機の代わりにならない**：Web シミュレータではセンサー値がモックであることが多く、性能と発熱も実機とは異なる。検証ステータスが「文書のみ」のエントリは、結論は実機での再確認をもって確定とする。

## 3. エントリ

### 3.1 ハードウェアと表示

根拠：公式グローバル製品ページ https://global.rokid.com/products/b-h-rokid-glasses-with-display 。英国公式サイトの同スペックと相互に裏付ける。

| ID | プリミティブ | 結論 | 検証 |
|---|---|---|---|
| C1001 | メインチップ | Snapdragon AR1。製品ページには別途「デュアルチップ」のうたい文句があるが、公式スペック表に第2チップの型番は載っていない | 文書のみ |
| C1002 | メモリとストレージ | 2 GB / 32 GB | 文書のみ |
| C1003 | 表示方式 | 両眼 Micro LED と回折型導波路 | 文書のみ |
| C1004 | 表示色 | 単色グリーン。発光チャネルは緑1色のみで、フルカラーではない | 文書のみ |
| C1005 | パネル解像度 | 480 × 400。製品スペックとしての口径であり、ランタイムキャンバス C5002 の口径と併存する。未確認事項の第1項を参照 | 文書のみ |
| C1006 | 視野角 | 30° | 文書のみ |
| C1007 | 輝度 | 1500 nits | 文書のみ |
| C1008 | カメラ | 12 MP、静止画 3024 × 4032、F2.25。センサの型番とカメラの視野角は公式に公表されていない | 文書のみ |
| C1009 | マイク | 4マイクアレイ | 文書のみ |
| C1010 | スピーカー | デュアルリニア指向性 Hi-Fi スピーカー | 文書のみ |
| C1011 | バッテリーと充電 | 210 mAh。公称の駆動時間は公式でも口径が複数あり、未確認事項の第3項を参照。マグネット吸着充電で、20分で80%まで充電でき、充電ケースで約10回フル充電できる | 文書のみ |
| C1012 | 無線接続 | Wi-Fi 6、Bluetooth 5.3 | 文書のみ |
| C1013 | 本体仕様 | 49 g、IPX4。テンプル長 155.5 mm、ヒンジ間隔 146.3 mm。フレームは TR90、ヒンジはチタン合金 | 文書のみ |
| C1014 | 度付き対応 | 度数 +15 から −15 まで対応。公式の度付きレンズサービスとマグネット式の度付きフレームがある | 文書のみ |
| C1015 | 撮影インジケータ | 対応する。撮影時に点灯する | 文書のみ |
| C1016 | OS | 名称とバージョンは公式に公表されていない。ランタイムが Ink コンテナであることは分かっている。C5001 を参照 | 文書のみ |
| C1017 | 製品レベルの本体機能 | リアルタイム翻訳（89言語）、AI アシスタント、通知、ナビゲーション、テレプロンプター、メモ、会議の文字起こしなどは、グラスのシステムと公式アプリの機能であり、Agent から呼び出せる API ではない。Agent が使えるのは本書に登録されたプリミティブのみである | 文書のみ |

### 3.2 カメラと画像

根拠：`skill: references/apis/media.md`、`skill: references/apis/wx.md`。権限 C7002 が必要。

| ID | プリミティブ | 結論 | 検証 |
|---|---|---|---|
| C2001 | 映像ストリーム getUserMedia | MediaStream を取得できる。制約として facingMode、width、height、frameRate、deviceId を指定でき、実際に適用された値はトラックの getSettings で読み取る | 文書のみ |
| C2002 | 静止画撮影 ImageCapture.takePhoto | エンコード済みの Blob を返す。モードは3種で、wide はバーコード読み取り向けの広角、telephoto は遠方の文字を読むため、default は通常撮影。ほかに quality、enableSystemPreview のオプションがある | 文書のみ |
| C2003 | 撮影の出力サイズ | wide 2016 × 2688、telephoto 2016 × 1512、default 3024 × 4032。Blob 自体には寸法が含まれないため、寸法を得るには createImageBitmap でデコードする必要がある | 文書のみ |
| C2004 | フレーム取得 ImageCapture.grabFrame | 未エンコードの ImageBitmap ピクセルフレームを返す。使用後は close が必要 | 文書のみ |
| C2005 | wx 撮影 CameraContext.takePhoto | ArrayBuffer と mimeType を返す。モード選択のパラメータはなく、モードは C2002 に従う。インタラクションゲートを満たす地点で発火させなければならない | 文書のみ |
| C2006 | 録画 MediaRecorder | 音声・映像ストリームを録画できる。映像の MIME タイプは isTypeSupported での照会が原則で、判明しているのは video/webm;codecs=vp8,opus と video/mp4 | 文書のみ |
| C2007 | バーコード検出 BarcodeDetector | 対応フォーマットはまず getSupportedFormats で確認する。detect の入力は ImageData、エンコード済み画像 Blob、ImageBitmap のいずれかに限られ、format、rawValue、boundingBox、cornerPoints を返す | 文書のみ |
| C2008 | OCR API | 存在しない。文字を読む手段は telephoto 撮影と、大規模モデルへの画像入力である。C3016 を参照 | 文書のみ |
| C2009 | 連続フレーム取得 | 連続取得時の頻度の上限とバックグラウンド時の挙動は、ドキュメントに示されていない。getUserMedia ストリームと grabFrame を継続利用できるかはプローブで検証する。第4節を参照 | 未確認 |
| C2010 | テキスト・顔検出 | TextDetector、FaceDetector は存在しない。公式一覧にこの項目はない | 文書のみ |

### 3.3 オーディオ・音声・大規模モデル

根拠：`skill: references/apis/media.md`、`skill: references/apis/ai.md`。録音には権限 C7003 が必要。

| ID | プリミティブ | 結論 | 検証 |
|---|---|---|---|
| C3001 | 録音ソース captureSource | microphone（マイク）または system-audio（システム音声の内部収録）。system-audio は echoCancellation や microphoneMode と組み合わせることができず、組み合わせると OverconstrainedError になる。システム音声からマイクへの自動フォールバックはない | 文書のみ |
| C3002 | マイクモード microphoneMode | 4種：wearer（装着者優先）、far-field（遠距離）、near-field（近距離）、omnidirectional（無指向性）。効くのは getUserMedia の収録ストリームのみで、デバイス側の対応は保証されない。非対応の場合は OverconstrainedError になり、実際に有効な値は getSettings で読み取る | 文書のみ |
| C3003 | マイクモードとホスト認識の関係 | モードは自前で収録するストリームにのみ作用し、ホストの音声認識には作用しない。ホスト認識はホストのマイクを使い、モード設定とは無関係である | 文書のみ |
| C3004 | 録音形式 MediaRecorder | 音声は audio/wav、audio/ogg;codecs=opus に対応する | 文書のみ |
| C3005 | wx 録音 RecorderManager | start、pause、resume、stop とフレームコールバックを持つ。使うマイクはデフォルト固定で、ソースやモードを選ぶパラメータはない。モードを選びたい場合は C3001、C3002 を使う | 文書のみ |
| C3006 | 音声合成 speechSynthesis.speak | 合成してそのまま再生し、ランタイム共通プレーヤーのキューを通る。mode は enqueue（デフォルト）または immediate | 文書のみ |
| C3007 | 音声合成 speechSynthesis.synthesize | 生成のみで再生はせず、中止可能なタスクを返す。字幕粒度 none、sentence、word、音声形式 pcm、mp3、ogg_opus、サンプルレート、チャネル数、ビットレートを指定でき、再生は SpeechAudioPlayer で別途行う | 文書のみ |
| C3008 | 合成音声の音色 | 固定の音色 ID が11種：female-tianmei、English_radiant_girl、English_expressive_narrator、male-qn-qingse、male-qn-jingying、female-yujie、Chinese (Mandarin)_News_Anchor、Chinese (Mandarin)_Radio_Host、clever_boy、lovely_girl、English_Trustworthy_Man。getVoices はない | 文書のみ |
| C3009 | 合成の制御 | utterance の lang 属性は無効で、生成言語は変わらない。cancel、pause、resume はない。pitch、rate、volume のデフォルトはいずれも 1 | 文書のみ |
| C3010 | wx 読み上げ wx.speech.playTTS | 1文を読み上げる。リクエスト ID の文字列を返し、失敗時は空文字列を返す | 文書のみ |
| C3011 | 音声認識 SpeechRecognition | ホストのマイクで認識する。プロパティは lang、continuous、interimResults、maxAlternatives。start にはビューがインタラクティブな状態を保っていることが必要で、満たさなければ InvalidStateError になる。lang が空のときはホストがデフォルト言語を選ぶ | 文書のみ |
| C3012 | 音声認識 SpeechRecognitionSession | 外部音声ストリームを認識し、セッション自体はマイクを開かない。ホットワード phrases と boost、セグメンテーション auto、VAD、semantic、updateContext による動的コンテキストに対応する。使用前に getCapabilities でホストの実能力を確認する | 文書のみ |
| C3013 | 認識エラーの種別 | error イベントのエラー種別が取りうる値について、公式の列挙表はない。種別ごとにエラー処理を分けるのは裏付けのない前提であり、依存してはならない | 文書のみ |
| C3014 | 大規模モデルの可用性 LanguageModel.availability | available または unavailable のみを返し、プロバイダ、モデル一覧、エンドポイントは公開されない | 文書のみ |
| C3015 | 大規模モデルセッション LanguageModel.create | 実体はホストの OpenAI 互換 chat-completions ストリーミング経路である。モデルの決定順は、明示した model、ホストの defaultModel の順。system は initialPrompts の先頭要素にのみ置ける | 文書のみ |
| C3016 | 大規模モデルのマルチモーダル入力 | user メッセージの content 配列は text と image_url に対応し、画像は data: URL でもよい。構造化された content は user ロールに限られる | 文書のみ |
| C3017 | 大規模モデルのツール呼び出し | tools はプロバイダへのリクエストボディに転送される。呼び出しはセッションの toolcall イベントで戻り、callId、functionName、arguments を含む。自動では実行されず、構造化された往復プロトコルの保証はない | 文書のみ |
| C3018 | 大規模モデルのリクエスト prompt と promptStreaming | ストリーミングはポーリング式の read であり、WHATWG Stream でも async iterator でもない。同一セッションで同時に進行できるリクエストは1件のみ。destroy 後は使えない | 文書のみ |
| C3019 | オーディオ再生 AudioPlayer | 汎用プレーヤーで、パッケージ内ファイルまたはネットワーク URL を扱う。pcm、ogg_opus のストリーミング追記再生と字幕テキストトラックに対応する | 文書のみ |
| C3020 | 効果音 Sound | ローカルファイル専用の短い再生で、http と https の URL は受け付けない | 文書のみ |
| C3021 | Web Audio | AudioContext と createBuffer、Oscillator、Gain、BiquadFilter、Analyser、MediaStreamSource、decodeAudioData などが使え、波形とスペクトルの解析ができる | 文書のみ |

### 3.4 センサーと測位

根拠：`skill: references/apis/device.md`、`skill: references/apis/geo/geolocation.md`、公式 IMU ガイド。測位には権限 C7001 が必要。

| ID | プリミティブ | 結論 | 検証 |
|---|---|---|---|
| C4001 | 加速度センサ Accelerometer | 3軸加速度 x、y、z と timestamp。イベントは activate、reading、error。コンストラクタのパラメータ frequency はホストへの目安にすぎない | 文書のみ |
| C4002 | ジャイロセンサ Gyroscope | 3軸角速度 x、y、z と timestamp。イベントと frequency の意味は C4001 と同じ | 文書のみ |
| C4003 | 絶対方位センサ AbsoluteOrientationSensor | 絶対方位のクォータニオン quaternion [x, y, z, w] と timestamp を返す。利用できるかはデバイスのハードウェア対応に依存する | 文書のみ |
| C4004 | サンプリングレート | 最大周波数と精度について、公式に公表された数値はない。公式ガイドのサンプルは 60 を使い、30 から 60 Hz で始めることを勧めている | 文書のみ |
| C4005 | その他のセンサ | 地磁気、照度、近接の各センサには単独の API がなく、公式一覧に載っていない | 文書のみ |
| C4006 | 頭部ジェスチャ onHeadGesture | Page 内で enableWorldAwareness を有効にする必要がある。公式サンプルに現れるジェスチャ値は nod（うなずき）のみで、全列挙は公表されていない。未確認事項の第7項を参照 | 文書のみ |
| C4007 | 頭部の安定検知 onOrientationStabilityChange | 同じくワールドアウェアネスの有効化が必要。event.stable が頭部の安定状態の変化を表す | 文書のみ |
| C4008 | アイトラッキング | 存在しない。いわゆる視線は、頭の向き C4003 と安定検知 C4007、うなずき C4006 の組み合わせで代替する | 文書のみ |
| C4009 | 測位 geolocation | getCurrentPosition と watchPosition があり、解放は clearWatch。coords には latitude、longitude、accuracy（メートル）と、null になりうる altitude、altitudeAccuracy、heading、speed が含まれる。オプションは enableHighAccuracy（デフォルト false）、timeout、maximumAge。エラーコードは 1 が拒否、2 が取得不可、3 がタイムアウト | 文書のみ |
| C4010 | GPX GPXDocument | GPX ルートの解析、作成、エクスポート：setStartPoint、addWaypoint、appendTrackPoint、toString、toBlob。map と map-gpx コンポーネントと組み合わせて軌跡を表示する | 文書のみ |
| C4011 | Bluetooth BLE | セントラル側として動作する：getAvailability、getDevices、requestDevice、scanDevices（Ink 独自）、GATT の connect、readValue、writeValue、startNotifications。requestDevice、scanDevices、connect、startNotifications はビューがインタラクティブな状態にあることを要求する | 文書のみ |
| C4012 | Bluetooth ペリフェラルとブロードキャスト | 存在しない。公式一覧にペリフェラル機能は載っていない | 文書のみ |

### 3.5 表示ランタイムとページ

根拠：`skill: references/framework.md`、`skill: references/apis/window.md`、`skill: references/apis/canvas.md`、`skill: references/events.md`、公式ランタイム環境ドキュメント。

| ID | プリミティブ | 結論 | 検証 |
|---|---|---|---|
| C5001 | ランタイム Ink | ロジック層とビュー層は、QuickJS と Skia でできた独自コンテナ Ink の中で動く。ES2023、ESM | 文書のみ |
| C5002 | 基準キャンバス | フルスクリーン Page の基準キャンバスは 480 × 352。安全マージンは左右 16 px、上下 12 px で、有効なコンテンツ幅は 448 px | 文書のみ |
| C5003 | 単色グリーンの設計制約 | 基調色 #40ff5e、輝度は6段階。黒は透明な背景と等価であり、不透明な黒いパネルで現実の景色を覆うことはできない。意味は色だけで担わせず、アイコン、テキスト、線種を重ねる。本文の輝度は 72% 以上、装飾線は 24% 以下が目安で、重要な情報は中央の快適な視野に置く | 文書のみ |
| C5004 | ビューポートサイズ | window.innerWidth、innerHeight は読み取り専用の論理ピクセル | 文書のみ |
| C5005 | Widget のサイズ | サイズ区分は 1x1 が 239 × 140、1x2 が 480 × 140。グラス側の Widget グリッド枠は合計4つ。family はサイズの区分にすぎず、ルートノードをそのピクセル値に固定して書いてはならない | 文書のみ |
| C5006 | 画面を開く window.open | 開けるのは app.json に宣言済みの Widget のみで、target は _widget のみ。overlay の重ね表示に対応する。他の Page や外部 URL は開けない | 文書のみ |
| C5007 | インスタンスを閉じる window.close | ホストに現在の Agent インスタンスを閉じるよう要求する | 文書のみ |
| C5008 | Agent 間遷移 | 存在しない。公式一覧に openAgent に類する項目はなく、wx.navigateTo は自 Agent 内のページ遷移に限られる。総則 R1 を参照 | 文書のみ |
| C5009 | ホスト設定画面を開くこと | 到達できない。そのための API はなく、「何々の設定を開く」類のインテントは、ホストがアプリ自体を開くところまでしか実行しない。総則 R1 を参照 | 文書のみ |
| C5010 | プロジェクト構成 | app.json、app.js、AGENTS.md、pages からなる。ページは .ink の単一ファイル、または .json、.wxml、.wxss、.js の4点セット。任意で widgets、workers、components、assets を置ける | 文書のみ |
| C5011 | 組み込みコンポーネント | 記述できるタグは合計37種で、コンテナ、テキスト、フォーム、メディア、地図、キャンバス、グラフと、AI 生成 UI の a2ui を含む | 文書のみ |
| C5012 | Agent Worker | UI を持たないスクリプトで、open で起動する。lifetime は instant または foreground で、background は予約されているが無効。タイマー、Promise、Crypto、Wasm、エンコードストリームがある。window、document、fetch、ルーティング、描画、メディア取得はない | 文書のみ |
| C5013 | 言語とモジュール | TypeScript のエントリと WebAssembly モジュールに対応し、プロジェクトのパッケージング工程を通る | 文書のみ |
| C5014 | Canvas 2D | パス、矩形、measureText を含むテキスト、変換、グラデーション、パターン、drawImage は引数3個、5個、9個の3形式のみ。色のパースは #rrggbb、#rgb、rgb、rgba と少数の名前付き色のみ。出力は convertToBlob と createImageBlob 経由で、canvas.toDataURL は存在しない | 文書のみ |
| C5015 | WXML テンプレート | template は未対応 | 文書のみ |
| C5016 | 会話フローカード | デフォルトでは表示のみ。対話的な画面にはフルスクリーン Page または Widget が必要 | 文書のみ |
| C5017 | デバイス情報 navigator | id は Agent とデバイスに結びついた不透明な ID で、認証情報として扱ってはならない。userAgent と versions.ink、versions.skia がバージョン文字列を与える。language、languages、region は空の場合がある。onLine と connection がオンライン状態と接続の推定値を与える。renderingEnabled は現在のインスタンスが描画できるかどうかを表す | 文書のみ |
| C5018 | バッテリー getBattery | Promise を返す BatteryManager。ホストにバッテリー能力がない場合は Promise が拒否される。ドキュメントは不完全で、未確認事項の第8項を参照 | 文書のみ |
| C5019 | シリアル番号とトークン | getDeviceSerialNumber と requestDeviceToken はシステムレベルの Agent のみが使える。通常の Agent では空文字列が返るか、そもそも依存してはならない | 文書のみ |
| C5020 | グローバルなエンコード機能 | window.atob、btoa とグローバルの createImageBlob が使え、createImageBlob は PNG、JPEG へのエンコードを行う | 文書のみ |

### 3.6 ストレージ・ファイル・ネットワーク

根拠：`skill: references/apis/web.md`、`skill: references/apis/wx.md`、公式ネットワークガイド。

| ID | プリミティブ | 結論 | 検証 |
|---|---|---|---|
| C6001 | ローカルストレージ localStorage | 現在の Agent に隔離された文字列 KV：getItem、setItem、removeItem、clear | 文書のみ |
| C6002 | wx ストレージ | setStorage、getStorage、removeStorage、clearStorage と、その Sync 版。データは JSON でシリアライズされる | 文書のみ |
| C6003 | OPFS navigator.storage | Agent ごとに独立したファイルストレージで、localStorage や wx ストレージとは別系統。estimate() で現在の使用量とクォータを取得できるが、クォータはランタイムが返す値で、公式の数値は公表されていない。persisted() で永続化の状態を確認し、persist() で永続化を要求、getDirectory() でルートディレクトリを取得する。ファイルは createWritable() で書き込み、close() で確定する。ホストに OPFS のバックエンドがない場合は NotSupportedError で失敗する。現行は実用的なサブセットで、File System Access API の完全な実装ではない。出典は公式ドキュメントの OPFS 専用ページ | 文書のみ |
| C6004 | 汎用ファイルシステム | 存在しない。リソースはすべてプロジェクト内パスから解決され、任意パスの読み取り、書き込み、ディレクトリ列挙の API はない | 文書のみ |
| C6005 | FileReader | 存在せず、実機では必ず FileReader is not defined になる。Blob から data URL への変換は blob.arrayBuffer と分割した btoa で行う。関連エラーコード E2005 | 実機確認済み |
| C6006 | 存在しないブラウザ API | 以下はいずれも Ink ランタイムに存在せず、コードに書けば誤りになる：sessionStorage、XMLHttpRequest、URL.createObjectURL、DOMParser、structuredClone、queueMicrotask、Notification、クリップボード API、IntersectionObserver、MutationObserver、ServiceWorker、new Worker、OffscreenCanvas、getDisplayMedia、applyConstraints、getVoices、navigator.permissions | 文書のみ |
| C6007 | fetch と Web の機能 | fetch、Headers、body のストリーミング読み取りを含む Response、WebSocket、File、FormData、URL と URLSearchParams、Streams 一式が使える | 文書のみ |
| C6008 | wx ネットワーク | wx.request のタイムアウトの決定順は options.timeout、app.json の設定、デフォルト 60000 ms の順。wx.createSocket、connectSocket のほか、SSE 用の wx.createEventSource がある | 文書のみ |
| C6009 | Web Crypto | randomUUID と getRandomValues（上限 65536 バイト）が使える。subtle は SHA-1、256、384、512 のダイジェストと HMAC のみ。暗号化、復号、RSA、ECDSA、JWK は未対応 | 文書のみ |
| C6010 | スマートフォン経由の通信 | グラスが Wi-Fi に接続していないときでも、Bluetooth でスマートフォンのアプリとつながっていれば、fetch と wx.request は自動的にスマートフォン側の回線経由で転送され、インターネットに出る。開発者からは透過的である | 文書のみ |
| C6011 | HTTPS とドメインの許可リスト | 本番環境のネットワークリクエストは HTTPS でなければならない。ストア公開前に、リクエスト先ドメインを開発者向け管理画面で許可リストに登録しておく必要がある | 文書のみ |
| C6012 | LAN への直接接続 | 未対応。公式ガイドでは開発中とされ、ドキュメント目次にも unsupported と記されている | 文書のみ |
| C6013 | データのプリフェッチ | prefetch は未対応 | 文書のみ |
| C6014 | ソースマップによるデバッグ | 未対応 | 文書のみ |

### 3.7 権限

根拠：公式 framework ドキュメント app-json.md の権限表。2026-10-29 の全量監査で訂正した。権限は合計7つで、名称は大文字と小文字を区別し、認識されない名称を指定してもいかなる能力も得られない。あわせて C7008 の上流ドキュメント内の不整合に注意する。

| ID | プリミティブ | 結論 | 検証 |
|---|---|---|---|
| C7001 | 権限 GEOLOCATION | 現在位置の取得と位置変化の監視を行う。C4009 を参照 | 文書のみ |
| C7002 | 権限 CAMERA | カメラへのアクセスと、画像や動画の撮影を行う。3.2 節を参照 | 文書のみ |
| C7003 | 権限 RECORD_AUDIO | マイクへのアクセスと音声の収録を行う。ASR のマイク起動もこの権限に依拠し、独立した ASR 権限はない。旧 SPEECH_RECOGNITION は Ink 0.19 で削除された | 文書のみ |
| C7004 | 権限 READ_MEDIA_IMAGES | システムのメディアライブラリ内の画像を列挙し、読み取る | 文書のみ |
| C7005 | 権限 CREATE_MEDIA_IMAGES | システムのメディアライブラリへ画像を新規に追加する。既存リソースの変更と上書きは含まない | 文書のみ |
| C7006 | 権限 READ_MEDIA_AUDIO | システムのメディアライブラリ内の音声を列挙し、読み取る | 文書のみ |
| C7007 | 権限 CREATE_MEDIA_AUDIO | システムのメディアライブラリへ音声を新規に追加する。既存リソースの変更と上書きは含まない | 文書のみ |
| C7008 | 権限一覧のドキュメント上の扱い | aiui-dev スキルの framework リファレンスには今も最初の3つの権限しか載っておらず、上流ドキュメント内部の不整合である。framework の公式ドキュメントにある7つの名称を正とする | 文書のみ |

### 3.8 インタラクションとホスト

根拠：`skill: references/events.md`、Hi Rokid アプリ内蔵の操作ガイド（ジェスチャの部分。実機の挙動はこちらを正とする）。

| ID | プリミティブ | 結論 | 検証 |
|---|---|---|---|
| C8001 | ウェイクアップ onVoiceWakeup | 音声でもタッチでも起動できる。event.keyword の判明している値は、乐奇、Hi Rokid、clickAiAssist（タッチによる起動）。原則として keyword で絞り込まない。event.preventDefault でホストのデフォルト動作を引き継げる | 文書のみ |
| C8002 | キーイベント | Page の onKeyDown、onKeyUp は event.code で振り分けられる：Enter が確定、Backspace が戻る、ArrowUp と ArrowDown がスクロール、GlobalHook がテンプルタッチ専用のデバイス信号。ホストのデフォルト動作は onKeyUp の後に発火する | 文書のみ |
| C8003 | 1本指のタップ | 確定。Enter に対応 | 文書のみ |
| C8004 | 1本指のダブルタップ | 戻る。Backspace に対応し、戻る先のページがない場合は Agent を閉じるよう要求する | 文書のみ |
| C8005 | 1本指のスワイプ | スクロール。ArrowUp、ArrowDown に対応し、スクロール方向はアプリ側で変更できる | 文書のみ |
| C8006 | 1本指の長押し | アシスタントを起動する。グラスの AI アシスタントかスマートフォンのアシスタントかをアプリで選べる | 文書のみ |
| C8007 | 2本指のダブルタップ | 画面を消灯する | 文書のみ |
| C8008 | 2本指の前後スワイプ | 音量の上げ下げ。デフォルトではこの割り当てで、アプリ側で変更できる | 文書のみ |
| C8009 | 2本指の長押し AI ショートカット | 選んだ起動対象へ固定のテキストを1件送る。テキストの上限は500文字。起動対象には特定のカスタム Agent やデバッグ Agent を選ぶことができ、ASR を介さずに固定テキストを確定的に指定の Agent へ届けられる | 実機確認済み |
| C8010 | シーン別ジェスチャ | 音楽シーン：タップで再生または一時停止、前後スワイプで曲の切り替え。通話シーン：着信時のダブルタップで拒否、通話中のタップでミュートの切り替え、ダブルタップで通話を終了する | 文書のみ |
| C8011 | クリックのみを結んだボタン | bindtap だけを結んだボタンは、グラス上ではジェスチャで操作できない。ページ側でキー入力とアクションの対応付けを自前で行う必要があり、ボタンのクリックだけに頼ることはできない | 実機確認済み |
| C8012 | 音声起動の失敗する段階 | 定型句による起動の失敗は、音声認識の転写の段階で起きる。テキストが正しく転写された後の照合の段階ではない。Agent 名を短くしたり整えたりしても転写のつまずきを緩和できるだけで、回避はできない。確定的な入口は C8009 を参照 | 実機確認済み |
| C8013 | スマートフォンのコンパニオンアプリの役割 | ネットワークの中継は C6010 を参照。そのほか、デバイス管理と設定、メディア管理、AI 機能の入口、グラス用リソースパッケージの配信を担う | 文書のみ |

### 3.9 配布と審査提出

根拠：公式の公開ドキュメント publish.md と AIX ドキュメント。インポートの挙動はメンテナが 2026-10-24 に Global AIUI Studio で確認したもの。

| ID | プリミティブ | 結論 | 検証 |
|---|---|---|---|
| C9001 | 配布形式 AIX | AI eXecutable で、Open Agent Format に準拠し、コード、設定、静的リソースを自己完結で含む。パッケージング時に一意な UUID の VERSION ファイルが自動生成され、バージョン照合に使われる | 文書のみ |
| C9002 | パッケージサイズの上限 | 公式には数値が公表されていない | 文書のみ |
| C9003 | パッケージング除外 .aixignore | .agents、.aix、artifacts、*.aix、skills-lock.json、node_modules を除外しなければならない。除外しないと開発用ファイルがパッケージに入り、実測では 2.3 KB から 107 KB に膨らんだ | ビルド確認済み |
| C9004 | Studio のインポート挙動 | インポートダイアログには URL の入力欄が1つだけある。/tree/ より後ろは丸ごと1つの ref として扱われるため、サブディレクトリのアドレスではインポートに失敗する。リポジトリのルートのアドレスでインポートすると空のコードツリーが得られる。ブランチ名を1セグメントにし、ブランチのルートに1つの Agent の全ファイルを置くと、完全なプロジェクトとしてインポートに成功する | Studio確認済み |
| C9005 | 審査提出のレッドライン | 名称は必須で20文字以内、他者と重複してはならず、テストや test、beta などの語と最上級の表現を含んではならない。アイコンは必須で、デフォルトアイコンは使えない。機能紹介は500文字以内。オープニングメッセージは必須で、300文字以内が推奨される。プレビュー素材は3から5ファイルで、少なくとも画像1点と動画1点を含み、動画は60秒以内。各権限について用途を1件ずつ明記する | 文書のみ |
| C9006 | 審査提出の申告チェック | Studio の審査提出には、申告系のチェック項目が別にある：ネットワーク、カメラ、マイク、スピーカー、Rokid アカウント情報など。3.7 節の権限一覧とは別の仕組みである | 文書のみ |
| C9007 | 公開フロー | ビルド、Web シミュレーション、AIX のパッケージングとクラウドへのアップロード、実機デバッグ、審査提出資料の整備、審査への提出 | 文書のみ |
| C9008 | バージョンと ID の生成 | バージョン番号と Agent ID はいずれもシステムが生成し、開発者は編集できない | 文書のみ |

## 4. 未検証プローブ

プローブは、エントリを検証するために用意した検証用の仕組みである。本節にはプローブと、その対象とするエントリ ID だけを登録する。プローブのデータが揃ったら、結論を対象のエントリに書き戻して検証ステータスを更新し、本節の該当行は削除する。

| プローブ | 対象エントリ | 状態 |
|---|---|---|
| 能力ベンチマーク Agent。23項目で基盤を1件ずつ測る | C2002、C2004、C3002、C3011、C4001 から C4007、C5002 など | 構築済み。実機での再検証は未完了 |
| 映像・音声キャプチャ系の Agent 10件。それぞれ1件の映像・音声の境界を担う | C2002、C2004、C2006、C2007、C3001、C3002、C3021 | 構築済み。ハードウェア経路は実機データの戻りを待っている |
| ストップモーション Agent とログ返送クライアント | C6005 の再検証。エラーログを外部チャネルで返送することの実現可能性 | 構築済み。実機で1回通して動かすのを待っている |
| なぞり書きプローブ。結印と手話の2件 | C3016 の画像入力による静止画判定の実用性と命中率 | 構築済み。正式版への収録は実機データで決める |
| 連続映像ストリームプローブ | C2009 | 企画済み。未実行 |
| 認識エラー種別の収集 | C3013 | 実機で各種類のエラーを発生させた後、原文と照合する |
| ストレージプローブ：3 系統のストレージごとに往復セルフチェックと容量ランプを実行し、OPFS ステーションでは estimate() のクォータと永続化状態を読み取る。セッションをまたぐマーカーで保存データが再起動後も残ることを確かめる | C6001 から C6003 | 作成済み、実機ラウンド待ち |

## 5. 未確認事項と矛盾点

以下はエントリではない。公式ソース自体の食い違い、あるいは公式が示していない点であり、関係するエントリに紐づけて置く。公式の見解か実測で明らかになったら、エントリに取り込むか削除する。

1. 解像度の二重の口径：製品スペックの 480 × 400（C1005）とランタイムキャンバスの 480 × 352（C5002）が併存し、両者の関係は公式に説明されていない。
2. FOV についての第三者の説 23° と、解像度についての第三者の説 640 × 480 は、いずれも公式の裏付けがない。C1006、C1005 を正とする。
3. 駆動時間の口径が複数ある：同じ製品ページでも、FAQ は日常使用で 8 から 10 時間、比較表は混合使用で 6 時間、充電ケース併用で 30 時間としており、統一した測定条件がない（C1011）。
4. 第2チップの型番は公式に裏付けられていない（C1001）。
5. カメラセンサの型番と視野角は公式に公表されていない（C1008）。
6. IMU の軸数、型番、サンプリングレートの上限と精度は公式に公表されていない（C4001 から C4004）。
7. 頭部ジェスチャの全列挙は公式に公表されていない（C4006）。
8. getBattery のドキュメントが不完全である：navigator リファレンスはバッテリーのメソッドを device リファレンスで見るよう案内するが、device リファレンスに該当する章がない（C5018）。
9. デバイス世代の差異：Rokid Glasses 2 と第1世代のフルカラーグラスのキーマッピングは、公式 events リファレンスの中で未検証と注記されており、本表 3.8 節のマッピングを流用してはならない。
10. 公式ドキュメントの二系統：open.rokid.com/aiui が現行版、js.rokid.com が旧版であり、両サイトの差異はページ単位では照合していない。本表は公式リポジトリの documentation と aiui-dev スキルを正とする。
11. パッケージサイズの上限、ドメイン許可リストの登録入口、審査にかかる時間については、公式に詳しい説明がない（C9002、C6011）。
12. メディアライブラリの操作面が未明である：四つのメディア権限は app.json の権限表に定義があるが（C7004 から C7007）、メディアライブラリの資源を列挙・読み取り・保存する具体的な API は公式ドキュメントに記載がない。権限表の注記は、該当する操作が権限をチェックすることのみである。アルバム機能を開発する前に操作面を確かめること。他のプラットフォームの同種インターフェースを推測で使ってはならない。

## 6. 公式ソース一覧

**製品とプラットフォーム**

- Rokid Glasses 公式グローバル製品ページ（スペックの主たる出典）：https://global.rokid.com/products/b-h-rokid-glasses-with-display
- Rokid 英国公式サイト AI 製品ライン（スペックの相互確認）：https://gb.rokid.com/collections/rokid-ai-lineup
- 公式 Academy チュートリアル『3.6 Glasses AIUI』：https://global.rokid.com/de/blogs/academy-glasses/glasses-3-6-aiui

**公式ドキュメントサイト**

- AIUI ドキュメント（現行版）：https://open.rokid.com/aiui
- AIUI ドキュメント（旧版）：https://js.rokid.com/AIUI/guide/quickstart/ai-dev

**公式 GitHub リポジトリ yodaos-project/AIUI**

- リポジトリのトップ：https://github.com/yodaos-project/AIUI
- aiui-dev スキル（API 契約の一次資料）：https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev
- 審査提出と公開：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md
- AIX とは何か：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/aix.md
- ランタイム環境：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
- IMU ガイド：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md
- ネットワーク利用の説明：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md
- ドキュメント目次（lan、prefetch、sourcemap などの unsupported 表記を含む）：https://github.com/yodaos-project/AIUI/blob/main/documentation/toc.json

## 7. 変更履歴

### v2.2.0 2026-10-30

第 4 節の開口プローブにストレージプローブを追加した。storage-probe は作成済み（リポジトリの base/storage-probe）で、C6001 から C6003 を検証する。3 系統のストレージの往復の正しさと実容量、OPFS のランタイムクォータ、セッションをまたぐマーカーによる保存データの保持である。実機の数値が戻ったら該当条目の結論と確認状態を更新し、この行を取り下げる。第 5 節の未明リストに第 12 項を追加した：四つのメディア権限は app.json の権限表に定義があるが（C7004 から C7007）、メディアライブラリの資源を列挙・読み取り・保存する具体的な API は公式ドキュメントに記載がない。

### v2.1.0 2026-10-30

C6003 を訂正した。公式ドキュメントの OPFS 専用ページには navigator.storage のメソッド一式が記載されており、aiui-dev リファレンスの 1 文をもとに「メソッドの詳細は示されていない」としていた従来の記述は正確ではなかったため、同ページに沿って書き換えた。クォータはランタイムが返す値のみで、公式の数値は公表されていないことも明記した。第 5 節の第 9 項（StorageManager のメソッド詳細）は解消したため削除し、以降の項番号を繰り上げた。あわせて、エントリ側の参照項番号に生じていた 1 つずれを揃えた（C1011、C4006、C5018）。

### v2.0.0 2026-10-29

アトミックレジストリへの再構成。全文を9つの区分に分けて123件の番号付きエントリとし、各エントリにプリミティブ、結論、検証ステータスを持たせた。「ID と運用ルール」「総則」「未検証プローブ」の3節を新設した。旧第5節の矛盾と未確認の点は、エントリ ID を付けて残した。シナリオ類の問いは個別収録をやめ、エントリと総則から導く形に統一した。

### v1.1.0 2026-10-29

第4節に、プラットフォームの位置づけに関する公式見解「Agent は単体で完結する」を加え、4.3 の表に Agent 間遷移とホスト設定画面を開くことの2件を追加した。見出し全体から括弧書きの注記を取り除き、注記の内容は本文へ移した。「はじめに」と本変更履歴を新設した。

### v1.0.0 2026-10-29

リポジトリへの公開版。本書のもとになった資料は 2026-10-24 に作成したもので、公式製品ページ、公式ドキュメントサイト、公式リポジトリの aiui-dev リファレンスを集約している。リポジトリに入れるにあたり汎用化の処理を行い、開発者内部の運用方針と個人の使用痕跡を取り除いた。能力に関する事実には手を入れていない。
