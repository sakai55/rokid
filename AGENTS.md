# Machi Game Set — Agent Notes

JP21（日本在地 × 指向性 × 游戏）。精品线合并重做：由 JP15 `matsuri-taiko` 与 JP17 `kotowaza-quiz` 合并为「等候时间头部游戏集」，原两个 Agent 原样封存。交互哲学：**ゲームカートリッジ式メニュー Game Cartridge Menu**，三页结构（菜单/太鼓/问答）。

一句话场景：祭りや駅で順番を待つ家族が、頭の動きだけで遊べる二つのゲーム（太鼓节奏＋ことわざ問答）で待ち時間を過ごし、記録を端末に残す。

## Design contract

- メニュー（index）：二つのモードを大きなタイルで提示し、保存済みベストスコアとプレイ回数を表示。
- 太鼓（taiko）：3 曲（8/10/12 拍、60–84 BPM）。開始時に正面を校准し、AbsoluteOrientationSensor の yaw/pitch で「うなずく/左/右」を判定、拍ごとに HIT/MISS、コンボとスコアを集計。動作は分段のみ（向く→正面に戻る）、回転は要求しない。onHeadGesture('nod') でも「ドン」を受け付ける。
- ことわざ（quiz）：12 問・3 級（4 問ごと級上げ）。頭の左右で A/B を回答、即時正誤＋TTS、正解 100 点。
- 記録：ベストスコア・到達級・プレイ回数は wx storage `machiGameSetV1` に跨会话保存。

底座七项均不构成其本体（游戏集であり、翻訳・字幕・転写等ではない）。

## 诚实边界

- センサー不可用時は明示し、キー（ArrowLeft/Right/Enter）で代替できることだけを案内する。センサー読取を装わない。
- 頭部動作はゆっくり小さく。痛み・めまいがあれば中止すること（README に明記）。医療効果は主張しない。

## Permissions

none。TTS 用宿主固定音色，永不设置 utterance の `lang`。

## Validation

- 静态校验与打包结果见精品线台账；预览截图在仓库 `screenshots/machi-game-set/`。
