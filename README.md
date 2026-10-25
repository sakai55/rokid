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
├── <分类>/<slug>/             # Agent 按编号分类存放，映射见文末清单说明
│   └── <slug>/                # 一个 Agent 一个目录（一套完整 AIUI 工程）
│       ├── app.json  AGENTS.md  app.js  package.json
│       ├── pages/             # .ink 页面
│       └── README.md          # 开头 Studio 导入块 + 真机信息表 + 提审资料（以它为准）
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

1. **本地开发** — 在 `<分类>/<slug>/` 目录里开发、改页面。
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
| ✅ `…/tree/agent-<slug>` | **唯一可用**：导入该分支根目录 = 一个完整 Agent，文件树完整；已实测可运行、可打包 |
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

不依赖 GitHub 地址解析，赶时间或 GitHub 导入异常时用它；日常首选分支法。

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
| 手机 App | **Hi Rokid**（包名 `com.rokid.sprite.global.aiapp`） | 国内版 Rokid Ai App |

## 真机测试（云端下发）

<details>
<summary><b>展开完整步骤</b></summary>

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

真机测试全部通过、维护者确认「真机测试完成」后：

1. 在 **Submit** 页签填 **Review Information**：Feature Description、Opening Message、
   Preview Media、Change Log。**四项成稿在各 Agent 自己 README 的「提审资料
   (Review Submission)」章节里，分段写好，整段复制**：Feature Description ≤500 字，
   Opening Message ≤500 字、支持 Markdown，Preview Media 3–5 个文件、≥1 图 ≥1 视频。
2. 权限声明与代码一致；可用权限只有 `GEOLOCATION`、`CAMERA`、`RECORD_AUDIO` 三种。
3. **Submit for Review** 提交；被拒按原因修改后重新打包保存、重新提交。

## 维护约定

- **一个 Agent 一个目录**：main 上按编号放进英文分类目录；**一个 Agent 一个分支**：`agent-<slug>`，分支根 = 工程根。
- 每个 Agent 的 README 必须写全：功能、权限、打包/预览命令、真机信息表、提审资料、预览截图，截图嵌入路径 `../../screenshots/<slug>/…`。
- 截图只放 `screenshots/<slug>/`；打包好的 `.aix` 只放仓库 `aix/` 目录，并与代码同步更新。
- GitHub 操作走终端 `gh` / `git`，含二进制与分支维护。

## Agent 清单

全部 Agent 一览，按完成顺序排列，新 Agent 完成即追加到表尾。
每个 Agent 的真机状态、提审资料看它自己目录里的 README。

**徽章怎么读：每行第三列是徽章，从左到右依次是编号徽章、系列徽章、冲突状态徽章（冲突状态三选一：直接冲突 / 高度重叠 / 待测试）。**
编号 = 2 个字母 + 2 位数字：字母取分类英文名的前两个字母，数字是组内序号。**全表编号唯一：每个字母只属于一个系列，同一编号只出现一次**（基础项 `my-agent` / `glasses-benchmark` 不编号、无徽章）。

**徽章说明**：

| 徽章 | 种类 | 含义 |
|---|---|---|
| ![DI01](https://img.shields.io/badge/DI01-24292F?style=flat-square) | 编号徽章 | 这个 Agent 的唯一编号，前两个字母 = 分类，后两位数字 = 组内序号 |
| ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) | 系列徽章 | 指向性系列：利用视线同轴、头部朝向等指向性能力解决生活问题（DI01–DI50） |
| ![注意力](https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square) | 系列徽章 | 注意力外挂系列：把持续占用的注意力外包给眼镜（WA/HO/CO/FI/DU/RE/CU/SO/BO/AM 各 01–05） |
| ![路缘坡](https://img.shields.io/badge/%E8%B7%AF%E7%BC%98%E5%9D%A1-FF9800?style=flat-square) | 系列徽章 | 路缘坡系列：先为一类特殊人群解决一个具体难题，再溢出到情境性障碍中的普通人（CC01–CC20） |
| ![游戏](https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square) | 系列徽章 | 头部动作小游戏系列：用头部动作玩的极简小游戏（GA01–GA20） |
| ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) | 冲突状态徽章 | 与眼镜默认能力**直接冲突**（冲突排查第一档，共 14 个）：本体就是默认能力，只加了一层小扭转 |
| ![高度重叠](https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square) | 冲突状态徽章 | 与眼镜默认能力**高度重叠**（冲突排查第二档，共 40 个）：默认功能能完成大半，只剩一层薄闭环 |
| ![待测试](https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square) | 冲突状态徽章 | 既不直接冲突、也不高度重叠的 Agent 都是**待测试**（共 68 个），冲突与否等真机测试确认 |

