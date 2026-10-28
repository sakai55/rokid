# 定期まもり — Agent Notes

JP28（日本在地 × 路缘坡 × 注意力）。交互哲学：**定期券帳簿**。一句话场景：通勤者が改札前で定期券の期限と忘れ物を一度に確認する。

## Design contract

见 README「结构与功能」一节：进入→过程→结果、可反复用；内容集逐项可数；跨会话持久化键 `teikiMamoriV1`。

## 诚实边界

见 README「诚实边界」一节。

## Permissions

见 README「权限」一节。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## Validation

- 静态校验与打包结果见精品线台账；预览截图在仓库 `screenshots/teiki-mamori/`。
