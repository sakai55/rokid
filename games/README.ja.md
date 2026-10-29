# 頭部動作ミニゲーム（games/）

[中文](README.md) | [English](README.en.md) | 日本語
中文版（2026-10-29 時点）からの翻訳。

頭部動作＋撮影による現実連動ミニゲームシリーズ · 番号 GA01–GA50：頭部動作 GA01–GA40 と撮影ゲーム GA41–GA50。頭の動きや撮影で現実と関わって遊ぶ、ごくシンプルなミニゲーム。

- GA01 [nod-count](nod-count/) — 音声ガイドで10回のゆっくりしたうなずき、下を向いて正面に戻ると1回
- GA02 [turn-count](turn-count/) — 音声ガイドで左右交互に振り向き、左右各5回で計10回
- GA03 [ear-tilt](ear-tilt/) — 耳を肩に寄せる動きを左右各3回、5秒止めて1回
- GA04 [stretch-hold](stretch-hold/) — 上を向く・下を向くを交互にストレッチ、各5秒保持を各3回
- GA05 [neck-clock](neck-clock/) — 読み上げられた時計の位置へ頭を向け、各地点で必ず正面に戻る
- GA06 [chin-tuck](chin-tuck/) — あごを小さく引いて5秒保持、あご引き運動8回
- GA07 [steady-hold](steady-hold/) — 頭を10秒間ぴたりと止めれば勝ち、動くと数え直し
- GA08 [nod-catch](nod-catch/) — 10個のボールが落ちてくる、うなずいて線を踏んで受け止め得点
- GA09 [turn-dodge](turn-dodge/) — 障害物が左なら右へ避け、10ラウンド正面に戻って得点
- GA10 [follow-dot](follow-dot/) — 光点が跳んだ先へついていき、止まって合わせると的中
- GA11 [rhythm-nod](rhythm-nod/) — 16拍の固定リズム、拍に合わせてうなずくと得点
- GA12 [memory-seq](memory-seq/) — 方向の順序を音声で読み上げ、覚えて順番どおりに再現
- GA13 [find-target](find-target/) — 方向を音声で知らせ、そちらを向いて止まれば発見
- GA14 [level-keep](level-keep/) — 頭を水平に保ち、傾くとボールがずれ、10秒保持で勝ち
- GA15 [slow-scan](slow-scan/) — 左から右へゆっくり走査、速すぎると音声で修正
- GA16 [nod-quiz](nod-quiz/) — ○×問題にうなずきで「はい」、横を向いて止まると「いいえ」で得点
- GA17 [breathe-turn](breathe-turn/) — 息を吸いながらゆっくり振り向き、吐きながらゆっくり戻る、左右各3回
- GA18 [guess-direction](guess-direction/) — 秘密の方向を当て、音声が「近づいた／遠ざかった」を知らせ、向ければ的中
- GA19 [traffic-light](traffic-light/) — 青信号で読み上げた方向を向き、赤信号ではぴたりと止まる
- GA20 [daily-routine](daily-routine/) — うなずき・振り向き・耳寄せ・上下・あご引き、一式を2分で完了
- GA21 [angle-match](angle-match/) — 片側に角度を指定され、±5度の帯に入って止まれば一致
- GA22 [tilt-match](tilt-match/) — 耳寄せで小さい角度に合わせ、±5度の帯に入って止まれば一致
- GA23 [pace-turn](pace-turn/) — 一回の振り向きに3〜5秒かけると等速扱い、速くても遅くても無効
- GA24 [stop-center](stop-center/) — 片側から正面に戻り±5度以内で停止、行き過ぎは誤り、左右交互に8回
- GA25 [hold-ramp](hold-ramp/) — 下向き保持2/3/4/5/6秒と段階的に伸ばし、各段階で正面に戻る
- GA26 [memory-six](memory-six/) — 6方向の順序3/4/5ステップ、覚えて順番どおりに再現
- GA41 [snap-hunt](snap-hunt/) — 画面に目標物が出るので、現実の環境で見つけて撮影、大規模モデルが有無を判定
- GA42 [color-catch](color-catch/) — ラウンドごとに色が出るので、主色が合う実物を撮って判定
- GA43 [word-spot](word-spot/) — 看板や包装から目標の文字を探して撮影、判定した文字を読み上げるので確認できる
- GA44 [barcode-bingo](barcode-bingo/) — 実物から異なるコード体系のバーコードを探し、3x3ビンゴ盤に読み込んでラインを作る
- GA45 [scene-memory](scene-memory/) — パノラマ写真を1枚撮ると記憶問題が3問出題、頭を向けて記憶で答える
- GA46 [frame-align](frame-align/) — 指定物を九分割グリッドの指定マスへ移して撮影、判定が位置を知らせて照合
- GA47 [odd-one-out](odd-one-out/) — 同種3個と異種1個を並べ、先に位置を当ててから撮影して判定を開示
- GA48 [size-sort](size-sort/) — 同種3個を並べ、先に大小順に並べてから撮影して全順序を照合判定
- GA49 [texture-hunt](texture-hunt/) — ラウンドごとに質感が出るので、実物の表面に寄って撮影し質感を判定
- GA50 [snap-diff](snap-diff/) — 同じ場面を2回撮影、先に変更の種類を宣言してから2枚で判定（シリーズ完結）
全リストは[リポジトリ ルート README](../README.md) 末尾の Agent リストを参照。
