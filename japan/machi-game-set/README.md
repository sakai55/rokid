# Machi Game Set（待ち時間ゲーム集）

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄に貼り付け）：

```
https://github.com/sakai55/rokid/tree/agent-machi-game-set
```

JP21 ・ 日本在地 × 指向性 × ゲーム。ブティックラインでの合併リメイク：JP15 `matsuri-taiko`（祭り太鼓リズム）と JP17 `kotowaza-quiz`（ことわざクイズ）を、待ち時間向け頭部ゲーム集として 1 つに合併した。元の 2 つの Agent はそのまま保管し、削除も変更もしない。場面を一言で表すと：祭りや駅で順番を待つ家族が、頭の動きだけで遊べる二つのゲームで待ち時間を過ごし、ベスト記録を端末に残す。

## プレビュー画像

![プレビュー-index](<../../screenshots/machi-game-set/preview-machi-game-set-index.png>)
![プレビュー-taiko](<../../screenshots/machi-game-set/preview-machi-game-set-taiko.png>)
![プレビュー-quiz](<../../screenshots/machi-game-set/preview-machi-game-set-quiz.png>)
![プレビュー-quiz-s2](<../../screenshots/machi-game-set/preview-machi-game-set-quiz-s2.png>)

## 構造と機能（完結した流れ）

3 ページ構造（ゲームカートリッジ式メニュー / 太鼓の円陣 / 問答の 2 枚カード）：

- **メニュー（pages/index）**：2 モードの大きなタイル。保存されたベストスコア、ことわざ到達級、プレイ回数を表示する（wx storage `machiGameSetV1`）。
- **太鼓（pages/taiko）**：収録内容は 3 曲（祭り囃子 8 拍 72 BPM／盆踊り 10 拍 60 BPM／山車リズム 12 拍 84 BPM）。開始時に正面で中心を校正し、AbsoluteOrientationSensor の yaw / pitch を実際に読み取って「うなずく（ドン）／左を向く／右を向く（カッ）」を判定する。拍ごとに HIT / MISS を判定し、コンボとスコアを集計し、終了時にベストを書き戻す。動作は分段だけを認める（向く→正面に戻る）。回す動きは決して使わない。`onHeadGesture('nod')` でもドンを入力できる。
- **ことわざ（pages/quiz）**：収録内容は 12 問、3 級（4 問ごとに 1 級上がる）。頭部を左右に回す（yaw が中心に対して ±0.40 rad）ことで A / B を選び、即時に正誤を示し、TTS で解説する。正解は 100 点。終了時に集計し、ベストと到達級を保存する。

方向の分担：ゲームは開始 / 勝敗 / スコア付けという遊びの完結した流れを担い、指向性は頭部の向きの判定（2 モード共通の唯一の主な入力）を担い、日本在地は祭りとことわざという内容そのものを担う。

## ジェスチャー対応表

| ジェスチャー（テンプル側タッチパッド） | キーイベント | 本 Agent での役割 |
|---|---|---|
| 1 回タップ | Enter | 太鼓の開始／ドン（ゲーム中） |
| 左スワイプ / 右スワイプに対応するキー | ArrowLeft / ArrowRight | 太鼓の左 / 右の動作、問答の A / B（頭を回す操作と同等） |
| うなずき | `onHeadGesture('nod')` | 太鼓のドン |
| 頭部の左右の回転 | AbsoluteOrientationSensor | 問答で A / B を選ぶ、太鼓の左 / 右 |
| 2 回タップ | Backspace | システムの戻る操作（子ページの BACK キーでも可） |

安全性：頭部の動作はゆっくり小さくし、動作の合間には必ず正面に戻る。痛みやめまいを感じたら直ちに中止する。本 Agent はいかなる医療効果も主張しない。

## 権限

なし。センサーと wx storage に権限の宣言は不要である。TTS はホストの固定音声を使い、utterance の `lang` は決して設定しない。

## 正直な境界

- センサーが使えない場合は「センサーなし（キーでも遊べます）」と明示し、キー操作で代用する。センサーの読み取り値を装わない（プレビュー画像では太鼓ページにセンサー使用中と表示されているが、これは Web ランタイムがセンサーのスタブを提供しているためである）。
- スコアと進み具合は端末内の wx storage だけに保存し、ネットワークにはつながず、ランキングにも載せない。

## 実機テスト情報

| 項目 | 値 |
|---|---|
| Studio 名 | Machi Game Set（インポート後に記入） |
| Version / Build | 1.0.0 |
| App Category | Entertainment（インポート時に確認） |
| Intent Description | 待ち時間に頭で遊ぶ太鼓とことわざのゲーム集 |
| Agent ID | インポート後に記入 |
| 状態 | パッケージ化済み、プッシュ済み。Studio 未インポート、実機テスト未実施、審査未提出 |

## 審査提出資料 (Review Submission)

### Feature Description (≤500 chars)

待ち時間向け頭部ゲーム集です。太鼓リズムゲーム（3 曲、頭部方向センサーで読むうなずき / 左 / 右の動作、分段の動きと中心への復帰、コンボによるスコア付け）と、頭を回して答える 3 段階 12 問のことわざクイズを収めます。ベストスコアと進み具合は端末に保存されます。

### Opening Message (≤500, Markdown)

**待ち時間ゲーム集へようこそ。** 太鼓とことわざ、遊びたい方を頭の動きで選んでください。記録は端末に残ります。

### Preview Media

画像 4 枚（本ページのプレビュー画像）。動画は実機の段階で追加する（審査提出の要件は 3–5 件のファイル、画像 1 件以上、動画 1 件以上）。

### Change Log

#### Build 1.0.0
- Features added: 3 ページの新作（メニュー / 太鼓 / ことわざ）。JP15 + JP17 の合併リメイク。曲目 3 首、問答 12 問、スコアと進み具合はセッションをまたいで保存される。
- Improvements: なし（初版）。
- Fixes: なし（初版）。

## パッケージ化とプレビュー

- パッケージ化：`~/tools/bin/aix pack . -o machi-game-set.aix`（リポジトリ内の複製は `aix/machi-game-set.aix`）
- プレビュー：`~/tools/bin/aix preview . --html-out artifacts/preview.html` のあと、ローカルの画像取得パイプラインを使う（ポート 8902）
