# 祭りゲーム集 — Agent Notes

JP32（日本在地 × 游戏 × 注意力 × 指向性）。交互哲学：**屋台ゲーム集**。一句话场景：夏祭りの待ち時間、家族が眼鏡一本で20の屋台ゲームを回す。

## Design contract

见 README「结构与功能」一节：进入→过程→结果、可反复用；内容集逐项可数；跨会话持久化键 `matsuriGameShuuV1`。

## 诚实边界

见 README「诚实边界」一节。

## Permissions

见 README「权限」一节。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## Validation

- 静态校验与打包结果见精品线台账；预览截图在仓库 `screenshots/matsuri-game-shuu/`。
