# 开口提示卡 — Agent Notes

CC18(路缘坡)。交互哲学:**开口前的一张提示卡**。一句话场景: 平时说话声音太小的人, 开口前先看一眼提示卡, 跟读一句示范句练声量, 每次对话后确认对方是否听清。

## Design contract

见 README「结构与功能」一节: 进入→过程→结果、可反复用; 内容集逐项可数; 跨会话持久化键 `speakUpCueV1`。

## 诚实边界

见 README「诚实边界」一节: 本机不测量声压、不测分贝——听清率来自对话后本人确认, 不是仪器测量; 生活辅助, 不替代医疗诊断与治疗建议。

## Permissions

见 README「权限」一节。TTS 用宿主固定音色, 永不设置 utterance 的 `lang`。

## Validation

- 静态校验与打包结果见精品线台账; 预览截图在仓库 `screenshots/speak-up-cue/`。
