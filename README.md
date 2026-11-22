# 盆踊りゲーム集

**Studio インポートアドレス**（Global AIUI Studio の Import Project 入力欄にコピー）：

```
https://github.com/sakai55/rokid/tree/agent-bon-odori-games-shuu
```

[bon-odori-games-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/bon-odori-games-shuu.aix)

## 機能

盆踊り会場の待ち時間、家族みんなで眼鏡一台を使って盆踊りのゲーム20本で遊び、得点を決める。頭を向けてえらび、うなずいて決め、ベストは次も残る。

## シーン

盆踊り会場の待ち時間に、家族が眼鏡一台で盆踊りのゲーム20本で遊び、得点を決める。

## 方向構成

日本在地 × ゲーム × 指向性 × 注意力。ゲームが盆踊りの遊び20本を、指向性が頭の向きでえらぶ役を、注意力が数え・クイズ・順番で見分ける役を担う。

## 眼鏡だけの能力

頭の方向の連携＋うなずきが主確認：両手がうちわや提灯でふさがっていても、頭を向けてえらび、うなずくだけで遊べる。接線：全ゲーム頁の onHeadGesture('nod') が primaryTap と同じ主確認で進め、方向当て頁 t05／t08／t13／t18 の _startSensor（AbsoluteOrientationSensor、存在性ガード）＋ _onYaw（左／中／右の3区、中へ戻って再武装、一回の向きで一区だけ）で向きを合わせる。センサーが使えないときはボタンでえらぶ。遊びの判定はデモの判定で、ほんものの盆踊りの動きを読み取るものではない。数えゲームの数は、目の前の提灯や踊り手を自分で見て数えた数を入れるもので、カメラで数えるものではない。

## ページ

| ページ | ページ |
|---|---|
| pages/index | 20の盆踊りゲーム一覧 |
| pages/t01 | 盆踊り数え |
| pages/t02 | 盆踊り提灯数え |
| pages/t03 | 盆踊り順番 |
| pages/t04 | 盆踊りクイズ |
| pages/t05 | 提灯方向当て |
| pages/t06 | うちわ数え |
| pages/t07 | やぐら飾り順番 |
| pages/t08 | 盆踊り方向当て |
| pages/t09 | 提灯順番 |
| pages/t10 | 提灯色当て |
| pages/t11 | 浴衣色当て |
| pages/t12 | 盆踊りお盆クイズ |
| pages/t13 | 浴衣方向当て |
| pages/t14 | 提灯計算 |
| pages/t15 | 盆踊り振り付け順番 |
| pages/t16 | 盆踊り計算 |
| pages/t17 | 浴衣数え |
| pages/t18 | うちわ方向当て |
| pages/t19 | 浴衣計算 |
| pages/t20 | 盆踊り記録 |

## 内容集

20のゲーム：数え4つ（盆踊り数え10／盆踊り提灯数え12／うちわ数え8／浴衣数え15）＋方向当て4つ（提灯方向当て／盆踊り方向当て／浴衣方向当て／うちわ方向当て、1回に6回）＋クイズ4つ（盆踊りクイズ／提灯色当て／浴衣色当て／盆踊りお盆クイズ）＋順番4つ（盆踊り順番／やぐら飾り順番／提灯順番／盆踊り振り付け順番、5段階ずつ）＋計算3つ（提灯計算 8+6／盆踊り計算 7+5／浴衣計算 9+4）＋盆踊り記録1つ。クイズの答えはほんものの盆踊りの事実（やぐらで太鼓を打つ／提灯はふつう赤／浴衣は藍色が多い／盆踊りはお盆にご先祖さまを迎える踊り）。

## セッションをまたぐ保存

保存キー `bonOdoriGamesShuuV1`（えらんだゲーム、ゲームごとのベスト、終わった記録、lastError）。

## 権限

権限の宣言なし。音声読み上げは宿主管理で、宣言は不要。カメラと位置情報は使わない。

## ジェスチャー対応

| 単指タップ | Enter | 主確認 |
| 上下スワイプ | ArrowUp / ArrowDown | 選択切替 |
| うなずき | onHeadGesture('nod') | 主確認と同じ |
| ダブルタップ | Backspace | 戻る |

## エラーコード

- `E5001` 保存の書き込み失敗
- `E5002` 保存の読み込み失敗
- `E3005` 音声読み上げ失敗
- `E8001` ページ遷移失敗
- `E7001` 頭部センサー不可または読取失敗

- 得点は本物のうなずきとタップだけで決まり、作った得点はない。
- 遊びの判定はデモの判定で、ほんものの盆踊りの動きを読み取るものではなく、えらんだものが目標と合うかだけで決めます。
- 数えゲームの数は自分で見て数えた数で、カメラで数えるものではありません。
- 一回の向きでは一区だけ変わり、中へ戻らないとまた変えられず、くるくる回らない。
- センサーが使えないときはボタンでえらぶ。遊びの判定は変わらない。センサー失敗は E7001 を残す。

## プレビュー画像

![preview-bon-odori-games-shuu-index.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-index.png)
![preview-bon-odori-games-shuu-t01.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t01.png)
![preview-bon-odori-games-shuu-t02.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t02.png)
![preview-bon-odori-games-shuu-t03.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t03.png)
![preview-bon-odori-games-shuu-t04.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t04.png)
![preview-bon-odori-games-shuu-t05.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t05.png)
![preview-bon-odori-games-shuu-t06.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t06.png)
![preview-bon-odori-games-shuu-t07.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t07.png)
![preview-bon-odori-games-shuu-t08.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t08.png)
![preview-bon-odori-games-shuu-t09.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t09.png)
![preview-bon-odori-games-shuu-t10.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t10.png)
![preview-bon-odori-games-shuu-t11.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t11.png)
![preview-bon-odori-games-shuu-t12.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t12.png)
![preview-bon-odori-games-shuu-t13.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t13.png)
![preview-bon-odori-games-shuu-t14.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t14.png)
![preview-bon-odori-games-shuu-t15.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t15.png)
![preview-bon-odori-games-shuu-t16.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t16.png)
![preview-bon-odori-games-shuu-t17.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t17.png)
![preview-bon-odori-games-shuu-t18.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t18.png)
![preview-bon-odori-games-shuu-t19.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t19.png)
![preview-bon-odori-games-shuu-t20.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t20.png)
![preview-bon-odori-games-shuu-t01-s2.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t01-s2.png)

## 提審資料

### Feature Description

盆踊り会場の待ち時間、家族みんなで眼鏡一台を使って盆踊りのゲーム20本で遊び、得点を決める。頭を向けてえらび、うなずいて決め、数え・方向当て・クイズ・順番・計算で遊び、ベストと記録は次も残る。

### Opening Message

盆踊りゲーム集へようこそ。頭を向けてゲームをえらび、うなずいて遊ぼう。20本のゲームで得点を決めよう。

### Preview Media

[preview-bon-odori-games-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-video.mp4)
![preview-bon-odori-games-shuu-index.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-index.png)
![preview-bon-odori-games-shuu-t01.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t01.png)
![preview-bon-odori-games-shuu-t05.png](../screenshots/bon-odori-games-shuu/preview-bon-odori-games-shuu-t05.png)

### Change Log

- Features：初版機能は上記の通り。
- Improvements：なし。
- Fixes：なし。

## デバイス試験情報

| Studio 名 | 未記入 |
|---|---|
| Studio 名 | 未記入 |
| Version / Build | 未記入 |
| App Category | 未記入 |
| Intent Description | 未記入 |
| Agent ID | 未記入 |
| 状態 | 未記入 |
