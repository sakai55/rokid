# 开口提示卡

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-speak-up-cue
```

**AIX 直接下载**（最新版）：[speak-up-cue.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/speak-up-cue.aix)

一句话场景：平时说话声音太小的人, 开口前先看一眼提示卡, 跟读一句示范句练声量, 每次对话后确认对方是否听清。

## 预览截图

![preview-speak-up-cue-index.png](../screenshots/speak-up-cue/preview-speak-up-cue-index.png)
![preview-speak-up-cue-check.png](../screenshots/speak-up-cue/preview-speak-up-cue-check.png)
![preview-speak-up-cue-check-s2.png](../screenshots/speak-up-cue/preview-speak-up-cue-check-s2.png)
![preview-speak-up-cue-record.png](../screenshots/speak-up-cue/preview-speak-up-cue-record.png)

## 方向构成

- 本 Agent 的方向构成: 路缘坡。场景核心是声音偏小者在日常对话中被听见的需求, 提示卡、跟读自评、对话确认三环都服务于这一环, 不是功能拼盘。
- 一句话场景: 平时说话声音太小的人, 开口前先看一眼提示卡, 跟读一句示范句练声量, 每次对话后确认对方是否听清。

## 结构与功能

3 页: `pages/index/` 场面与提示卡(6 场面: 家里/办公室/餐厅/医院/教室/电话, 每场面一句提示: 慢一点/大声一点/面向对方, 三类提示在 6 场面中各出现两次);`pages/check/` 跟读练习(6 示范句 TTS 播报, 用户跟读后自评 大/正好/小, 自评逐条保存);`pages/record/` 对话确认记录(每次对话后确认 听清/重说, 累计听清率与总数, 最近 6 条回显)。

内容集的数: 场面 6 个; 示范句 6 句; 自评与确认记录按实际条数计。闭环: 进提示卡选场面 → 跟读页听示范、跟读、自评 → 对话后在记录页确认听清或重说, 听清率累计变化。跨会话持久化: 存储键 `speakUpCueV1`(选中场面、自评数组、听清数、对话总数、确认记录数组、`lastError`)。

## 手势映射

| 手势(镜腿触控板) | 按键事件 | 本 Agent 中的作用 |
|---|---|---|
| 单指点按 | Enter | 主确认(各页主按钮) |
| 上滑/下滑 | ArrowUp / ArrowDown | 切换场面/示范句 |
| 点头(头部静止时) | `onHeadGesture('nod')` | 主确认, 与 Enter 等价 |
| 双指点按 | Backspace | 返回上一页(子页) |

## 权限

无。TTS 用宿主固定音色, 永不设置 utterance 的 `lang`; 不调用相机与定位。

## 诚实边界

- **本机不测量声压、不测分贝——听清率来自对话后本人确认, 不是仪器测量。** 跟读自评同样来自本人感受, 不是仪器测量。
- 提示卡与示范句是内置内容, 不诊断嗓音问题, 不给出医疗结论。
- 本 Agent 是生活辅助, 不替代医疗诊断与治疗建议。嗓音持续异常请咨询专业医生。

## 错误码

失败时在镜片画面显示裸码, TTS 只读码本身, 最近一次错误写入持久数据的 `lastError`(含码、本机 slug、版本、原文)。本机可能出现的码:

- `E5001` 记录保存失败(存储写入异常)
- `E5002` 记录读取失败(读取/解析异常)
- `E3005` 朗读失败(TTS speak 异常)
- `E8001` 页面跳转失败(navigateTo/navigateBack 异常)

## 设备测试信息

| 项目 | 内容 |
|---|---|
| Studio 名称 | 未填写 |
| Version | 1.0.0 |
| App Category | 未填写 |
| Intent Description | 未填写 |
| Agent ID | 未填写 |
| 状态 | 未导入 / 未真机验证 |

## 提审资料 (Review Submission)

- Feature Description: 开口提示卡: 声音偏小者的说话帮手。6 场面提示卡开口前提醒, 6 示范句跟读自评练声量, 每次对话后确认听清与否并累计听清率, 记录跨会话保存。
- Opening Message: 开口前先看一眼提示卡。选场面、跟读一句、对话后确认一次, 慢慢把声音练到能被听清。
- Preview Media: 预览截图见上(截图在开发流程后补齐, 正式提审需 3–5 个媒体文件, 其中视频 ≥1 个、≤60 秒)。
- Change Log (Build 1.0.0):
  - Features added: 初版; 6 场面提示卡、6 示范句跟读自评、对话确认与听清率累计、跨会话持久化。
  - Improvements: 无(初版)。
  - Fixes: 无(初版)。
