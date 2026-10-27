# skills/ — Rokid 项目的 Skill 库

给 Coding Agent 用的技能包（`SKILL.md` + 参考资料）。开发任何 Agent 前先装对应 skill，
不要凭 Web / 小程序的经验假设 AIUI 的 API 存在。

| 目录 | 内容 | 来源 |
|---|---|---|
| [`aiui-dev/`](aiui-dev/) | 官方 AIUI 开发技能：框架、.ink 页面、组件、WXSS、运行时 API 契约、单色绿设计规范、打包检查清单 | 官方仓库 [yodaos-project/AIUI](https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev) 的 vendored 副本（2026-10-24 同步）；上游更新后在此覆盖同步 |
| [`rokid-agent-sop/`](rokid-agent-sop/) | 本项目生产 SOP：能力红线 → 开发 → 静态检查 → 打包 → 预览 → README（含提审资料）→ GitHub 同步（main + aix/ 包 + 截图 + `agent-<slug>` 分支）→ 登记 | 本项目自有 |
| [`rokid-preview-screenshots/`](rokid-preview-screenshots/) | 本地预览截图管线：`aix preview` 导出 HTML → 本地 Ink 运行时 → headless Chrome 截 480×352 画布 | 本项目自有 |
| [`rokid-conflict-audit/`](rokid-conflict-audit/) | 默认能力冲突排查：七项自带功能基线 + 三档判定（直接冲突 / 高度重叠 / 待测试），根 README 冲突徽章的唯一数据源；带版本号迭代（当前 v1.0.0） | 本项目自有 |
| [`rokid-boutique-acceptance/`](rokid-boutique-acceptance/) | 精品线批次验收（rokid-boutique-acceptance）：按建成文件核页数与同构、内容集逐项数、闭环查 API 接线、跨会话查持久化代码、占位永不计入、只计通过项；带版本号迭代 | 本项目自有 |
| [`jp/`](jp/) | 日本本地化技能（rokid-jp-localization）：JP 系列的在地性判据、日语纯度规则与机检、中文文案陷阱、环境门；带版本号迭代 | 本项目自有 |
| [`kr/`](kr/) | 韩国本地化技能（rokid-kr-localization）：KR 系列的在地性判据、韩语纯度规则与机检（假名与汉字 = 0）、日语文案陷阱、环境门；带版本号迭代 | 本项目自有 |

## 用法

```bash
# 从本仓库安装单个 skill 到当前项目
npx skills add https://github.com/sakai55/rokid/tree/main/skills/aiui-dev

# 或直接把目录拷进项目的 .agents/skills/
cp -r skills/aiui-dev <agent-project>/.agents/skills/
```

> 注意：Agent 工程打包时 `.aixignore` 必须排除 `.agents/`，否则 skill 文件会进 .aix 包。
