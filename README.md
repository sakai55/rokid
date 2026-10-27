# Seoul Transfer

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：
```
https://github.com/sakai55/rokid/tree/agent-seoul-transfer
```

一句话场景：第一次坐首尔地铁的人，在换乘站用头部方向确认站台方向并锁定，再用倒计时守住末班车。

方向构成：韩国在地 × 指向性 × 注意力。指向性承担换乘站台方向确认一环（头部 yaw 左右确认＋点头锁定）；注意力承担末班车倒计时守候与换乘记录保持一环；在地性落在首尔地铁 8 处真实换乘站与线路。

## 预览截图

![总览](<../screenshots/seoul-transfer/preview-seoul-transfer-index.png>)
![换乘确认](<../screenshots/seoul-transfer/preview-seoul-transfer-transfer.png>)
![换乘确认二](<../screenshots/seoul-transfer/preview-seoul-transfer-transfer-s2.png>)
![末班车守候](<../screenshots/seoul-transfer/preview-seoul-transfer-lasttrain.png>)
![末班车守候二](<../screenshots/seoul-transfer/preview-seoul-transfer-lasttrain-s2.png>)

## 结构与功能

- 页清单（3 页）：总览 index（8 换乘站线路带＋今日状态）／换乘确认 transfer（逐站方向确认与锁定）／末班车守候 lasttrain（手动倒计时＋记录回显）。
- 内容集计数：换乘站 8 处（서울역・시청・종로3가・동대문역사문화공원・강남・잠실・홍대입구・고속터미널），每处含换乘线路与站台方向一句话；倒计时档位 5 档（5/10/15/20/30 分钟）。
- 闭环：进入总览 → 换乘页选站、看方向句、头部确认、点头锁定（TTS 报结论并存记录）→ 末班车页选分钟、开始倒计时、到点播报并记一次；记录跨会话持久化（存储键 `seoulTransferV1`），可反复用。

## 手势映射

| 操作 | 效果 |
|---|---|
| 首页 ArrowUp/ArrowDown | 循环选子页（▶ 标记） |
| 首页 Enter | 打开选中子页 |
| 子页 ArrowUp/ArrowDown | 上一／下一项（换乘页换站、末班车页换分钟） |
| 子页 Enter | 主动作（锁定方向／开始倒计时） |
| 点头 | 主动作（与 Enter 同效） |
| 头部左右转 | 换乘页确认站台方向 |

## 权限

无。TTS 用宿主固定音色，不设置 utterance 的 `lang`。

## 诚实边界

- 站台方向句是内置内容集，不联网、不含实时列车时刻与站台变更信息；末班车倒计时是用户手动设定的提醒，不是官方时刻表。
- 传感器不可用时页面如实显示，方向锁定仍可用 Enter/点头完成，不冒充传感读数。

## 设备测试信息

| 项目 | 内容 |
|---|---|
| Studio 名 | 待回填 |
| Version | 1.0.0 |
| App Category | 待回填 |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| 状态 | 未导入／未真机验证 |

## 提审资料 (Review Submission)

- Feature Description：首尔地铁换乘助手：8 处换乘站的线路与站台方向指引，头部方向确认并锁定，末班车倒计时守候，换乘记录跨会话保存。
- Opening Message：首尔地铁换乘站에서 방향을 확인하고 막차를 지키세요. 환승역 8곳의 방향 안내와 막차 카운트다운이 함께합니다.
- Preview Media：预览截图见上（截图由开发流程后补，至少 1 图＋1 视频，视频 ≤60 秒）。
- Change Log（Build 1.0.0）：
  - Features added：8 换乘站方向确认页、头部 yaw 方向确认与点头锁定、末班车倒计时守候、换乘记录持久化。
  - Improvements：无（首版）。
  - Fixes：无（首版）。
