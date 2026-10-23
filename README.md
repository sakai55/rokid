# rokid — Rokid AIUI Agents

Rokid AI 眼镜的 AIUI 智能体仓库。**一个 Agent 一个目录**，每个目录是一套完整的 AIUI 项目（`app.json` + `AGENTS.md` + `pages/`）。

## Agents

| 目录 | 说明 |
|---|---|
| `my-agent/` | 官方脚手架示例智能体（Hello AIUI），用于验证开发 → 打包 → 导入 → 真机全流程 |
| `glasses-benchmark/` | 眼镜全功能 Benchmark：21 项一键跑完（设备/显示/CPU/加密/存储/网络/Canvas/音频/麦克风/相机/传感器/定位/BLE/电量/TTS/ASR/LLM/条码/交互） |

## 在 AIUI Studio 中导入

Global AIUI Studio（aiui-global.rokid.com）→ New Agent → **Import from GitHub** → 选择本仓库 → **指定要导入的 Agent 子目录**（如 `glasses-benchmark`），一次导入一个 Agent。

## 工具链

```bash
npm install -g @yodaos-pkg/aix-cli        # AIX CLI
npm create @yodaos-pkg/aiui-agent@latest  # 官方脚手架
aix pack . -o agent.aix                   # 在某个 Agent 目录内打包
aix preview .                             # 本地预览
```

## 真机测试流程（Studio + Rokid AI App）

1. Studio 导入 Agent → 在 Device Debug 页签完成 basic information、permissions、package and save
2. 手机 Rokid AI App →「设置 → 开发者选项 → AIUI」→「更新眼镜资源包」
3. 看到「智能体资源包下载成功」后，对眼镜语音打开该智能体测试
4. 真机测试通过后，再在 Submit 页签提交审核
