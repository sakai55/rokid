# rokid — Rokid AIUI Agents（海外版 / Global）

Rokid AI 眼镜的 **AIUI 智能体** 仓库。我们只开发 Agent，不开发 App。
组织方式：**一个 Agent 一个目录**，每个目录是一套完整的 AIUI 项目
（`app.json` + `AGENTS.md` + `app.js` + `pages/`），仓库根目录只放本 README 和各 Agent 目录。

## Agents

| 目录 | 说明 | 真机测试状态 |
|---|---|---|
| `my-agent/` | 官方脚手架示例（Hello AIUI），验证全流程用 | 尚未导入 Studio |
| `glasses-benchmark/` | 眼镜全功能 Benchmark，21 项一键跑完 | Studio 名 `12345`，Build `1.0.19`，Debug version ready |

每个 Agent 的真机测试信息（Studio 里的名称、Build 版本、App 分类、描述、Agent ID、状态）
完整记录在该 Agent 目录自己的 README 里，以那里为准。

## 开发环境与工具链

```bash
npm install -g @yodaos-pkg/aix-cli          # AIX CLI（pack / preview / show）
npm create @yodaos-pkg/aiui-agent@latest    # 官方脚手架
npx skills add https://github.com/jsar-project/AIUI/tree/main/skills/aiui-dev
                                            # aiui-dev Skill（给 Coding Agent 用）
aix pack . -o <name>.aix                    # 在 Agent 目录内打包
aix preview .                               # 本地预览（终端起服务 / --html-out 导出 HTML）
```

打包注意：项目根必须有 `.aixignore`，排除 `.agents/`、`.aix/`、`artifacts/`、`*.aix`、
`skills-lock.json`、`node_modules/`，否则开发文件会进包（实测 2.3 KB 会涨到 107 KB）。

## 标准工作流

1. **本地开发**：在对应 Agent 目录里开发、改页面。
2. **预览**：开发完成后用 `aix preview` 出该 Agent **所有页面**的预览图确认效果。
3. **推 GitHub**：代码推到本仓库对应 Agent 目录。
4. **Studio 导入**：Global AIUI Studio → New Agent → **Import from GitHub** → 选本仓库 →
   指定 Agent 子目录导入（一个目录导一个 Agent）。
5. **真机测试（云端下发）**：见下面专门章节。
6. **提交审核**：真机测试通过并确认后，在 Studio 的 **Submit** 页签填写
   Review Information（Feature Description、Opening Message、Preview Media、Change Log）
   并 Submit for Review。

## ⚠️ 海外版本注意事项（必须全链路海外，缺一不可）

1. **Studio 必须是 Global 站 + 英文**：只用
   [aiui-global.rokid.com/?lang=en-US](https://aiui-global.rokid.com/?lang=en-US)，
   地址是 global、语言参数必须是 `en-US`。不要用国内站（aiui.rokid.com），
   两站账号和项目不互通。
2. **账号必须是海外版注册**：在 [account-web.rokid.com](https://account-web.rokid.com/)
   的**英文版**注册/登录 Rokid 账号（本项目账号地区：Japan）。
   用国内版注册的账号不算海外开发账号。
3. **下发走云端，不走数据线**：在 Studio 里打包保存后由云端下发到眼镜，
   不用 ADB、不用数据线直装。
4. **手机 App 必须是海外版 Hi Rokid**：Google Play 的
   **Hi Rokid - Rokid Glasses**（包名 `com.rokid.sprite.global.aiapp`，
   发行方 Rokid International），**不是国内版 Rokid Ai App**。
   眼镜资源包的更新入口在 Hi Rokid 里。
5. 以上四点（Global 账号 + en-US Studio + 云端下发 + Hi Rokid）齐全，
   才算海外版开发；任何一环用了国内版，链路就不通。

## 真机测试（云端下发）详细步骤

在 Global AIUI Studio（en-US）里打开该 Agent：

1. 进 **Device Debug** 页签，先填 **Basic Information**：
   - Agent Icon（建议 1:1 图片）
   - **Agent Name**（必填）
   - **App Category**（必填）：Life / Work / Entertainment / Learning
   - **Intent Description**（必填，≤500 字）：写清 AI 助手应在什么场景、
     什么前提下、被什么样的用户请求唤起这个 Agent
   - Version 和 Agent ID 由系统生成，不可手改；**Version 是 Build 号，
     每次重新打包保存自动递增**（如 1.0.19）
2. 在 **AIX Packaging** 区点 **Repackage and Save**，等打包完成。
3. **成功的标志**：页面顶部出现绿色状态
   **● Debug version ready — Ready for device debugging**。
   没出现这个状态，说明这一版还没有保存成功，App 端拉不到，不要去 App 里白等。
4. 手机打开 **Hi Rokid**（海外版），确认已连接眼镜，进
   「设置 → 开发者选项 → AIUI」→ 点「更新眼镜资源包」，等眼镜端下载完成，
   看到「智能体资源包下载成功」。
5. 对眼镜语音打开该 Agent（如「乐奇，打开 xxx」）开始真机测试。
6. 改代码后循环：改 → 推 GitHub → Studio 更新导入 → Repackage and Save
   （Build 号递增，重新出现 Debug version ready）→ Hi Rokid 更新眼镜资源包 → 再测。
   **只改代码不重新 Repackage and Save，App 拉到的还是旧版。**

## 提交审核

真机测试全部通过后（以维护者确认「真机测试完成」为准）：

1. 在 Studio 的 **Submit** 页签填 Review Information：
   Feature Description、Opening Message、Preview Media、Change Log。
   **这四项的成稿统一放在各 Agent 自己 README 的「提审资料（Review Submission）」
   章节里，分段写好，提交时整段复制**（Feature Description ≤500 字、
   Opening Message ≤500 字且支持 Markdown；Preview Media 需 3–5 个
   JPG/PNG/MP4 且至少 1 图 1 视频，每次提交前重新确认）。
2. 确认权限声明与代码实际用到的能力一致（如定位 GEOLOCATION、相机 CAMERA、
   录音 RECORD_AUDIO 必须在 `app.json.permissions` 里声明）。
3. 点 **Submit for Review** 提交，等待审核结果；被拒按原因修改后
   重新打包保存、重新提交。
