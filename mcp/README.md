# mcp/ — Rokid 项目的 MCP 登记处

中文 | [English](README.en.md) | [日本語](README.ja.md)

Model Context Protocol 服务器与连接方式的登记目录：本项目实际在用的 MCP、
用途、接入方式都记在这里，新增一个登记一个，避免散落在各台机器的本地配置里。

## 在用

| MCP | 用途 | 接入方式 | 状态 |
|---|---|---|---|
| GitHub 官方 MCP Server | 仓库读写（文件、分支、提交查询） | GitHub 连接器（OAuth，账号 `sakai55`） | 在用（只读查询与文本文件场景） |

> 说明：日常 GitHub 操作（含二进制 .aix / PNG、分支清理等）现在以**终端 `gh` / `git`**
> 为准（已登录 sakai55，见根 README「维护约定」）；GitHub MCP 作为连接器能力保留，
> 适合快速只读查询。两者操作同一个仓库 `sakai55/rokid`，不要混淆提交来源即可。

## 计划 / 占位

| MCP | 设想用途 | 状态 |
|---|---|---|
| （待建）AIUI Docs MCP | 把官方 AIUI 文档（API 契约、事件、组件）做成本地可查的 MCP，供各 Agent 开发时核对能力边界 | 未建；现阶段用 `skills/aiui-dev` 的 references 代替 |

## 新增一个 MCP 时

1. 在本目录建 `<name>/` 子目录，放该 MCP 的 `README.md`：写清服务器来源（官方仓库/包名）、
   启动方式、需要的凭据**存放在哪里**（只写存放位置，如 Secure Vault / 环境变量名，**绝不写凭据值**）、
   暴露的工具清单与典型用法。
2. 在上表登记一行。
3. 若凭据需要录入，走 Secure Vault 安全录入流程，不进聊天、不进仓库。
