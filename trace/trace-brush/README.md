# TR01 Trace Brush · 毛笔字描红练习

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-trace-brush
```

描红系列 TR01：中央范本 + 边上步骤 + 做一步验一步。书法初学者在书桌前打开它，逐笔学一个范字，在自己面前的真纸上用真毛笔写，写完低头拍照验字——只查粗项，不装专业评分；进度跨会话保存，下次接着练。

## 功能（7 页闭环）

| 页 | 内容 |
|---|---|
| 今日 | 今日一字（按日期轮换）、上次练到哪、已练字数 / 累计次数 |
| 字库 | 20 字总表：每字标拼音、笔画数、练过次数，选字进学字页 |
| 学字 | 中央范字逐笔渲染：当前笔最亮绿、已学笔中绿、未学笔暗绿；右侧笔顺步骤 + 本笔要点，TTS 同步念要点；逐笔推进 |
| 字义笔法 | 读音、字义一句、结构、重心提示、逐笔类型清单 |
| 验收 | 低头对准自己写的字拍照，LLM 对照范字粗查三项：有没有少笔多笔、结构重心偏没偏、最明显的 1–2 处；看不清如实说、重拍 |
| 点评 | 一句人话点评 + 三项结果；用户可自己确认「这字算过」覆盖机器判定，覆盖落盘计数 |
| 进度 | 已练字集、每字次数、练习天数；复习抽查（只给拼音不给范字，凭记忆写完再验） |

## 字库与数据来源（双源，缺一不收）

- **分笔数据**：`hanzi-writer-data`（Make Me a Hanzi 项目）——逐字 JSON 的 `strokes[]` 逐笔 SVG 路径（序即笔顺）与 `medians[]` 中线点列。数据由 Arphic（文鼎）字体提取，依 **Arphic Public License** 再分发，许可证全文见工程内 `LICENSE-data.txt`。
- **笔顺校对**：《通用规范汉字笔顺规范》GF0023-2020（教育部、国家语委发布）。
- **收字结果**：20 字笔画数逐字核对通过——永 5、人 2、大 3、天 4、上 3、下 3、山 3、川 3、水 4、火 4、木 4、日 4、月 4、田 5、口 3、中 4、心 4、正 5、生 5、白 5。**纠正一处常见误记：永是 5 画**，「永字八法」说的是永字包含八种基本笔法，不是八画。20 字全为简繁同形，避开字形分歧。台湾教育部笔顺学习网数据因 CC BY-NC-ND（非商业 + 禁改作）与提审冲突，只作人工参考、不取数据。
- 逐笔要点（第 X 笔 · 笔型：起笔 / 行笔 / 收笔）为本系列自撰的练习提示，不是书法评分标准。

## 方向性 / 交互

核心 = SCAN（拍照验字）+ HEAD（点头执行 / 验收页点头拍照）。手势：点头 = 执行焦点；单指点按 = 确认（Enter）；上下滑 = 切焦点 / 选字；双击 = 返回（Backspace）。学字页 TTS 同步念每笔要点。

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | 验收时拍用户自己写的字，转 data URL 给 LLM 图片输入粗查 |

## 错误码

本台遵循全局错误码表（仓库根 `ERROR-CODES.md`，裸码 `E####`）。出错时屏显裸码 + 一行说明，最近一次错误保存在 `lastError`（含码、slug、版本、原文截断）。回报问题时请带上眼镜上显示的码。
本台用到：E1001 相机打开失败、E1002 相机权限未给、E1003 拍照器不可用、E1007 相机设备不存在、E1009 拍照失败、E2002 画布创建失败、E2013 文本编码失败、E5001 记录保存失败、E5002 记录读取失败、E6001 大模型不可用、E6002 大模型请求失败、E6011 大模型输出不可用、E8001 页面切换失败、E9001 未分类错误。

## 真机信息

| 项 | 值 |
|---|---|
| Studio name | （待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | （待导入后回填） |
| Intent Description | 毛笔字描红：20 字逐笔范字学写，拍照粗查三项，本人改判，进度续练 |
| Agent ID | （待导入后回填） |
| 状态 | 已打包，待 GO 导入真机测试（提审等 GO 确认真机测试完成） |

## 打包 / 预览命令

```bash
~/tools/bin/aix pack . -o trace-brush.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 预览截图

（Web 预览渲染：验收页无相机时如实显示待拍状态；范字渲染为真实分笔数据绘制。）

![今日页](../../screenshots/trace-brush/preview-trace-brush-index.png)
![字库页](../../screenshots/trace-brush/preview-trace-brush-library.png)
![学字页](../../screenshots/trace-brush/preview-trace-brush-learn.png)
![字义笔法页](../../screenshots/trace-brush/preview-trace-brush-detail.png)
![验收页](../../screenshots/trace-brush/preview-trace-brush-verify.png)
![点评页](../../screenshots/trace-brush/preview-trace-brush-review.png)
![进度页](../../screenshots/trace-brush/preview-trace-brush-progress.png)

## 提审资料 (Review Submission)

- **Feature Description**（≤500 字）：毛笔字描红练习：20 个常用字逐笔范字浮在眼前（当前笔最亮），跟着在真纸上用真毛笔写，写完低头拍照，只查少笔多笔、结构重心和最明显的差别，给一句人话点评；判定可由本人改判，进度保存、下次续练，还有只给拼音的复习抽查。
- **Opening Message**：今天练一个字：一笔一笔看清，在纸上写完，拍照看看差在哪。
- **Preview Media**：见「预览截图」7 张（图片）；视频待真机阶段补（提审需 3–5 个文件、含 ≥1 视频 ≤60s）。
- **Change Log**（Build 1.0.0）：Features added — 7 页闭环（今日 / 字库 / 学字 / 字义笔法 / 验收 / 点评 / 进度）、20 字分笔字库、逐笔 TTS 要点、拍照粗查三项、本人改判、跨会话进度与复习抽查；Improvements — 无；Fixes — 无。
