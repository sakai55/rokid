<div align="center">

# `rokid` — Rokid AIUI Agents

**Rokid AI 眼镜的 AIUI 智能体仓库 · 海外版 / Global**
只做 **Agent**，不做 App。一个仓库装下所有 Agent，靠**分支**逐个导入 Studio。

![last commit](https://img.shields.io/github/last-commit/sakai55/rokid?style=flat-square)
![repo size](https://img.shields.io/github/repo-size/sakai55/rokid?style=flat-square)
![studio](https://img.shields.io/badge/AIUI%20Studio-Global%20·%20en--US-00C853?style=flat-square)
![scope](https://img.shields.io/badge/scope-AIUI%20Agents%20only-blue?style=flat-square)

</div>

> [!IMPORTANT]
> **导入铁律**：往 Global AIUI Studio 导单个 Agent，只用它的专属分支地址
> `https://github.com/sakai55/rokid/tree/agent-<slug>`。
> 子目录地址、根地址、blob 地址都已实测证伪（见 [Studio 导入](#studio-导入实测结论)）。
> 保底路线：`aix/` 目录里的 `<slug>.aix` 下载后走 **Import from AIX**。

## 目录

- [仓库结构](#仓库结构)
- [快速开始](#快速开始)
- [标准工作流](#标准工作流)
- [Studio 导入（实测结论）](#studio-导入实测结论)
- [海外链路（全链路海外，缺一不可）](#海外链路全链路海外缺一不可)
- [真机测试（云端下发）](#真机测试云端下发)
- [提交审核](#提交审核)
- [维护约定](#维护约定)
- [Agent 清单](#agent-清单)

## 仓库结构

```text
rokid/
├── README.md                  # 本文件
├── <slug>/                    # 一个 Agent 一个目录（一套完整 AIUI 工程）
│   ├── app.json  AGENTS.md  app.js  package.json
│   ├── pages/                 # .ink 页面
│   └── README.md              # 该 Agent 的真机信息表 + 提审资料（以它为准）
├── aix/<slug>.aix             # 全部 Agent 打包好的 AIX（集中存放，备选导入用）
├── screenshots/<slug>/        # 预览截图集中存放，Agent 的 README 直接嵌入
├── skills/                    # 项目 Skill 库（官方 aiui-dev + 自有 SOP / 截图管线）
├── mcp/                       # MCP 登记处（在用服务器、接入方式、凭据存放位置）
├── assets/                    # README 素材（如工作流图 workflow.svg）
└── 分支 agent-<slug>          # 每个 Agent 一个分支，分支根目录 = 该 Agent 工程根
```

## 快速开始

```bash
npm install -g @yodaos-pkg/aix-cli          # AIX CLI（pack / preview / show）
npm create @yodaos-pkg/aiui-agent@latest    # 官方脚手架
npx skills add https://github.com/jsar-project/AIUI/tree/main/skills/aiui-dev
                                            # aiui-dev Skill（给 Coding Agent 用）
aix pack . -o <slug>.aix                    # 在 Agent 目录内打包
aix preview .                               # 本地预览（起服务 / --html-out 导出 HTML）
```

> [!WARNING]
> 打包前项目根必须有 `.aixignore`，排除 `.agents/`、`.aix/`、`artifacts/`、`*.aix`、
> `skills-lock.json`、`node_modules/`——否则开发文件会进包（实测 2.3 KB → 107 KB）。

## 标准工作流

<div align="center">

<img src="assets/workflow.svg" width="1000" alt="标准工作流：本地开发 → 预览截图 → 推 GitHub → 同步分支 → Studio 导入 → 打包保存 → 云端下发 → 真机测试 → 提交审核"/>

</div>

1. **本地开发** — 在 `<slug>/` 目录里开发、改页面。
2. **预览** — `aix preview` 出该 Agent **所有页面**的预览图，存 `screenshots/<slug>/`。
3. **推 GitHub** — 目录推 main；重打 `<slug>.aix` 放 `aix/` 目录；同一套文件同步到分支 `agent-<slug>` 的**根目录**。
4. **Studio 导入** — 粘贴分支地址导入（见下节），一个分支导一个 Agent。
5. **真机测试** — 云端下发，见 [真机测试](#真机测试云端下发)。
6. **提交审核** — 真机测试通过并经维护者确认后，在 **Submit** 页签提交（见 [提交审核](#提交审核)）。

## Studio 导入（实测结论）

导入对话框（`IMPORT PROJECT` / "GitHub Subdirectory Import"）**只有 URL 一个输入框**，
没有分支/路径选择；Studio 把 `/tree/` 后的**整段当作一个 ref**，不拆「ref + 路径」。
2026-10-24 逐条实测：

| 地址形式 | 结果 |
|---|---|
| ✅ `…/tree/agent-<slug>`（专属分支） | **唯一可用**：导入该分支根目录 = 一个完整 Agent，文件树完整；已实测可运行、可打包 |
| ❌ `…/tree/main/<slug>`（子目录） | `GitHub ref not found: main/<slug>`（官方仓库 `JellyFlow/AIUI/tree/main/samples/scanner` 同样失败） |
| ❌ `…/tree/<完整 commit SHA>/<slug>` | 同样 ref not found |
| ❌ 仓库根地址 | 能导入，但是**空心 Agent**（Code 文件树为空） |
| ❌ `…/blob/main/<slug>/app.json` | 能过导入，Run 报「请先创建Agent的项目文件」 |

**分支法要点**

- 分支名必须是**单段**（`agent-<slug>`），分支**根目录**放该 Agent 的全套文件。
- 导入后生成的 Draft 名为 `sakai55/rokid`，进 Studio 后改名。
- 改代码后重新导入：先同步分支根目录，再重新粘贴分支地址导入，然后走真机流程。

<details>
<summary><b>备选：AIX 导入（保底路线）</b></summary>

1. 在仓库 `aix/` 目录里点开 `<slug>.aix`，下载到本地。
2. Global AIUI Studio → New Agent → **Import from AIX**，上传该文件。
3. 导入后生成 Draft，文件树即包内完整工程；后续同样走 Device Debug 打包 → 真机测试。

不依赖 GitHub 地址解析，赶时间或 GitHub 导入异常时用它；日常首选分支法（直接对应最新代码）。

</details>

## 海外链路（全链路海外，缺一不可）

> [!CAUTION]
> 以下四点齐全才算海外版开发；任何一环用了国内版，链路就不通。
> 国内站（aiui.rokid.com）与 Global 站账号、项目**不互通**。

| 环节 | 必须用 | 不能用 |
|---|---|---|
| 账号 | [account-web.rokid.com](https://account-web.rokid.com/) **英文版**注册（本项目地区：Japan） | 国内版注册的账号 |
| Studio | [aiui-global.rokid.com/?lang=en-US](https://aiui-global.rokid.com/?lang=en-US) | aiui.rokid.com |
| 下发 | Studio 打包保存 → **云端下发**到眼镜 | ADB / 数据线直装 |
| 手机 App | **Hi Rokid**（Google Play，包名 `com.rokid.sprite.global.aiapp`，Rokid International） | 国内版 Rokid Ai App |

## 真机测试（云端下发）

<details>
<summary><b>展开完整步骤</b>（在 Global AIUI Studio 里打开该 Agent 后）</summary>

1. 进 **Device Debug** 页签，填 **Basic Information**：
   - Agent Icon（建议 1:1）、**Agent Name**（必填）
   - **App Category**（必填）：Life / Work / Entertainment / Learning
   - **Intent Description**（必填，≤500 字）：写清什么场景、什么前提下、被什么样的用户请求唤起
   - Version / Agent ID 由系统生成；**Version 是 Build 号，每次 Repackage and Save 自动递增**
2. **AIX Packaging** 区点 **Repackage and Save**，等打包完成。
3. **成功标志**：顶部绿色状态 **● Debug version ready — Ready for device debugging**。
   没出现就说明没保存成功，App 端拉不到，不要白等。
4. 手机打开 **Hi Rokid**（海外版）→ 确认眼镜已连接 →「设置 → 开发者选项 → AIUI」→
   「更新眼镜资源包」→ 等「智能体资源包下载成功」。
5. 对眼镜语音打开 Agent（如「乐奇，打开 xxx」）开始测试。
6. 迭代循环：改代码 → 推 GitHub / 同步分支 → Studio 重新导入 → Repackage and Save
   → Hi Rokid 更新资源包 → 再测。**只改代码不重新打包保存，App 拉到的还是旧版。**

</details>

## 提交审核

真机测试全部通过后（以维护者确认「真机测试完成」为准）：

1. 在 **Submit** 页签填 **Review Information**：Feature Description、Opening Message、
   Preview Media、Change Log。**四项成稿在各 Agent 自己 README 的「提审资料
   (Review Submission)」章节里，分段写好，整段复制**（Feature Description ≤500 字；
   Opening Message ≤500 字、支持 Markdown；Preview Media 需 3–5 个 JPG/PNG/MP4
   且 ≥1 图 ≥1 视频，每次提交前重新确认）。
2. 权限声明与代码一致：`app.json.permissions` 里声明实际用到的能力
   （如 `GEOLOCATION` / `CAMERA` / `RECORD_AUDIO`）。
3. **Submit for Review** 提交；被拒按原因修改后重新打包保存、重新提交。

## 维护约定

- **一个 Agent 一个目录**（main），**一个 Agent 一个分支**（`agent-<slug>`，分支根 = 工程根）。
- 每个 Agent 的 README 必须写全：功能、权限、打包/预览命令、真机信息表、提审资料、预览截图（嵌入 `../screenshots/<slug>/…`）。
- 截图只放 `screenshots/<slug>/`；打包好的 `.aix` 只放仓库 `aix/` 目录，并与代码同步更新。
- GitHub 操作走终端 `gh` / `git`（已登录 sakai55），含二进制与分支维护。

## Agent 清单

全部 Agent 一览（持续增长中，新 Agent 完成即追加到表尾，表格按完成顺序排列，不按编号排序；表格已取消单独的编号列）。
每个 Agent 的真机状态、提审资料看它自己目录里的 README。

**徽章怎么读：每行一句话说明的末尾是一串徽章——编号徽章（深灰）在最前，然后是系列徽章，有冲突标记的再跟一个冲突徽章。**
编号 = 字母 + 数字：字母是它所属的系列 / 分组，数字是该组内的序号。**全表编号唯一：每个字母只属于一个系列，同一编号只出现一次**（基础项 `my-agent` / `glasses-benchmark` 不编号、无徽章）。

**徽章说明**（徽章串从左到右依次是：编号 → 系列 → 冲突）：

| 徽章 | 种类 | 含义 |
|---|---|---|
| ![Z01](https://img.shields.io/badge/Z01-24292F?style=flat-square) | 编号徽章（深灰） | 这个 Agent 的唯一编号（此处以 `Z01` 为例），字母 = 系列 / 分组，数字 = 组内序号；每行第一个徽章 |
| ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | 系列徽章（蓝） | 指向性系列：利用视线同轴、头部朝向等指向性能力解决生活问题（Z01–Z50） |
| ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | 系列徽章（紫） | 注意力外挂系列：把持续占用的注意力外包给眼镜（W/H/C/F/D/R/P/S/B/E 各 01–05） |
| ![路缘坡](https://img.shields.io/badge/%E8%B7%AF%E7%BC%98%E5%9D%A1-FF9800?style=flat-square) | 系列徽章（橙） | 路缘坡系列：先为一类特殊人群解决一个具体难题，再溢出到情境性障碍中的普通人（K01–K20） |
| ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | 系列徽章（绿） | 头部动作小游戏系列：用头部动作玩的极简小游戏（G01–G20） |
| ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | 冲突徽章（红） | 与眼镜默认能力**直接冲突**（冲突排查第一档，共 14 个）：本体就是默认能力，只加了一层小扭转 |
| ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | 冲突徽章（黄） | 与眼镜默认能力**高度重叠**（冲突排查第二档，共 40 个）：默认功能能完成大半，只剩一层薄闭环 |

没有冲突徽章 = 冲突排查第三档「不冲突」；基础项（`my-agent`、`glasses-benchmark`）没有任何徽章。
读例：`gaze-translate` 行尾的 ![Z01](https://img.shields.io/badge/Z01-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) = 编号 Z01 · 指向性系列 · 与默认能力直接冲突。

- **无字母（`—`）**：基础项，不属于任何系列——`my-agent` 是官方脚手架示例，`glasses-benchmark` 是眼镜全功能自检工具。
- **`Z01`–`Z50`**：**指向性系列**（50 个）——利用眼镜的视线同轴、头部朝向等指向性能力，一个 Agent 解决一个生活问题；`Z` 取「指向」拼音首字母（英文 Directional 的 `D` 已被注意力并行型占用，故不用 `D`），编号内部再分 A–J 十组生活场景。2026-10-25 由原纯数字 `01`–`50` 改为 Z 编号。
- **字母 + `01`–`05`**：**注意力外挂系列**（50 个，10 组 × 5）——把人原本要持续占用的注意力外包给眼镜，字母是外包类型的英文首字母：
  - `W` = **守望型 WATCH**：替你持续盯着一个信号（锅、叫号、门铃）
  - `H` = **默念型 HOLD**：替你记住要反复默念的号码、口令、清单、路线
  - `C` = **覆盖型 COVER**：替你证明「都看过了」，防漏检、漏扫、漏装
  - `F` = **过滤型 FILTER**：只放行你声明要的那类信息，其余挡住
  - `D` = **并行型 DUAL**：主线你做，副线（孩子、行李、排队号）它替你管
  - `R` = **回放型 REVIEW**：替你回答「刚才……」，事后按记录复盘
  - `P` = **提示型 CUE**：看向某个场景才触发对应的提醒（`C` 已被覆盖型占用，故用 `P`）
  - `S` = **社交型 SOCIAL**：替你分担待客、倾听、记人情的社交注意力
  - `B` = **身体型 BODY**：替你留意眼睛、喝水、呼吸、久坐等身体信号
  - `E` = **环境型 AMBIENT**：替你留意光线、天色、噪音等环境变化（取 Environment 的 `E`）
- **`K01`–`K20`**：**路缘坡系列**（20 个）——先为一类特殊人群解决一个具体难题，再溢出到处在情境性障碍中的普通人；`K` 取路缘的英式拼法 **Kerb**（Curb Cut 的 curb 英式拼作 kerb）。2026-10-25 由原 `C01`–`C20` 改为 K 编号——`C` 从此只属于注意力覆盖型，全表不再重号。
- **`G01`–`G20`**：**头部动作小游戏系列**（20 个，`G` = Game）——用头部动作玩的极简小游戏，含语音指导的颈部分段活动（只分段、必回正、不转圈）。

**冲突徽章**（据《眼镜默认能力冲突排查报告》2026-10-25，对照眼镜自带七项默认能力逐个排查；紧跟在系列徽章之后）：

- **直接冲突**（红，第一档，共 14 个）：本体就是默认能力（实时翻译 / 实时字幕 / 会议转写 / 提词器 / 慧眼读牌 / AR 导航 / AI 问答），只加了一层小扭转。报告建议停提审 / 下架，待裁决，尚未执行。
- **高度重叠**（黄，第二档，共 40 个）：默认功能问一句 / 开一下就能完成大半，只剩一层薄闭环，待逐簇裁决。
- **没有冲突徽章** = 第三档不冲突（已逐个核过，闭环是默认能力没有的）。

| Agent | 一句话说明 | 导入分支 |
|---|---|---|
| [my-agent](my-agent/) | 官方脚手架示例，点击切换中英文问候 | `agent-my-agent` |
| [glasses-benchmark](glasses-benchmark/) | 眼镜全功能自检，21 项一键跑完出结果 | `agent-glasses-benchmark` |
| [gaze-translate](gaze-translate/) | 看着外文稳头，长焦拍下翻译并朗读 ![Z01](https://img.shields.io/badge/Z01-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-gaze-translate` |
| [shelf-compare](shelf-compare/) | 扫货架条码入表比价，点头加入清单 ![Z02](https://img.shields.io/badge/Z02-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-shelf-compare` |
| [expiry-check](expiry-check/) | 读包装日期算剩余天数，临期语音警告 ![Z03](https://img.shields.io/badge/Z03-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-expiry-check` |
| [plant-doctor](plant-doctor/) | 拍照识植物状态，养护步骤语音领做 ![Z04](https://img.shields.io/badge/Z04-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-plant-doctor` |
| [manual-lens](manual-lens/) | 读铭牌故障码，给出下一步操作指引 ![Z05](https://img.shields.io/badge/Z05-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-manual-lens` |
| [head-nav](head-nav/) | 导航箭头跟着头转，对准方向才走 ![Z06](https://img.shields.io/badge/Z06-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-head-nav` |
| [find-my-thing](find-my-thing/) | 看向物品语音登记，回忆位置与朝向 ![Z07](https://img.shields.io/badge/Z07-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-find-my-thing` |
| [meet-point](meet-point/) | 共享定位，转头就能对准走散的朋友 ![Z08](https://img.shields.io/badge/Z08-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-meet-point` |
| [parking-return](parking-return/) | 存车位定位朝向，回程引导找车 ![Z09](https://img.shields.io/badge/Z09-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-parking-return` |
| [exit-radar](exit-radar/) | 环视登记出口方向，紧急时播报最近出口 ![Z10](https://img.shields.io/badge/Z10-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-exit-radar` |
| [cook-along](cook-along/) | 菜谱悬在眼前，点头翻步，油烟里只听你 ![Z11](https://img.shields.io/badge/Z11-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-cook-along` |
| [repair-buddy](repair-buddy/) | 拍故障部位分步指导，点头确认每步 ![Z12](https://img.shields.io/badge/Z12-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-repair-buddy` |
| [assemble-guide](assemble-guide/) | 对照图纸零件，按步引导组装纠错 ![Z13](https://img.shields.io/badge/Z13-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-assemble-guide` |
| [garden-hands](garden-hands/) | 看着植物给修剪浇水指示，免手操作 ![Z14](https://img.shields.io/badge/Z14-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-garden-hands` |
| [baby-care-hands](baby-care-hands/) | 抱娃免手语音问答，拍照问宝宝状态 ![Z15](https://img.shields.io/badge/Z15-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-baby-care-hands` |
| [sound-compass](sound-compass/) | 转头扫描声源方向，报出声音在哪边 ![Z16](https://img.shields.io/badge/Z16-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-sound-compass` |
| [far-ear](far-ear/) | 远场收音转实时字幕，听清远处人声 ![Z17](https://img.shields.io/badge/Z17-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-far-ear` |
| [cry-watch](cry-watch/) | 守听婴儿房动静，哭声立刻语音提醒 ![Z18](https://img.shields.io/badge/Z18-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-cry-watch` |
| [name-call](name-call/) | 听清谁在喊你，内容与方向一起报 ![Z19](https://img.shields.io/badge/Z19-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-name-call` |
| [ambient-captions](ambient-captions/) | 全向收音实时字幕，对准谁增强谁 ![Z20](https://img.shields.io/badge/Z20-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-ambient-captions` |
| [market-radar](market-radar/) | 按朝向登记摊位报价，转头亮价比价 ![Z21](https://img.shields.io/badge/Z21-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-market-radar` |
| [allergen-guard](allergen-guard/) | 读配料表查忌口成分，命中立刻警告 ![Z22](https://img.shields.io/badge/Z22-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-allergen-guard` |
| [fresh-pick](fresh-pick/) | 拍照判果蔬成熟新鲜，挑果有人指点 ![Z23](https://img.shields.io/badge/Z23-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-fresh-pick` |
| [outfit-check](outfit-check/) | 拍照评衣物搭配与场合，照镜再评上身 ![Z24](https://img.shields.io/badge/Z24-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-outfit-check` |
| [receipt-keeper](receipt-keeper/) | 看一眼小票入账，月度汇总语音播报 ![Z25](https://img.shields.io/badge/Z25-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-receipt-keeper` |
| [home-find](home-find/) | 收纳时登记位置，找东西报方位线索 ![Z26](https://img.shields.io/badge/Z26-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-home-find` |
| [meter-reader](meter-reader/) | 长焦读水电表数，自动记录比对异常 ![Z27](https://img.shields.io/badge/Z27-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-meter-reader` |
| [home-patrol](home-patrol/) | 出门巡检门窗燃气，逐项看过才放行 ![Z28](https://img.shields.io/badge/Z28-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-home-patrol` |
| [parcel-sort](parcel-sort/) | 扫快递单条码，按急缓语音分类堆放 ![Z29](https://img.shields.io/badge/Z29-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-parcel-sort` |
| [clean-check](clean-check/) | 环视登记打扫覆盖，漏扫角落提醒你 ![Z30](https://img.shields.io/badge/Z30-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-clean-check` |
| [med-look](med-look/) | 读药瓶标签对服药表，报剂量记已服 ![Z31](https://img.shields.io/badge/Z31-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-med-look` |
| [posture-guard](posture-guard/) | 测低头时长，久低头语音轻提醒 ![Z32](https://img.shields.io/badge/Z32-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-posture-guard` |
| [fall-guard](fall-guard/) | 跌倒无回应时，按预设联系紧急联系人 ![Z33](https://img.shields.io/badge/Z33-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-fall-guard` |
| [cross-street](cross-street/) | 过街前左右转头停稳，双确认才报可通行 ![Z34](https://img.shields.io/badge/Z34-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-cross-street` |
| [food-safe](food-safe/) | 看剩菜外观+登记日期给风险分级提示 ![Z35](https://img.shields.io/badge/Z35-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-food-safe` |
| [word-look](word-look/) | 看着生词说出来，释义发音进生词本 ![Z36](https://img.shields.io/badge/Z36-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-word-look` |
| [story-look](story-look/) | 绘本页拍照生成讲解词+提问，翻页续讲 ![Z37](https://img.shields.io/badge/Z37-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-story-look` |
| [memory-anchor](memory-anchor/) | 「刚才那个想法/待办」转头就忘 ![Z38](https://img.shields.io/badge/Z38-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-memory-anchor` |
| [board-capture](board-capture/) | 上课/开会黑板白板字远又擦得快 ![Z39](https://img.shields.io/badge/Z39-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-board-capture` |
| [homework-lens](homework-lens/) | 孩子题目不会，家长讲不清步骤 ![Z40](https://img.shields.io/badge/Z40-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-homework-lens` |
| [sign-reader](sign-reader/) | 站牌/登机口/菜单牌太远太小看不清 ![Z41](https://img.shields.io/badge/Z41-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-sign-reader` |
| [transit-direction](transit-direction/) | 出了地铁站转头校准方向，偏离语音纠正 ![Z42](https://img.shields.io/badge/Z42-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-transit-direction` |
| [hotel-checkin](hotel-checkin/) | 八检查点逐个看过打勾，漏看按方位领回 ![Z43](https://img.shields.io/badge/Z43-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-hotel-checkin` |
| [photo-level](photo-level/) | 取景叠三分法+气泡水平仪，点头快门 ![Z44](https://img.shields.io/badge/Z44-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-photo-level` |
| [queue-sense](queue-sense/) | 眼数人数镜测速度，估哪支队最快 ![Z45](https://img.shields.io/badge/Z45-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-queue-sense` |
| [speaker-focus](speaker-focus/) | 多人会议跟不上谁说话，纪要按朝向标人 ![Z46](https://img.shields.io/badge/Z46-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-speaker-focus` |
| [badge-reader](badge-reader/) | 看不清名牌忘了名字？长焦读牌悄悄报你听 ![Z47](https://img.shields.io/badge/Z47-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-badge-reader` |
| [teleprompter-gaze](teleprompter-gaze/) | 演讲/录视频忘词，低头看稿不自然 ![Z48](https://img.shields.io/badge/Z48-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-teleprompter-gaze` |
| [site-patrol](site-patrol/) | 工地/仓库巡检要逐项看、逐项记，双手拿工具 ![Z49](https://img.shields.io/badge/Z49-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | `agent-site-patrol` |
| [elder-day](elder-day/) | 独居老人一日清单：吃药喝水出门逐项确认 ![Z50](https://img.shields.io/badge/Z50-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-elder-day` |
| [stove-watch](stove-watch/) | 多锅看向登记计时，沸腾溢锅叫你回看 ![W01](https://img.shields.io/badge/W01-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-stove-watch` |
| [bath-watch](bath-watch/) | 浴缸放水登记守听，水满前叫你关水 ![W02](https://img.shields.io/badge/W02-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-bath-watch` |
| [laundry-watch](laundry-watch/) | 洗衣结束蜂鸣守听，第一时间叫你晾衣 ![W03](https://img.shields.io/badge/W03-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-laundry-watch` |
| [signal-watch](signal-watch/) | 医院/银行/取餐叫号，大屏节律提醒回看，差3号喊你准备 ![W04](https://img.shields.io/badge/W04-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-signal-watch` |
| [door-watch](door-watch/) | 里屋开会戴耳机，守听门铃敲门快递叫你回看 ![W05](https://img.shields.io/badge/W05-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-door-watch` |
| [number-catch](number-catch/) | 号码拍下放大核对，常驻视线内不用默念 ![H01](https://img.shields.io/badge/H01-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-number-catch` |
| [code-hold](code-hold/) | 临时码复述存住，要输入时逐段显示 ![H02](https://img.shields.io/badge/H02-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-code-hold` |
| [voice-list](voice-list/) | 复述成清单挂在视线里，看向货架逐项点头勾掉 ![H03](https://img.shields.io/badge/H03-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-voice-list` |
| [route-hold](route-hold/) | 复述问路线路存步骤，走时只显示当前一步点头前进 ![H04](https://img.shields.io/badge/H04-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-route-hold` |
| [seat-catch](seat-catch/) | 拍票根存座位号，逐排逐座只报相对差 ![H05](https://img.shields.io/badge/H05-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-seat-catch` |
| [drop-search](drop-search/) | 掉落小物脚边 6 区逐区手摸，查完才报没找到 ![K01](https://img.shields.io/badge/K01-24292F?style=flat-square) ![路缘坡](https://img.shields.io/badge/%E8%B7%AF%E7%BC%98%E5%9D%A1-FF9800?style=flat-square) | `agent-drop-search` |
| [last-glance](last-glance/) | 离开前环视存档最后画面，焦虑时按区回放 ![C01](https://img.shields.io/badge/C01-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-last-glance` |
| [room-sweep](room-sweep/) | 睡前逐项巡房确认打勾，漏项按方位提醒补看 ![C02](https://img.shields.io/badge/C02-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-room-sweep` |
| [proof-sweep](proof-sweep/) | 逐行指读记进度，跳行漏段当场提醒给覆盖率 ![C03](https://img.shields.io/badge/C03-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-proof-sweep` |
| [pack-sweep](pack-sweep/) | 清单逐件看向登记，出门前点名没装的那几件 ![C04](https://img.shields.io/badge/C04-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-pack-sweep` |
| [shelf-sweep](shelf-sweep/) | 货架分层分段记已扫格，没扫的格点名提醒 ![C05](https://img.shields.io/badge/C05-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-shelf-sweep` |
| [focus-shield](focus-shield/) | 只放行白名单声音，其余只记时间线休息时摘要 ![F01](https://img.shields.io/badge/F01-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-focus-shield` |
| [sign-filter](sign-filter/) | 先声明目标，扫街只亮匹配的牌 ![F02](https://img.shields.io/badge/F02-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-sign-filter` |
| [buy-filter](buy-filter/) | 清单预算忌口三条件，只亮符合商品 ![F03](https://img.shields.io/badge/F03-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-buy-filter` |
| [meeting-filter](meeting-filter/) | 守听长会，命中名字关键词才亮屏 ![F04](https://img.shields.io/badge/F04-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-meeting-filter` |
| [lecture-filter](lecture-filter/) | 守听课堂，信号句命中即存笔记 ![F05](https://img.shields.io/badge/F05-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-lecture-filter` |
| [play-watch](play-watch/) | 游乐场副线定时提醒回看，未确认逐级升级 ![D01](https://img.shields.io/badge/D01-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-play-watch` |
| [bag-watch](bag-watch/) | 行李副线定时提醒回看，离开门未确认喊停 ![D02](https://img.shields.io/badge/D02-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-bag-watch` |
| [dog-walk](dog-walk/) | 遛狗副线狗停当场定性，回家门逐项核对才放行 ![D03](https://img.shields.io/badge/D03-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-dog-walk` |
| [tour-watch](tour-watch/) | 跟团副线只捞集合句，快到点按朝向提醒归队 ![D04](https://img.shields.io/badge/D04-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-tour-watch` |
| [queue-roam](queue-roam/) | 取号副线守听叫号，距5号内叫你回去等着 ![D05](https://img.shields.io/badge/D05-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-queue-roam` |
| [day-lookback](day-lookback/) | 白天凝视按时间朝向排线，晚上顺线复盘 ![R01](https://img.shields.io/badge/R01-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-day-lookback` |
| [talk-replay](talk-replay/) | 谈话字幕按说话方朝向，回放只列承诺数字期限 ![R02](https://img.shields.io/badge/R02-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-talk-replay` |
| [shop-replay](shop-replay/) | 犹豫商品按店面朝向存档，回放比价钉最便宜 ![R03](https://img.shields.io/badge/R03-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-shop-replay` |
| [route-replay](route-replay/) | 路上登记危险点，次日出门按序预告 ![R04](https://img.shields.io/badge/R04-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-route-replay` |
| [attention-diary](attention-diary/) | 一天注意力被谁偷走，一张账单说清 ![R05](https://img.shields.io/badge/R05-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-attention-diary` |
| [cue-door](cue-door/) | 看向大门触发清单，逐项确认全过才放行 ![P01](https://img.shields.io/badge/P01-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-cue-door` |
| [cue-fridge](cue-fridge/) | 看向冰箱触发清单，拿一样勾一样关门报漏拿 ![P02](https://img.shields.io/badge/P02-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-cue-fridge` |
| [cue-desk](cue-desk/) | 看向书桌亮今日三件事，起身按未完成给续接句 ![P03](https://img.shields.io/badge/P03-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-cue-desk` |
| [cue-bag](cue-bag/) | 看向要背的包触发清单，逐项看向格层确认装入 ![P04](https://img.shields.io/badge/P04-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-cue-bag` |
| [cue-mirror](cue-mirror/) | 看向镜子亮三行，逐行确认已读，提前结束报未读 ![P05](https://img.shields.io/badge/P05-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-cue-mirror` |
| [chat-catchup](chat-catchup/) | 谈话走神摇头求助，眼前给最近15秒要点摘要 ![S01](https://img.shields.io/badge/S01-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-chat-catchup` |
| [my-bus-watch](my-bus-watch/) | 只守登记的一路公交，拍车头核线路号报上车与否 ![K02](https://img.shields.io/badge/K02-24292F?style=flat-square) ![路缘坡](https://img.shields.io/badge/%E8%B7%AF%E7%BC%98%E5%9D%A1-FF9800?style=flat-square) | `agent-my-bus-watch` |
| [guest-watch](guest-watch/) | 客人逐位看向登记座位，定时提醒回看茶水位 ![S02](https://img.shields.io/badge/S02-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-guest-watch` |
| [elder-ear](elder-ear/) | 守听老人聊天，叮嘱句存清单聊完复述 ![S03](https://img.shields.io/badge/S03-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-elder-ear` |
| [standup-echo](standup-echo/) | 守听站会只亮关联句，未命中默记摘要会后查 ![S04](https://img.shields.io/badge/S04-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | `agent-standup-echo` |
| [gift-clue](gift-clue/) | 日常聊天默记想要句成线索卡，按人回放 ![S05](https://img.shields.io/badge/S05-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | `agent-gift-clue` |
| [eye-rest](eye-rest/) | 头稳凝视近处满20分钟提醒远眺，抬头确认 ![B01](https://img.shields.io/badge/B01-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-eye-rest` |
| [nod-count](nod-count/) | 语音指导10次慢速点头，低头回正算一次 ![G01](https://img.shields.io/badge/G01-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-nod-count` |
| [turn-count](turn-count/) | 语音指导左右转头交替，各5次满10次 ![G02](https://img.shields.io/badge/G02-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-turn-count` |
| [water-watch](water-watch/) | 久未看向水杯亮屏提醒喝水，凝视确认 ![B02](https://img.shields.io/badge/B02-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-water-watch` |
| [ear-tilt](ear-tilt/) | 左右贴耳各3次，稳住5秒才算一次 ![G03](https://img.shields.io/badge/G03-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-ear-tilt` |
| [stretch-hold](stretch-hold/) | 仰头低头交替拉伸，各保持5秒各3次 ![G04](https://img.shields.io/badge/G04-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-stretch-hold` |
| [breath-pace](breath-pace/) | 视线内呼吸节拍光点，跟着看就行 ![B03](https://img.shields.io/badge/B03-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-breath-pace` |
| [neck-clock](neck-clock/) | 按报出的时钟点位转头，每点必回正 ![G05](https://img.shields.io/badge/G05-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-neck-clock` |
| [stand-move](stand-move/) | 久坐超阈值提醒起身，环视一圈作确认 ![B04](https://img.shields.io/badge/B04-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-stand-move` |
| [chin-tuck](chin-tuck/) | 下巴小幅后收保持5秒，8次收下巴操 ![G06](https://img.shields.io/badge/G06-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-chin-tuck` |
| [snack-aware](snack-aware/) | 看向零食先亮今天第几次，吃不吃你决定 ![B05](https://img.shields.io/badge/B05-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-snack-aware` |
| [steady-hold](steady-hold/) | 头稳住不动满10秒胜，动了重计 ![G07](https://img.shields.io/badge/G07-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-steady-hold` |
| [light-change](light-change/) | 相机定时测光，光线暗了提醒开灯 ![E01](https://img.shields.io/badge/E01-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-light-change` |
| [nod-catch](nod-catch/) | 10 个球下落，点头踩线接住计分 ![G08](https://img.shields.io/badge/G08-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-nod-catch` |
| [sky-watch](sky-watch/) | 登记晾晒区，定时回看天空云变预警 ![E02](https://img.shields.io/badge/E02-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-sky-watch` |
| [turn-dodge](turn-dodge/) | 障碍在左向右躲，10 回合回正计分 ![G09](https://img.shields.io/badge/G09-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-turn-dodge` |
| [follow-dot](follow-dot/) | 光点跳到哪就跟到哪，停稳算中 ![G10](https://img.shields.io/badge/G10-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-follow-dot` |
| [noise-map](noise-map/) | 转头扫 8 方向，报最安静的朝向 ![E03](https://img.shields.io/badge/E03-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-noise-map` |
| [rhythm-nod](rhythm-nod/) | 16 拍固定节拍，拍点点头打中计分 ![G11](https://img.shields.io/badge/G11-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-rhythm-nod` |
| [trail-back](trail-back/) | 沿途登记路口面包屑，返程反向逐点领回 ![E04](https://img.shields.io/badge/E04-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-trail-back` |
| [memory-seq](memory-seq/) | 语音报出方向序列，记住并依次复现 ![G12](https://img.shields.io/badge/G12-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-memory-seq` |
| [tomorrow-stage](tomorrow-stage/) | 睡前登记明早要用的物品，出门逐项确认带齐 ![E05](https://img.shields.io/badge/E05-24292F?style=flat-square) ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | `agent-tomorrow-stage` |
| [find-target](find-target/) | 语音报方向，转过去停稳算找到 ![G13](https://img.shields.io/badge/G13-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-find-target` |
| [level-keep](level-keep/) | 头端平保持水平，歪了小球偏，满10秒胜 ![G14](https://img.shields.io/badge/G14-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-level-keep` |
| [slow-scan](slow-scan/) | 从左到右慢速扫一遍，太快语音纠偏 ![G15](https://img.shields.io/badge/G15-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-slow-scan` |
| [nod-quiz](nod-quiz/) | 是非题点头答是，侧转停稳答否计分 ![G16](https://img.shields.io/badge/G16-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-nod-quiz` |
| [breathe-turn](breathe-turn/) | 吸气慢慢转头，呼气慢慢回正，左右各3次 ![G17](https://img.shields.io/badge/G17-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-breathe-turn` |
| [guess-direction](guess-direction/) | 猜保密方向，语音报近了远了，转到算中 ![G18](https://img.shields.io/badge/G18-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-guess-direction` |
| [traffic-light](traffic-light/) | 绿灯转向报出的方向，红灯稳住不动 ![G19](https://img.shields.io/badge/G19-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-traffic-light` |
| [daily-routine](daily-routine/) | 点头转头贴耳仰低收下巴，一套2分钟走完 ![G20](https://img.shields.io/badge/G20-24292F?style=flat-square) ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | `agent-daily-routine` |