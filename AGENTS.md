# 看向代说 — Agent Notes

CC16（路缘坡（CC））。交互哲学：**代说卡片**。一句话场景：失语者看向场景、从4句固定候选里点头选一句、由TTS替他说出来。

## Design contract

见 README「结构与功能」一节：进入→过程→结果、可反复用；内容集逐项可数；跨会话持久化键 `sayByLookingV1`。

## 诚实边界

见 README「诚实边界」一节。

## Permissions

见 README「权限」一节。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## Validation

- 静态校验与打包结果见精品线台账；预览截图在仓库 `screenshots/say-by-looking/`。
