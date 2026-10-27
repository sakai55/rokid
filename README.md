# かるた取り

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：
```
https://github.com/sakai55/rokid/tree/agent-karuta-tori
```

一句话场景：家族が待ち時間に、頭の動きだけでかるたを取る。

## 方向构成

日本在地 × 指向性 × 游戏。

- 日本在地：かるた取りそのものが日本の家族の待ち時間の遊びであり、句は季節・日常の日本語で作る。ユーザーに見える文言はすべて日本語。
- 指向性：頭の左右（AbsoluteOrientationSensor の yaw）で札を選ぶことが核心入力。開始時に正面を校准し、左右への分段動作でカーソルを 1 枚ずつ動かす。
- 游戏：20 首の対戦として開始／正誤判定／計分／勝敗決着まで一本の閉環。ベストスコア・取札数・プレイ回数は跨会话で残る。

## 预览截图

![かるた取り 札一覧](../screenshots/karuta-tori/preview-karuta-tori-index.png)
![かるた取り 対戦](../screenshots/karuta-tori/preview-karuta-tori-play.png)
![かるた取り 対戦 2](../screenshots/karuta-tori/preview-karuta-tori-play-s2.png)
![かるた取り 記録](../screenshots/karuta-tori/preview-karuta-tori-record.png)
![かるた取り 記録 2](../screenshots/karuta-tori/preview-karuta-tori-record-s2.png)

## 结构与功能

- 札一覧（pages/index）：20 枚の札を 5 列 × 4 行の札面グリッドで一覧し、前回対戦で取った札に ●、まだの札に ○ を付ける。スポット表示で 1 首ずつ上の句を確認できる。
- 対戦（pages/play）：毎ラウンド TTS が目標の上の句を読み上げる。候補 4 枚（目標 1 枚＋別の札 3 枚）の中から頭の左右で選び、うなずき／Enter で取札を確定する。正解 +100 点、不正解 −50 点。20 首すべて終えたら勝敗を決める（正解 14 以上で勝ち）。
- 記録（pages/record）：ベストスコア・取札総数・プレイ回数・前回の成績を端末から読む。

内容集の数：自作オリジナル上の句 20 首（季節・日常）。句集はすべて本作オリジナルであり、百人一首の原文を引用していない。

## 手势映射

| 操作 | 动作 |
| --- | --- |
| 札一覧：子页选择 | ArrowUp / ArrowDown 循环选対戦／記録（▶ 标记），Enter 打开选中子页；子页返回后 onShow 强制复位为第 1 项（対戦），故返回后直接 Enter 必开対戦、ArrowDown 一次＋Enter 必开記録 |
| 対戦：选札 | 头向左／右（分段动作，向く→正面に戻る→次），或 ArrowLeft / ArrowRight / ArrowUp / ArrowDown |
| 対戦：取札（主动作） | 点头（onHeadGesture('nod')）或 Enter |
| 対戦：再听一句 | 「もう一度聞く」按钮 |
| 記録：行选择 | ArrowUp / ArrowDown 循环，Enter 朗读汇总 |

头动作一律分段：向く→正面に戻る→次の動作。頭を回すことは絶対に要求しない。ゆっくり小さく動き、痛み・めまいがあれば中止すること。

## 权限

无。TTS は宿主の固定音色を使い、utterance に `lang` は設定しない。

## 诚实边界

- 句集 20 首はすべて自作オリジナルであり、古典の引用ではない。
- センサーが使えない場合は画面の evt 行にその旨を出し、キーでも遊べることだけを案内する。センサー読取を装わない。
- TTS が使えない場合は読み上げを省略し、画面表示だけで遊べる。成功したふりをしない。
- 頭部動作に医療効果は主張しない。

## 设备测试信息

| 项目 | 内容 |
| --- | --- |
| Studio 名 | karuta-tori（导入后按需改名） |
| Version | 1.0.0 |
| App Category | ゲーム |
| Intent Description | 家族が待ち時間に、頭の動きだけでかるたを取る |
| Agent ID | 待回填 |
| 状态 | 未导入／未真机验证 |

## 提审资料 (Review Submission)

Feature Description：頭の動きだけで遊べる家族のかるた取り。20首の自作オリジナル句を音声で聞き、左右を向いて札を選び、うなずいて取ります。正解で得点し、20首で勝敗が決まります。ベストスコアと取札数が端末に残ります。

Opening Message：かるた取りへようこそ。札一覧で今日の札を確認して、対戦で頭を動かして札を取りましょう。ゆっくり小さく動いてくださいね。

Preview Media：预览截图见上（札一覧／対戦／記録，全页截图由 aix preview 生成；视频待真机阶段补）。

Change Log（Build 1.0.0）：

- Features added：札一覧（20 枚グリッド＋取／未マーク＋スポット表示）；対戦（TTS 読み上げ・頭左右選択・うなずき確定・正誤計分・20 首決着）；記録（ベスト・取札総数・プレイ回数の跨会话保存）。
- Improvements：无（首版）。
- Fixes：无（首版）。
