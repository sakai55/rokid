# 서울 생활 수첩 — Agent Notes

KR19（韩国在地 × 集合总控 × 注意力）。（立项时曾列指向性，建成复核：20 工具页均无方向机制承载，故修正，不虚标。）交互哲学：**서울 생활 수첩**。一句话场景：在首尔生活一周的访客用一本手帳把20件日常工具回完。

## Design contract

见 README「结构与功能」一节：进入→过程→结果、可反复用；内容集逐项可数；跨会话持久化键 `seoulLifeHubV1`。

## 诚实边界

见 README「诚实边界」一节。

## Permissions

见 README「权限」一节。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## Validation

- 静态校验与打包结果见精品线台账；预览截图在仓库 `screenshots/seoul-life-hub/`。