基础项（`my-agent`、`glasses-benchmark`）没有任何徽章。
读例：`gaze-translate` 行尾的 ![DI01](https://img.shields.io/badge/DI01-24292F?style=flat-square) ![指向性](https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square) ![直接冲突](https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square) = 编号 DI01 · 指向性系列 · 与默认能力直接冲突；`drop-search` 行尾的 ![CC01](https://img.shields.io/badge/CC01-24292F?style=flat-square) ![路缘坡](https://img.shields.io/badge/%E8%B7%AF%E7%BC%98%E5%9D%A1-FF9800?style=flat-square) ![待测试](https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square) = 编号 CC01 · 路缘坡系列 · 冲突与否待测试。

- **无字母（`—`）**：基础项，不属于任何系列——`my-agent` 是官方脚手架示例，`glasses-benchmark` 是眼镜全功能自检工具。目录：`base/`
- **`DI01`–`DI50`**：**指向性系列**（50 个）——利用眼镜的视线同轴、头部朝向等指向性能力，一个 Agent 解决一个生活问题；编号取 Directional 的前两个字母，内部再分 A–J 十组生活场景。目录：`directional/`
- **双字母 + `01`–`05`**：**注意力外挂系列**（50 个，10 组 × 5）——把人原本要持续占用的注意力外包给眼镜，字母取外包类型英文名的前两个字母：
  - `WA` = **守望型 WATCH**：替你持续盯着一个信号（锅、叫号、门铃），目录 `watch/`
  - `HO` = **默念型 HOLD**：替你记住要反复默念的号码、口令、清单、路线，目录 `hold/`
  - `CO` = **覆盖型 COVER**：替你证明「都看过了」，防漏检、漏扫、漏装，目录 `cover/`
  - `FI` = **过滤型 FILTER**：只放行你声明要的那类信息，其余挡住，目录 `filter/`
  - `DU` = **并行型 DUAL**：主线你做，副线（孩子、行李、排队号）它替你管，目录 `dual/`
  - `RE` = **回放型 REVIEW**：替你回答「刚才……」，事后按记录复盘，目录 `review/`
  - `CU` = **提示型 CUE**：看向某个场景才触发对应的提醒，目录 `cue/`
  - `SO` = **社交型 SOCIAL**：替你分担待客、倾听、记人情的社交注意力，目录 `social/`
  - `BO` = **身体型 BODY**：替你留意眼睛、喝水、呼吸、久坐等身体信号，目录 `body/`
  - `AM` = **环境型 AMBIENT**：替你留意光线、天色、噪音等环境变化，目录 `ambient/`
- **`CC01`–`CC20`**：**路缘坡系列**（20 个）——先为一类特殊人群解决一个具体难题，再溢出到处在情境性障碍中的普通人；编号取 Curb Cut 的首字母 **CC**。目录：`curb-cut/`
- **`GA01`–`GA20`**：**头部动作小游戏系列**（20 个，编号取 Game 的前两个字母）——用头部动作玩的极简小游戏，含语音指导的颈部分段活动（只分段、必回正、不转圈）。目录：`games/`

编号沿革（2026-10-25）：指向性纯数字 → Z → DI，路缘坡 C → K → CC，注意力与游戏由单字母扩为双字母；现行编号一律双字母 + 两位数字。

<table>
<tr><td><a href="base/my-agent/">my-agent</a></td><td>官方脚手架示例，点击切换中英文问候</td><td></td></tr>
<tr><td><a href="base/glasses-benchmark/">glasses-benchmark</a></td><td>眼镜全功能自检，21 项一键跑完出结果</td><td></td></tr>
<tr><td><a href="directional/gaze-translate/">gaze-translate</a></td><td>看着外文稳头，长焦拍下翻译并朗读</td><td><img src="https://img.shields.io/badge/DI01-24292F?style=flat-square" alt="DI01"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="directional/shelf-compare/">shelf-compare</a></td><td>扫货架条码入表比价，点头加入清单</td><td><img src="https://img.shields.io/badge/DI02-24292F?style=flat-square" alt="DI02"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/expiry-check/">expiry-check</a></td><td>读包装日期算剩余天数，临期语音警告</td><td><img src="https://img.shields.io/badge/DI03-24292F?style=flat-square" alt="DI03"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/plant-doctor/">plant-doctor</a></td><td>拍照识植物状态，养护步骤语音领做</td><td><img src="https://img.shields.io/badge/DI04-24292F?style=flat-square" alt="DI04"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/manual-lens/">manual-lens</a></td><td>读铭牌故障码，给出下一步操作指引</td><td><img src="https://img.shields.io/badge/DI05-24292F?style=flat-square" alt="DI05"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/head-nav/">head-nav</a></td><td>导航箭头跟着头转，对准方向才走</td><td><img src="https://img.shields.io/badge/DI06-24292F?style=flat-square" alt="DI06"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="directional/find-my-thing/">find-my-thing</a></td><td>看向物品语音登记，回忆位置与朝向</td><td><img src="https://img.shields.io/badge/DI07-24292F?style=flat-square" alt="DI07"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/meet-point/">meet-point</a></td><td>共享定位，转头就能对准走散的朋友</td><td><img src="https://img.shields.io/badge/DI08-24292F?style=flat-square" alt="DI08"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/parking-return/">parking-return</a></td><td>存车位定位朝向，回程引导找车</td><td><img src="https://img.shields.io/badge/DI09-24292F?style=flat-square" alt="DI09"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="directional/exit-radar/">exit-radar</a></td><td>环视登记出口方向，紧急时播报最近出口</td><td><img src="https://img.shields.io/badge/DI10-24292F?style=flat-square" alt="DI10"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/cook-along/">cook-along</a></td><td>菜谱悬在眼前，点头翻步，油烟里只听你</td><td><img src="https://img.shields.io/badge/DI11-24292F?style=flat-square" alt="DI11"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/repair-buddy/">repair-buddy</a></td><td>拍故障部位分步指导，点头确认每步</td><td><img src="https://img.shields.io/badge/DI12-24292F?style=flat-square" alt="DI12"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/assemble-guide/">assemble-guide</a></td><td>对照图纸零件，按步引导组装纠错</td><td><img src="https://img.shields.io/badge/DI13-24292F?style=flat-square" alt="DI13"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/garden-hands/">garden-hands</a></td><td>看着植物给修剪浇水指示，免手操作</td><td><img src="https://img.shields.io/badge/DI14-24292F?style=flat-square" alt="DI14"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/baby-care-hands/">baby-care-hands</a></td><td>抱娃免手语音问答，拍照问宝宝状态</td><td><img src="https://img.shields.io/badge/DI15-24292F?style=flat-square" alt="DI15"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="directional/sound-compass/">sound-compass</a></td><td>转头扫描声源方向，报出声音在哪边</td><td><img src="https://img.shields.io/badge/DI16-24292F?style=flat-square" alt="DI16"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/far-ear/">far-ear</a></td><td>远场收音转实时字幕，听清远处人声</td><td><img src="https://img.shields.io/badge/DI17-24292F?style=flat-square" alt="DI17"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="directional/cry-watch/">cry-watch</a></td><td>守听婴儿房动静，哭声立刻语音提醒</td><td><img src="https://img.shields.io/badge/DI18-24292F?style=flat-square" alt="DI18"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/name-call/">name-call</a></td><td>听清谁在喊你，内容与方向一起报</td><td><img src="https://img.shields.io/badge/DI19-24292F?style=flat-square" alt="DI19"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/ambient-captions/">ambient-captions</a></td><td>全向收音实时字幕，对准谁增强谁</td><td><img src="https://img.shields.io/badge/DI20-24292F?style=flat-square" alt="DI20"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="directional/market-radar/">market-radar</a></td><td>按朝向登记摊位报价，转头亮价比价</td><td><img src="https://img.shields.io/badge/DI21-24292F?style=flat-square" alt="DI21"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/allergen-guard/">allergen-guard</a></td><td>读配料表查忌口成分，命中立刻警告</td><td><img src="https://img.shields.io/badge/DI22-24292F?style=flat-square" alt="DI22"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/fresh-pick/">fresh-pick</a></td><td>拍照判果蔬成熟新鲜，挑果有人指点</td><td><img src="https://img.shields.io/badge/DI23-24292F?style=flat-square" alt="DI23"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/outfit-check/">outfit-check</a></td><td>拍照评衣物搭配与场合，照镜再评上身</td><td><img src="https://img.shields.io/badge/DI24-24292F?style=flat-square" alt="DI24"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/receipt-keeper/">receipt-keeper</a></td><td>看一眼小票入账，月度汇总语音播报</td><td><img src="https://img.shields.io/badge/DI25-24292F?style=flat-square" alt="DI25"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/home-find/">home-find</a></td><td>收纳时登记位置，找东西报方位线索</td><td><img src="https://img.shields.io/badge/DI26-24292F?style=flat-square" alt="DI26"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/meter-reader/">meter-reader</a></td><td>长焦读水电表数，自动记录比对异常</td><td><img src="https://img.shields.io/badge/DI27-24292F?style=flat-square" alt="DI27"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/home-patrol/">home-patrol</a></td><td>出门巡检门窗燃气，逐项看过才放行</td><td><img src="https://img.shields.io/badge/DI28-24292F?style=flat-square" alt="DI28"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/parcel-sort/">parcel-sort</a></td><td>扫快递单条码，按急缓语音分类堆放</td><td><img src="https://img.shields.io/badge/DI29-24292F?style=flat-square" alt="DI29"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/clean-check/">clean-check</a></td><td>环视登记打扫覆盖，漏扫角落提醒你</td><td><img src="https://img.shields.io/badge/DI30-24292F?style=flat-square" alt="DI30"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/med-look/">med-look</a></td><td>读药瓶标签对服药表，报剂量记已服</td><td><img src="https://img.shields.io/badge/DI31-24292F?style=flat-square" alt="DI31"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/posture-guard/">posture-guard</a></td><td>测低头时长，久低头语音轻提醒</td><td><img src="https://img.shields.io/badge/DI32-24292F?style=flat-square" alt="DI32"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/fall-guard/">fall-guard</a></td><td>跌倒无回应时，按预设联系紧急联系人</td><td><img src="https://img.shields.io/badge/DI33-24292F?style=flat-square" alt="DI33"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/cross-street/">cross-street</a></td><td>过街前左右转头停稳，双确认才报可通行</td><td><img src="https://img.shields.io/badge/DI34-24292F?style=flat-square" alt="DI34"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/food-safe/">food-safe</a></td><td>看剩菜外观+登记日期给风险分级提示</td><td><img src="https://img.shields.io/badge/DI35-24292F?style=flat-square" alt="DI35"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/word-look/">word-look</a></td><td>看着生词说出来，释义发音进生词本</td><td><img src="https://img.shields.io/badge/DI36-24292F?style=flat-square" alt="DI36"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/story-look/">story-look</a></td><td>绘本页拍照生成讲解词+提问，翻页续讲</td><td><img src="https://img.shields.io/badge/DI37-24292F?style=flat-square" alt="DI37"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/memory-anchor/">memory-anchor</a></td><td>「刚才那个想法/待办」转头就忘</td><td><img src="https://img.shields.io/badge/DI38-24292F?style=flat-square" alt="DI38"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/board-capture/">board-capture</a></td><td>上课/开会黑板白板字远又擦得快</td><td><img src="https://img.shields.io/badge/DI39-24292F?style=flat-square" alt="DI39"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/homework-lens/">homework-lens</a></td><td>孩子题目不会，家长讲不清步骤</td><td><img src="https://img.shields.io/badge/DI40-24292F?style=flat-square" alt="DI40"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/sign-reader/">sign-reader</a></td><td>站牌/登机口/菜单牌太远太小看不清</td><td><img src="https://img.shields.io/badge/DI41-24292F?style=flat-square" alt="DI41"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="directional/transit-direction/">transit-direction</a></td><td>出了地铁站转头校准方向，偏离语音纠正</td><td><img src="https://img.shields.io/badge/DI42-24292F?style=flat-square" alt="DI42"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="directional/hotel-checkin/">hotel-checkin</a></td><td>八检查点逐个看过打勾，漏看按方位领回</td><td><img src="https://img.shields.io/badge/DI43-24292F?style=flat-square" alt="DI43"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/photo-level/">photo-level</a></td><td>取景叠三分法+气泡水平仪，点头快门</td><td><img src="https://img.shields.io/badge/DI44-24292F?style=flat-square" alt="DI44"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/queue-sense/">queue-sense</a></td><td>眼数人数镜测速度，估哪支队最快</td><td><img src="https://img.shields.io/badge/DI45-24292F?style=flat-square" alt="DI45"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/speaker-focus/">speaker-focus</a></td><td>多人会议跟不上谁说话，纪要按朝向标人</td><td><img src="https://img.shields.io/badge/DI46-24292F?style=flat-square" alt="DI46"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="directional/badge-reader/">badge-reader</a></td><td>看不清名牌忘了名字？长焦读牌悄悄报你听</td><td><img src="https://img.shields.io/badge/DI47-24292F?style=flat-square" alt="DI47"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="directional/teleprompter-gaze/">teleprompter-gaze</a></td><td>演讲/录视频忘词，低头看稿不自然</td><td><img src="https://img.shields.io/badge/DI48-24292F?style=flat-square" alt="DI48"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="directional/site-patrol/">site-patrol</a></td><td>工地/仓库巡检要逐项看、逐项记，双手拿工具</td><td><img src="https://img.shields.io/badge/DI49-24292F?style=flat-square" alt="DI49"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="directional/elder-day/">elder-day</a></td><td>独居老人一日清单：吃药喝水出门逐项确认</td><td><img src="https://img.shields.io/badge/DI50-24292F?style=flat-square" alt="DI50"> <img src="https://img.shields.io/badge/%E6%8C%87%E5%90%91%E6%80%A7-2196F3?style=flat-square" alt="指向性"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="watch/stove-watch/">stove-watch</a></td><td>多锅看向登记计时，沸腾溢锅叫你回看</td><td><img src="https://img.shields.io/badge/WA01-24292F?style=flat-square" alt="WA01"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="watch/bath-watch/">bath-watch</a></td><td>浴缸放水登记守听，水满前叫你关水</td><td><img src="https://img.shields.io/badge/WA02-24292F?style=flat-square" alt="WA02"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="watch/laundry-watch/">laundry-watch</a></td><td>洗衣结束蜂鸣守听，第一时间叫你晾衣</td><td><img src="https://img.shields.io/badge/WA03-24292F?style=flat-square" alt="WA03"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="watch/signal-watch/">signal-watch</a></td><td>医院/银行/取餐叫号，大屏节律提醒回看，差3号喊你准备</td><td><img src="https://img.shields.io/badge/WA04-24292F?style=flat-square" alt="WA04"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="watch/door-watch/">door-watch</a></td><td>里屋开会戴耳机，守听门铃敲门快递叫你回看</td><td><img src="https://img.shields.io/badge/WA05-24292F?style=flat-square" alt="WA05"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="hold/number-catch/">number-catch</a></td><td>号码拍下放大核对，常驻视线内不用默念</td><td><img src="https://img.shields.io/badge/HO01-24292F?style=flat-square" alt="HO01"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="hold/code-hold/">code-hold</a></td><td>临时码复述存住，要输入时逐段显示</td><td><img src="https://img.shields.io/badge/HO02-24292F?style=flat-square" alt="HO02"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="hold/voice-list/">voice-list</a></td><td>复述成清单挂在视线里，看向货架逐项点头勾掉</td><td><img src="https://img.shields.io/badge/HO03-24292F?style=flat-square" alt="HO03"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="hold/route-hold/">route-hold</a></td><td>复述问路线路存步骤，走时只显示当前一步点头前进</td><td><img src="https://img.shields.io/badge/HO04-24292F?style=flat-square" alt="HO04"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="hold/seat-catch/">seat-catch</a></td><td>拍票根存座位号，逐排逐座只报相对差</td><td><img src="https://img.shields.io/badge/HO05-24292F?style=flat-square" alt="HO05"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="curb-cut/drop-search/">drop-search</a></td><td>掉落小物脚边 6 区逐区手摸，查完才报没找到</td><td><img src="https://img.shields.io/badge/CC01-24292F?style=flat-square" alt="CC01"> <img src="https://img.shields.io/badge/%E8%B7%AF%E7%BC%98%E5%9D%A1-FF9800?style=flat-square" alt="路缘坡"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="cover/last-glance/">last-glance</a></td><td>离开前环视存档最后画面，焦虑时按区回放</td><td><img src="https://img.shields.io/badge/CO01-24292F?style=flat-square" alt="CO01"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="cover/room-sweep/">room-sweep</a></td><td>睡前逐项巡房确认打勾，漏项按方位提醒补看</td><td><img src="https://img.shields.io/badge/CO02-24292F?style=flat-square" alt="CO02"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="cover/proof-sweep/">proof-sweep</a></td><td>逐行指读记进度，跳行漏段当场提醒给覆盖率</td><td><img src="https://img.shields.io/badge/CO03-24292F?style=flat-square" alt="CO03"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="cover/pack-sweep/">pack-sweep</a></td><td>清单逐件看向登记，出门前点名没装的那几件</td><td><img src="https://img.shields.io/badge/CO04-24292F?style=flat-square" alt="CO04"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="cover/shelf-sweep/">shelf-sweep</a></td><td>货架分层分段记已扫格，没扫的格点名提醒</td><td><img src="https://img.shields.io/badge/CO05-24292F?style=flat-square" alt="CO05"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="filter/focus-shield/">focus-shield</a></td><td>只放行白名单声音，其余只记时间线休息时摘要</td><td><img src="https://img.shields.io/badge/FI01-24292F?style=flat-square" alt="FI01"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="filter/sign-filter/">sign-filter</a></td><td>先声明目标，扫街只亮匹配的牌</td><td><img src="https://img.shields.io/badge/FI02-24292F?style=flat-square" alt="FI02"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="filter/buy-filter/">buy-filter</a></td><td>清单预算忌口三条件，只亮符合商品</td><td><img src="https://img.shields.io/badge/FI03-24292F?style=flat-square" alt="FI03"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="filter/meeting-filter/">meeting-filter</a></td><td>守听长会，命中名字关键词才亮屏</td><td><img src="https://img.shields.io/badge/FI04-24292F?style=flat-square" alt="FI04"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="filter/lecture-filter/">lecture-filter</a></td><td>守听课堂，信号句命中即存笔记</td><td><img src="https://img.shields.io/badge/FI05-24292F?style=flat-square" alt="FI05"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="dual/play-watch/">play-watch</a></td><td>游乐场副线定时提醒回看，未确认逐级升级</td><td><img src="https://img.shields.io/badge/DU01-24292F?style=flat-square" alt="DU01"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="dual/bag-watch/">bag-watch</a></td><td>行李副线定时提醒回看，离开门未确认喊停</td><td><img src="https://img.shields.io/badge/DU02-24292F?style=flat-square" alt="DU02"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="dual/dog-walk/">dog-walk</a></td><td>遛狗副线狗停当场定性，回家门逐项核对才放行</td><td><img src="https://img.shields.io/badge/DU03-24292F?style=flat-square" alt="DU03"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="dual/tour-watch/">tour-watch</a></td><td>跟团副线只捞集合句，快到点按朝向提醒归队</td><td><img src="https://img.shields.io/badge/DU04-24292F?style=flat-square" alt="DU04"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="dual/queue-roam/">queue-roam</a></td><td>取号副线守听叫号，距5号内叫你回去等着</td><td><img src="https://img.shields.io/badge/DU05-24292F?style=flat-square" alt="DU05"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="review/day-lookback/">day-lookback</a></td><td>白天凝视按时间朝向排线，晚上顺线复盘</td><td><img src="https://img.shields.io/badge/RE01-24292F?style=flat-square" alt="RE01"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="review/talk-replay/">talk-replay</a></td><td>谈话字幕按说话方朝向，回放只列承诺数字期限</td><td><img src="https://img.shields.io/badge/RE02-24292F?style=flat-square" alt="RE02"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="review/shop-replay/">shop-replay</a></td><td>犹豫商品按店面朝向存档，回放比价钉最便宜</td><td><img src="https://img.shields.io/badge/RE03-24292F?style=flat-square" alt="RE03"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="review/route-replay/">route-replay</a></td><td>路上登记危险点，次日出门按序预告</td><td><img src="https://img.shields.io/badge/RE04-24292F?style=flat-square" alt="RE04"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="review/attention-diary/">attention-diary</a></td><td>一天注意力被谁偷走，一张账单说清</td><td><img src="https://img.shields.io/badge/RE05-24292F?style=flat-square" alt="RE05"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="cue/cue-door/">cue-door</a></td><td>看向大门触发清单，逐项确认全过才放行</td><td><img src="https://img.shields.io/badge/CU01-24292F?style=flat-square" alt="CU01"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="cue/cue-fridge/">cue-fridge</a></td><td>看向冰箱触发清单，拿一样勾一样关门报漏拿</td><td><img src="https://img.shields.io/badge/CU02-24292F?style=flat-square" alt="CU02"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="cue/cue-desk/">cue-desk</a></td><td>看向书桌亮今日三件事，起身按未完成给续接句</td><td><img src="https://img.shields.io/badge/CU03-24292F?style=flat-square" alt="CU03"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="cue/cue-bag/">cue-bag</a></td><td>看向要背的包触发清单，逐项看向格层确认装入</td><td><img src="https://img.shields.io/badge/CU04-24292F?style=flat-square" alt="CU04"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="cue/cue-mirror/">cue-mirror</a></td><td>看向镜子亮三行，逐行确认已读，提前结束报未读</td><td><img src="https://img.shields.io/badge/CU05-24292F?style=flat-square" alt="CU05"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="social/chat-catchup/">chat-catchup</a></td><td>谈话走神摇头求助，眼前给最近15秒要点摘要</td><td><img src="https://img.shields.io/badge/SO01-24292F?style=flat-square" alt="SO01"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="curb-cut/my-bus-watch/">my-bus-watch</a></td><td>只守登记的一路公交，拍车头核线路号报上车与否</td><td><img src="https://img.shields.io/badge/CC02-24292F?style=flat-square" alt="CC02"> <img src="https://img.shields.io/badge/%E8%B7%AF%E7%BC%98%E5%9D%A1-FF9800?style=flat-square" alt="路缘坡"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="social/guest-watch/">guest-watch</a></td><td>客人逐位看向登记座位，定时提醒回看茶水位</td><td><img src="https://img.shields.io/badge/SO02-24292F?style=flat-square" alt="SO02"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="social/elder-ear/">elder-ear</a></td><td>守听老人聊天，叮嘱句存清单聊完复述</td><td><img src="https://img.shields.io/badge/SO03-24292F?style=flat-square" alt="SO03"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="social/standup-echo/">standup-echo</a></td><td>守听站会只亮关联句，未命中默记摘要会后查</td><td><img src="https://img.shields.io/badge/SO04-24292F?style=flat-square" alt="SO04"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E7%9B%B4%E6%8E%A5%E5%86%B2%E7%AA%81-C62828?style=flat-square" alt="直接冲突"></td></tr>
<tr><td><a href="social/gift-clue/">gift-clue</a></td><td>日常聊天默记想要句成线索卡，按人回放</td><td><img src="https://img.shields.io/badge/SO05-24292F?style=flat-square" alt="SO05"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E9%AB%98%E5%BA%A6%E9%87%8D%E5%8F%A0-F9A825?style=flat-square" alt="高度重叠"></td></tr>
<tr><td><a href="body/eye-rest/">eye-rest</a></td><td>头稳凝视近处满20分钟提醒远眺，抬头确认</td><td><img src="https://img.shields.io/badge/BO01-24292F?style=flat-square" alt="BO01"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/nod-count/">nod-count</a></td><td>语音指导10次慢速点头，低头回正算一次</td><td><img src="https://img.shields.io/badge/GA01-24292F?style=flat-square" alt="GA01"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/turn-count/">turn-count</a></td><td>语音指导左右转头交替，各5次满10次</td><td><img src="https://img.shields.io/badge/GA02-24292F?style=flat-square" alt="GA02"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="body/water-watch/">water-watch</a></td><td>久未看向水杯亮屏提醒喝水，凝视确认</td><td><img src="https://img.shields.io/badge/BO02-24292F?style=flat-square" alt="BO02"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/ear-tilt/">ear-tilt</a></td><td>左右贴耳各3次，稳住5秒才算一次</td><td><img src="https://img.shields.io/badge/GA03-24292F?style=flat-square" alt="GA03"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/stretch-hold/">stretch-hold</a></td><td>仰头低头交替拉伸，各保持5秒各3次</td><td><img src="https://img.shields.io/badge/GA04-24292F?style=flat-square" alt="GA04"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="body/breath-pace/">breath-pace</a></td><td>视线内呼吸节拍光点，跟着看就行</td><td><img src="https://img.shields.io/badge/BO03-24292F?style=flat-square" alt="BO03"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/neck-clock/">neck-clock</a></td><td>按报出的时钟点位转头，每点必回正</td><td><img src="https://img.shields.io/badge/GA05-24292F?style=flat-square" alt="GA05"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="body/stand-move/">stand-move</a></td><td>久坐超阈值提醒起身，环视一圈作确认</td><td><img src="https://img.shields.io/badge/BO04-24292F?style=flat-square" alt="BO04"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/chin-tuck/">chin-tuck</a></td><td>下巴小幅后收保持5秒，8次收下巴操</td><td><img src="https://img.shields.io/badge/GA06-24292F?style=flat-square" alt="GA06"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="body/snack-aware/">snack-aware</a></td><td>看向零食先亮今天第几次，吃不吃你决定</td><td><img src="https://img.shields.io/badge/BO05-24292F?style=flat-square" alt="BO05"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/steady-hold/">steady-hold</a></td><td>头稳住不动满10秒胜，动了重计</td><td><img src="https://img.shields.io/badge/GA07-24292F?style=flat-square" alt="GA07"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="ambient/light-change/">light-change</a></td><td>相机定时测光，光线暗了提醒开灯</td><td><img src="https://img.shields.io/badge/AM01-24292F?style=flat-square" alt="AM01"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/nod-catch/">nod-catch</a></td><td>10 个球下落，点头踩线接住计分</td><td><img src="https://img.shields.io/badge/GA08-24292F?style=flat-square" alt="GA08"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="ambient/sky-watch/">sky-watch</a></td><td>登记晾晒区，定时回看天空云变预警</td><td><img src="https://img.shields.io/badge/AM02-24292F?style=flat-square" alt="AM02"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/turn-dodge/">turn-dodge</a></td><td>障碍在左向右躲，10 回合回正计分</td><td><img src="https://img.shields.io/badge/GA09-24292F?style=flat-square" alt="GA09"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/follow-dot/">follow-dot</a></td><td>光点跳到哪就跟到哪，停稳算中</td><td><img src="https://img.shields.io/badge/GA10-24292F?style=flat-square" alt="GA10"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="ambient/noise-map/">noise-map</a></td><td>转头扫 8 方向，报最安静的朝向</td><td><img src="https://img.shields.io/badge/AM03-24292F?style=flat-square" alt="AM03"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/rhythm-nod/">rhythm-nod</a></td><td>16 拍固定节拍，拍点点头打中计分</td><td><img src="https://img.shields.io/badge/GA11-24292F?style=flat-square" alt="GA11"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="ambient/trail-back/">trail-back</a></td><td>沿途登记路口面包屑，返程反向逐点领回</td><td><img src="https://img.shields.io/badge/AM04-24292F?style=flat-square" alt="AM04"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/memory-seq/">memory-seq</a></td><td>语音报出方向序列，记住并依次复现</td><td><img src="https://img.shields.io/badge/GA12-24292F?style=flat-square" alt="GA12"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="ambient/tomorrow-stage/">tomorrow-stage</a></td><td>睡前登记明早要用的物品，出门逐项确认带齐</td><td><img src="https://img.shields.io/badge/AM05-24292F?style=flat-square" alt="AM05"> <img src="https://img.shields.io/badge/%E6%B3%A8%E6%84%8F%E5%8A%9B-9C27B0?style=flat-square" alt="注意力"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/find-target/">find-target</a></td><td>语音报方向，转过去停稳算找到</td><td><img src="https://img.shields.io/badge/GA13-24292F?style=flat-square" alt="GA13"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/level-keep/">level-keep</a></td><td>头端平保持水平，歪了小球偏，满10秒胜</td><td><img src="https://img.shields.io/badge/GA14-24292F?style=flat-square" alt="GA14"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/slow-scan/">slow-scan</a></td><td>从左到右慢速扫一遍，太快语音纠偏</td><td><img src="https://img.shields.io/badge/GA15-24292F?style=flat-square" alt="GA15"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/nod-quiz/">nod-quiz</a></td><td>是非题点头答是，侧转停稳答否计分</td><td><img src="https://img.shields.io/badge/GA16-24292F?style=flat-square" alt="GA16"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/breathe-turn/">breathe-turn</a></td><td>吸气慢慢转头，呼气慢慢回正，左右各3次</td><td><img src="https://img.shields.io/badge/GA17-24292F?style=flat-square" alt="GA17"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/guess-direction/">guess-direction</a></td><td>猜保密方向，语音报近了远了，转到算中</td><td><img src="https://img.shields.io/badge/GA18-24292F?style=flat-square" alt="GA18"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/traffic-light/">traffic-light</a></td><td>绿灯转向报出的方向，红灯稳住不动</td><td><img src="https://img.shields.io/badge/GA19-24292F?style=flat-square" alt="GA19"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
<tr><td><a href="games/daily-routine/">daily-routine</a></td><td>点头转头贴耳仰低收下巴，一套2分钟走完</td><td><img src="https://img.shields.io/badge/GA20-24292F?style=flat-square" alt="GA20"> <img src="https://img.shields.io/badge/%E6%B8%B8%E6%88%8F-00C853?style=flat-square" alt="游戏"> <img src="https://img.shields.io/badge/%E5%BE%85%E6%B5%8B%E8%AF%95-607D8B?style=flat-square" alt="待测试"></td></tr>
</table>
