# 通学路みまもり

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：
```
https://github.com/sakai55/rokid/tree/agent-tsugaku-mimamori
```

**AIX 直接下载**（最新版）：[tsugaku-mimamori.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/tsugaku-mimamori.aix)

一句话场景：小学生が眼鏡をかけて登校し、通学路のチェックポイントでうなずいて到着を記録し、帰宅後に記録を確認できる。

## 方向构成

日本在地 × 路缘坡 × 注意力。

- 日本在地：日本の小学生の通学路（集合場所・横断歩道・公園前・踏切・コンビニ前・神社前・学校門・下校集合場所）そのものが場面であり、ユーザーに見える文言はすべて日本語。
- 路缘坡：先行人群は通学児童（方向感覚・注意力が未発達で、道順の保持と到着確認に手助けが要る）。溢出先は方向感覚の弱い成人訪問者（初めての土地で道順を辿る人）であり、児童のための設計が薄まらない。
- 注意力：8 地点を順に盯守し、到着を 1 点ずつ記録して 8 点そろったことを確認する「見守り」閉環。未到達点は記録頁で提醒する。

## 预览截图

![通学路みまもり ルート总览](../screenshots/tsugaku-mimamori/preview-tsugaku-mimamori-index.png)
![通学路みまもり チェック](../screenshots/tsugaku-mimamori/preview-tsugaku-mimamori-check.png)
![通学路みまもり チェック 2](../screenshots/tsugaku-mimamori/preview-tsugaku-mimamori-check-s2.png)
![通学路みまもり 記録](../screenshots/tsugaku-mimamori/preview-tsugaku-mimamori-record.png)
![通学路みまもり 記録 2](../screenshots/tsugaku-mimamori/preview-tsugaku-mimamori-record-s2.png)

## 结构与功能

- ルート总览（pages/index）：8 地点をドットで結んだ通学路として一覧し、今日の登校の到達状況を ●／○ で示す。今日の登校／下校の進捗も数で出す。
- チェック（pages/check）：現在の地点を大きく表示し、その地点の一句话特徴を出す。うなずき／Enter で到着にチェックを入れ、時刻を記録する。ArrowUp/ArrowDown で前／次の地点に移る。登校／下校はボタンで切り替える。8 点そろったら「登校完了」／「下校完了」を TTS で播报する。
- 記録（pages/record）：登校／下校の記録を日ごとに端末から読み、到達数と未到達点を示す。▶ 選択した方向の未到達点を読み上げる。

内容集の数：通学路チェックポイント 8 处（集合場所・横断歩道・公園前・踏切・コンビニ前・神社前・学校門・下校集合場所，各 1 句话特征）。

## 手势映射

| 操作 | 动作 |
| --- | --- |
| ルート总览：子页选择 | ArrowUp / ArrowDown 循环选チェック／記録（▶ 标记），Enter 打开选中子页；子页返回后 onShow 强制复位为第 1 项（チェック），故返回后直接 Enter 必开チェック、ArrowDown 一次＋Enter 必开記録 |
| チェック：上／下一地点 | ArrowUp（前）/ ArrowDown（次） |
| チェック：到着（主动作） | 点头（onHeadGesture('nod')）或 Enter，或「到着チェック」按钮 |
| チェック：登校／下校切换 | 「登校／下校」按钮 |
| 記録：方向选择 | ArrowUp / ArrowDown 循环选登校／下校（▶ 标记），Enter 朗读该方向未到達点 |

## 权限

无。位置情報は使わない。到着は本人のうなずき／Enter による申告のみで記録する（GPS による自動判定はしない）。TTS は宿主の固定音色を使い、utterance に `lang` は設定しない。

## 诚实边界

- 到着記録は本人の申告であり、眼鏡が位置を測った証明ではない。画面と記録はその旨に沿って「チェック」として扱う。
- うなずき検出が使えない場合は Enter／ボタンでも記録できる。
- 記録のない日は 0 / 8・未到達全点として表示し、記録をでっち上げない。

## 设备测试信息

| 项目 | 内容 |
| --- | --- |
| Studio 名 | tsugaku-mimamori（导入后按需改名） |
| Version | 1.0.0 |
| App Category | 生活 |
| Intent Description | 小学生が眼鏡をかけて登校し、通学路でうなずいて到着を記録し、帰宅後に記録を確認できる |
| Agent ID | 待回填 |
| 状态 | 未导入／未真机验证 |

## 提审资料 (Review Submission)

Feature Description：小学生の通学路みまもりです。集合場所から学校門まで8つのチェックポイントを順にたどり、着いたらうなずいて時刻を記録します。8地点そろうと完了をお知らせし、帰宅後に登校・下校の記録と未到達点を確認できます。位置情報は使いません。

Opening Message：通学路みまもりへようこそ。今日の通学路を一緒にたどりましょう。着いたらうなずいてチェックしてくださいね。

Preview Media：预览截图见上（ルート总览／チェック／記録，全页截图由 aix preview 生成；视频待真机阶段补）。

Change Log（Build 1.0.0）：

- Features added：ルート总览（8 地点ドット＋今日進捗）；チェック（地点大字表示・一句话特徴・うなずき／Enter 到着記録・時刻保存・8 点完了播报・登校／下校切替）；記録（日ごとの登校／下校到達数・未到達点提醒・記録日数）。
- Improvements：无（首版）。
- Fixes：无（首版）。
