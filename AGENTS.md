# 駅弁えらび — Agent Notes

JP31（日本在地 × 注意力 × 游戏）。交互哲学：**駅弁トレイ**。一句话场景：駅で旅行者がアレルギーを確かめながら駅弁をクイズで選ぶ。

## Design contract

见 README「结构与功能」一节：进入→过程→结果、可反复用；内容集逐项可数；跨会话持久化键 `ekibenErabiV1`。

## 诚实边界

见 README「诚实边界」一节。

## Permissions

见 README「权限」一节。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## Validation

- 静态校验与打包结果见精品线台账；预览截图在仓库 `screenshots/ekiben-erabi/`。
