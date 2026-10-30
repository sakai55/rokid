# 单手开物

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-one-hand-open
```

**AIX 直接下载**（最新版）：[one-hand-open.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/one-hand-open.aix)

编号 CC20，方向构成：路缘坡。一句话场景：只有一只手能用的人按单手重构步骤开瓶盖、撕包装、开快递，不腾手操作眼镜。

## 预览截图

![preview-one-hand-open-index.png](../screenshots/one-hand-open/preview-one-hand-open-index.png)
![preview-one-hand-open-check.png](../screenshots/one-hand-open/preview-one-hand-open-check.png)
![preview-one-hand-open-record.png](../screenshots/one-hand-open/preview-one-hand-open-record.png)
![preview-one-hand-open-check-s2.png](../screenshots/one-hand-open/preview-one-hand-open-check-s2.png)

## 方向构成

- 本 Agent 的方向构成：路缘坡。场景核心是只有一只手能用的人不用腾手操作眼镜也能开东西，物品清单、单手步骤逐项勾选、完成记录三环都服务于这一环，不是功能拼盘。
- 一句话场景：只有一只手能用的人按单手重构步骤开瓶盖、撕包装、开快递，不腾手操作眼镜。

## 结构与功能

3 页：`pages/index/` 物品清单（6 件，每件一句单手前提：瓶盖——一只手拧瓶盖，另一只手腾不出来；零食包装——一只手撕开零食袋，不洒出来；快递箱——一只手拆快递箱，不用牙咬胶带；罐头——一只手开罐头拉环，不割到手；药瓶——一只手开药瓶，药片不洒；饮料拉环——一只手拉开易拉罐，不溅出来）；`pages/check/` 单手步骤（选中物品专属 5 步，全部按单手重构：以桌沿、身体、膝盖、墙角、抽屉缝为固定点，不是双手版的朗读；上下切换步骤、逐项勾选，5 步全勾后按「全部完成」语音播报并保存一条记录）；`pages/record/` 完成记录（最近 6 条 + 累计总数）。

内容集的数：物品 6 件；单手步骤每件 5 步，共 30 步，各件步骤互异；完成记录按实际条数计。闭环：选一件物品 → 按单手步骤逐项做、逐项勾 → 全部完成语音播报并记下 → 下一件可反复用。跨会话持久化：存储键 `oneHandOpenV1`（选中物品、完成记录数组、`lastError`）。

单手步骤一览（每件 5 步）：瓶盖：把瓶身夹在两膝之间、用桌沿卡住瓶盖、单手反向拧、拧不动先松后紧、盖子放稳防滚；零食包装：包装袋一角压在桌沿下、单手捏住另一角、向身体方向慢撕、撕口够大停手、倒出不洒；快递箱：箱子靠墙角顶住、胶带一端用膝盖压住、单手沿中线划开、先开一面再翻面、取出物品核对；罐头：罐身放进抽屉缝卡住、拉环勾住桌沿、单手下压起盖、盖口朝外防割手、倒出后盖子朝下放；药瓶：瓶身夹在腋下固定、下压式盖先压后转、转不动换手掌根部压、药片倒在掌心数、盖紧后放回原处；饮料拉环：易拉罐夹在两腿间、拉环勾在钥匙圈上、单手向后拉、拉环不断慢慢加力、开口朝上防溅。

## 手势映射

| 手势（镜腿触控板） | 按键事件 | 本 Agent 中的作用 |
|---|---|---|
| 单指点按 | Enter | 主确认（步骤页为勾选本步） |
| 上滑/下滑 | ArrowUp / ArrowDown | 切换物品/步骤 |
| 点头（头部静止时） | `onHeadGesture('nod')` | 主确认，与 Enter 等价 |
| 双指点按 | Backspace | 返回上一页（子页） |

## 权限

无。TTS 用宿主固定音色，永不设置 utterance 的 `lang`；不调用相机与定位。

## 诚实边界

- **步骤是单手重构的通用做法，锋利/烫手物品先停手求助，不作医疗建议。** 步骤按桌沿、身体、膝盖等固定点重构，不是双手版的朗读。
- 本 Agent 是生活辅助，不替代康复与医疗建议；手部情况变化请咨询专业人员。

## 错误码

失败时在镜片画面显示裸码，TTS 只读码本身，最近一次错误写入持久数据的 `lastError`（含码、本机 slug、版本、原文）。本机可能出现的码：

- `E5001` 记录保存失败（存储写入异常）
- `E5002` 记录读取失败（读取/解析异常）
- `E3005` 朗读失败（TTS speak 异常）
- `E8001` 页面跳转失败（navigateTo/navigateBack 异常）

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

- Feature Description: 单手开物：只有一只手能用的人的开物帮手。6 件物品各有单手前提与专属 5 步，步骤以桌沿、身体、膝盖为固定点重构，逐项勾选、全部完成语音播报并记下，记录跨会话保存。
- Opening Message: 一只手也能开东西。选一件物品，跟着单手步骤一步一步勾，做完按一下全部完成，就记下了。
- Preview Media: 预览截图见上（截图在开发流程后补齐，正式提审需 3–5 个媒体文件，其中视频 ≥1 个、≤60 秒）。
- Change Log (Build 1.0.0):
  - Features added: 初版；6 件物品清单、每件 5 步单手步骤共 30 步、逐项勾选与全部完成记录、跨会话持久化。
  - Improvements: 无（初版）。
  - Fixes: 无（初版）。
