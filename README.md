# rokid — Rokid AIUI Agents

Rokid AI 眼镜的 AIUI 智能体项目（AIUI / AIX 路线）。

## 当前项目（仓库根目录）

脚手架示例智能体 `my-agent`：

- `app.json` — 页面注册与全局窗口配置
- `app.js` — 应用级逻辑
- `AGENTS.md` — 智能体定义（身份、能力、行为边界）
- `pages/index/index.ink` — 首页（.ink 单文件：`<script def>` / `<script setup>` / `<page>` / `<style>`）
- `.aixignore` — 打包排除（`.agents/`、`.aix/`、`artifacts/`、`*.aix`、`skills-lock.json` 等开发文件不要进 .aix 包）

## 工具链

```bash
npm install -g @yodaos-pkg/aix-cli        # AIX CLI
npm create @yodaos-pkg/aiui-agent@latest  # 官方脚手架
npx skills add https://github.com/jsar-project/AIUI/tree/main/skills/aiui-dev  # aiui-dev Skill
aix pack . -o my-agent.aix                # 打包
aix preview ./my-agent                    # 本地预览
```

## 真机测试流程（路径一：Studio + Rokid AI App）

1. 在 Global AIUI Studio（aiui-global.rokid.com）从 GitHub 导入本仓库
2. 在 Studio「构建与提审」里做 AIX 打包并保存（生成新版本后 App 才能拉到）
3. 手机 Rokid AI App →「设置 → 开发者选项 → AIUI」→「更新眼镜资源包」
4. 看到「智能体资源包下载成功」后，对眼镜说「乐奇，打开 my-agent」

真机测试通过后，再在 Studio 提交审核。
