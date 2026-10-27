---
name: "rokid-conflict-audit"
description: "Audit Rokid AIUI Agents against the glasses' built-in (default) capabilities: any agent whose core mechanic IS a built-in feature is a conflict, no matter how it is dressed up. Produces the three-tier verdict （直接冲突 / 高度重叠 / 待测试） that drives the root README conflict badges and the SOP thickness gate. Use when tiering a new agent, re-auditing the fleet, or before any submission."
version: "1.0.0"
---

# Rokid 默认能力冲突排查 (Built-in Capability Conflict Audit)

**Version: 1.0.0** — 版本迭代规则见文末。首版源头：2026-10-25 对全舰队 122 个 Agent 的首次排查（GO 指令），完整报告在 Muse 工作区 `~/workspace/rokid/audit-builtin-conflicts/REPORT.md`。

## 为什么有这个 skill

眼镜整机自带一套完整功能。Agent 若把自带功能换个名字重做一遍，就是造轮子：用户开自带功能即可，不需要这个 Agent；提审时也站不住（SOP Governing rule 的厚度关：与默认能力同本体直接出局）。本 skill 把「什么算冲突」的口径固定下来，使每个新 Agent 立项时可自查、全舰队可复查、根 README 的冲突徽章有唯一数据源。

## 默认能力基线（判定前必须先核对最新版）

基线只取官方/公开来源，不凭印象。当前基线（2026-10-25 核定，来源：官方能力档案 `~/memory/rokid-glasses-capabilities.md` §1.1/§3.5、官方全球产品页、公开评测实证）：

1. **实时翻译**（89 种语言）：对话翻译字幕、拍照翻译文字/菜单/路牌；AI 快捷指令预置即有「拍照翻译成中文」。
2. **实时字幕（Intelligent Captioning）**：同语言对话实时上屏，且字幕留历史、可事后回看。
3. **会议转写 + AI 摘要**：转写带说话人识别，自动生成智能摘要；语音笔记同为自带。
4. **提词器**：原稿上屏，按朗读语速/停顿自动滚动跟随。
5. **慧眼辨识 / AI 视觉问答**：「Hi Rokid」助手 + 相机，看物识物、读字读牌、场景问答。
6. **视觉化 AR 导航**：方向箭头 + 速度/时长/到达时间上屏。
7. **个人助理 AI 问答、通知显示、拍照录影、通话/音乐**。

复查时先验证基线有没有变（新机型、新系统版本、官方新功能都可能扩基线）；基线变了，按文末规则升版本并重排受影响档位。

## 判定口径（三档，互斥）

判定对象是 Agent 的**本体机制**（它替用户做的那件事本身），不是它借用的通道。

- **第一档 · 直接冲突**：本体就是某项默认功能，只加了一层小扭转（换个触发方式、加个小过滤、截取一段时间窗）。GO 点名样板：`chat-catchup`（SO01）——自带字幕已留历史可回看，「摇头调最近 15 秒摘要」只是小扭转，判多余。处置：不得重组提审（SOP 硬规则）；是否下架/删草稿等 GO 裁决，不自动执行。
- **第二档 · 高度重叠**：本体大半可由默认功能「问一句/开一下」完成，只剩一层薄闭环（如读字后多一步登记/比对、问答后多一步分步引导）。去留由 GO 逐簇裁决；裁决前不提审。
- **第三档 · 待测试**：既非一档也非二档的全部编号 Agent 统一归此档——含义是「与默认能力的关系要等真机测试后定性」，不是「已验不冲突」。新 Agent 默认进此档，审计后才改档。

不算冲突的情形（归第三档并在报告中写明理由）：默认能力只作闭环中的一步，登记 → 守候/分区覆盖/逐步计数/事后回放的闭环是自带功能没有的（如 `drop-search` 的分区覆盖搜索、`my-bus-watch` 的目标线路守候过滤）。

## 排查流程

1. **列全集**：枚举仓库分类目录下全部 Agent（以根 README 清单为准核对差集，退役保留的不入清单、不参与定档）。
2. **读本体**：逐个读 PLAN 登记行与 README 的机制描述，写下本体一句话；读不到机制实现的，读 `pages/index/index.ink` 与 AGENTS.md 核实，不凭 slug 猜。
3. **对基线**：本体逐项对七项基线，按上节口径定档；擦边的写清「默认功能能完成到哪一步、Agent 多出的那一层是什么」，再定二档或三档。
4. **出报告**：更新工作区报告（逐项对照表：一档全列、二档按簇列、三档汇总），注明基线版本与本次 skill 版本。
5. **同步徽章**：根 README 清单的冲突徽章以报告档位为准（一档=直接冲突、二档=高度重叠、三档=待测试）；徽章定义冻结，不得借同步之名新增/改动任何徽章定义（GO 2026-10-25 裁定）。
6. **留裁决口**：一档的处置、二档的逐簇去留只报 GO 裁决；未裁决前不删、不提审、不把待裁决写成已处置。

## 当前档位（v1.0.0 基线下，2026-10-25 定档）

- 第一档 14：DI 系 `gaze-translate`、`head-nav`、`parking-return`、`baby-care-hands`、`far-ear`、`ambient-captions`、`sign-reader`、`transit-direction`、`speaker-focus`、`teleprompter-gaze`；注意力系 `chat-catchup`(SO01)、`standup-echo`(SO04)、`meeting-filter`(FI04)、`talk-replay`(RE02)。
- 第二档 40：看图问答簇 / 读字登记簇 / 笔记提醒簇 / 字幕转写簇 / 读屏读号簇（明细见报告）。
- 第三档：其余编号 Agent（舰队 122 个中 68 个；根 README 图例计数 88 含 JP/KR 现役 20 个）。
- 预筛教训：路缘坡 CC07 `last-sentence` 立项时以「字幕可回放」与慧眼区隔，按 SO01 口径区隔不成立——新立项凡以「自带功能的某个子特性」作区隔的，先过本 skill 再开工。

## 版本迭代规则

本 skill 带版本号迭代，任何修改必须同时做三件事：升版本号、在下方变更日志追加一条、报告里注明所依据的 skill 版本。

- **PATCH（x.y.Z）**：措辞、例子、流程细节修正，判定口径与基线不变。
- **MINOR（x.Y.0）**：基线增删一项、判定口径补充新情形、流程增加步骤——可能引起档位变化，须在变更日志里写明受影响的 Agent。
- **MAJOR（X.0.0）**：档位体系或口径根本变化（如 GO 更换判定标准），全舰队须按新口径重排并全量同步徽章。

## 变更日志 (Changelog)

- **v1.0.0（2026-10-28）**：首版落地。内容源自 2026-10-25 首次全舰队排查（122 个 Agent，报告 `~/workspace/rokid/audit-builtin-conflicts/REPORT.md`）：七项默认能力基线、三档判定口径、排查六步、当前档位（14 / 40 / 68）。此前该方法只存在于一次性报告与记忆条目中，本版起固化为 skill 维护。
