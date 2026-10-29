# お薬手帳

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：
```
https://github.com/sakai55/rokid/tree/agent-okusuri-techou
```

**AIX 直接下载**（最新版）：[okusuri-techou.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/okusuri-techou.aix)

一句话场景：高齢者がお薬手帳を眼鏡で守る——服薬時刻を逃さず、残量と次回受診を一冊で管理する。

## 方向构成

日本在地 × 路缘坡 × 注意力：

- **日本在地**：お薬手帳は日本の薬局・受診制度に根ざした生活物で、薬の呼び名・服用時刻・受診の回し方が日本日常そのもの（UI 全日语）。
- **路缘坡**：高齢者の服薬継続という具体的バリアを先に立てる——時刻を覚えきれない、残量を見落とす、受診日を忘れる、という三つのつまずきに直接応える。
- **注意力**：服薬時刻の守候（今日のチェック）、残量の見守り（7 以下警告）、受診の記録（前回＋30 日）という保持モードが各页承担的一环。

## 预览截图

![手帳总览](<../screenshots/okusuri-techou/preview-okusuri-techou-index.png>)
![今日服薬チェック](<../screenshots/okusuri-techou/preview-okusuri-techou-medicine.png>)
![今日服薬チェック（チェック済み）](<../screenshots/okusuri-techou/preview-okusuri-techou-medicine-s2.png>)
![残量・受診記録](<../screenshots/okusuri-techou/preview-okusuri-techou-record.png>)
![残量・受診記録（補充後）](<../screenshots/okusuri-techou/preview-okusuri-techou-record-s2.png>)

## 结构与功能

三页，形态各异（手帳表紙＋背脊／横罫ページ／台帳表）：

- **手帳总览（pages/index）**：今日の服薬進捗（x / 6）、残量 7 以下の警告一覧、次回受診予定（前回受診日＋30 日）、二子页菜单（▶ 标记）。
- **今日服薬チェック（pages/medicine）**：薬 6 種＝朝の血圧薬（7:00・朝食前）・昼の胃薬（12:30・昼食後）・夜の睡眠薬（21:30・就寝前）・食後のビタミン（8:30・朝食後）・週1回の骨薬（日曜 9:00）・頓服の痛み止め（必要時）。点头或 Enter 逐个打勾，打勾即当日分持久化、残量减 1；6 種齐全时 TTS 播报完成。
- **残量・受診記録（pages/record）**：6 種残量数（既定数 28／28／28／30／4／10，7 以下标 ⚠），Enter／点头为选中药補充回既定数；「受診日を記録」记当日为前回受診日，次回予定＝前回＋30 日。

内容集计数：薬 6 種（時刻・用法付き）、既定残量 6 数、受診記録 1 件（前回日＋次回予定の派生）。跨会话持久化键：`okusuriTechouV1`（当日チェック・残量・受診日）。

## 手势映射

| 操作 | 镜腿／头部 | 作用 |
| --- | --- | --- |
| 上／下移动 | ArrowUp／ArrowDown | 总览：循环选子页；子页：上／下一项 |
| 确认 | Enter | 总览：打开选中子页；子页：主动作（打勾／補充） |
| 点头 | onHeadGesture('nod') | 子页主动作（打勾／補充） |
| 返回 | Backspace（镜腿双击）／BACK 按钮 | 回上一页；首页 onShow 时选中项复位为第 1 项 |

## 权限

无。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## 诚实边界

- 服薬チェックは本人の申告（点头／ボタン）であり、実際に飲んだことの医学的証明ではない；残量はチェック回数からの推定で、薬の実物数えではない。
- 残量警告は 7 以下の目安であり、処方・受診の判断は医師・薬剤師に委ねる；医療効果は主張しない。
- TTS は服薬時刻の案内のみで、服薬の指示・変更はしない。

## 设备测试信息

| 项目 | 内容 |
| --- | --- |
| Studio 名 | お薬手帳（待主代理推送后回填） |
| Version | 1.0.0 |
| App Category | 待主代理推送后回填 |
| Intent Description | 高齢者の服薬を眼鏡で守る：今日の服薬チェック・残量・次回受診の一括管理 |
| Agent ID | 待主代理推送后回填 |
| 状态 | 已打包已推送未真机未提审（待主代理推送后回填） |

## 提审资料 (Review Submission)

- Feature Description: 高齢者の服薬を眼鏡で守るお薬手帳。今日の服薬6種を時刻・用法付きでチェックし、残量と次回受診を一冊で管理します。点头で一つずつ打勾でき、残量が少なくなると警告し、受診日を記録すると次回予定を出します。記録は端末に残り、翌日も引き継がれます。
- Opening Message: **お薬手帳へようこそ。** 今日のお薬を一緒に確認しましょう。上下で選んで、点头か Enter で「飲んだ」を付けます。残量と次の受診日もこの一冊で見守ります。
- Preview Media: 5 张预览截图（见上「预览截图」节；视频待真机录制后补）。
- Change Log (Build 1.0.0):
  - Features added: 三页新作（手帳总览／今日服薬チェック／残量・受診記録）；薬 6 種内容集、残量警告、受診日記録と次回予定、跨会话持久化。
  - Improvements: （首版，无）
  - Fixes: （首版，无）
