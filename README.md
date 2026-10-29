# 서울 생활 수첩

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-seoul-life-hub
```

**AIX 直接下载**（最新版）：[seoul-life-hub.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/seoul-life-hub.aix)

KR19 · 韩国在地 × 集合总控 × 注意力。在首尔生活一周的访客用一本手帳把20件日常工具回完

## 预览截图

![preview-seoul-life-hub-index.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-index.png)
![preview-seoul-life-hub-t01.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t01.png)
![preview-seoul-life-hub-t02.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t02.png)
![preview-seoul-life-hub-t03.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t03.png)
![preview-seoul-life-hub-t04.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t04.png)
![preview-seoul-life-hub-t05.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t05.png)
![preview-seoul-life-hub-t06.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t06.png)
![preview-seoul-life-hub-t07.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t07.png)
![preview-seoul-life-hub-t08.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t08.png)
![preview-seoul-life-hub-t09.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t09.png)
![preview-seoul-life-hub-t10.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t10.png)
![preview-seoul-life-hub-t11.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t11.png)
![preview-seoul-life-hub-t12.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t12.png)
![preview-seoul-life-hub-t13.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t13.png)
![preview-seoul-life-hub-t14.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t14.png)
![preview-seoul-life-hub-t15.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t15.png)
![preview-seoul-life-hub-t16.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t16.png)
![preview-seoul-life-hub-t17.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t17.png)
![preview-seoul-life-hub-t18.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t18.png)
![preview-seoul-life-hub-t19.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t19.png)
![preview-seoul-life-hub-t20.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t20.png)
![preview-seoul-life-hub-t01-s2.png](../screenshots/seoul-life-hub/preview-seoul-life-hub-t01-s2.png)

## 方向构成

- 本 Agent 的方向构成：韩国在地 × 集合总控 × 注意力。每个方向在场景里承担不可替代的一环，非功能拼盘。（立项时曾列指向性，建成复核：20 工具页均无方向机制承载，故修正为三方向，不虚标。）
- 一句话场景：在首尔生活一周的访客用一本手帳把20件日常工具回完。

## 结构与功能

21 页：`pages/index/` 生活手帳一覧（20工具名を5件ずつ窓表示・上下选・Enter开）；工具页各一功能——核销清单13页（各4点、点头逐项打勾、齐全记完成记录）、选择问答3页（各3問・3択・正誤TTS＋解説）、代说短语3页（各4句固定短语、主确认即TTS代说并记记录）、计数1页（散步5处目标计数）。每工具页功能与内容集互异，状态变体不充页数。

内容集计数：生活工具20个；清单13页×4点；问答3页×3問；短语3页×4句；计数1页目标5处；使用记录按实际条数计。跨会话持久化：存储键 `seoulLifeHubV1`（选中项、打勾/答题/计数状态、完成记录数组、`lastError`）。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 主确认（各页主按钮） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 切换选项 / 上下一项 |
| 点头（头稳时） | `onHeadGesture('nod')` | 等价于主确认 |
| 双击 | Backspace | 返回上一页（子页） |

## 权限

无。TTS 与传感器不需要清单权限，相机零调用。

## 诚实边界

- 각 도구의 안내와 문장은 수록된 정형 내용입니다. 실제 가게와 기관의 안내가 기준입니다.
- 대신 말하기는 본인이 고른 정형 문장만을 읽습니다. 현장에서 새로 만든 말이 아닙니다.

## 错误码

失败时眼镜屏显裸码、TTS 只读码、最近一次错误写入持久数据的 `lastError`（含码、本台 slug、版本与原文）。本台可能出现的码：

- `E5001` 记录保存失败（存储写入抛错）
- `E5002` 记录读取失败（读取/解析抛错）
- `E3005` 播报失败（TTS speak 抛错）
- `E8001` 页面切换失败（navigateTo/navigateBack 抛错）

## 设备测试信息

| 项目 | 内容 |
|---|---|
| Studio 名 | 待回填 |
| Version | 1.0.0 |
| App Category | 待回填 |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| 状态 | 未真机验证 |

## 提审资料 (Review Submission)

Feature Description: Seoul life hub: one notebook for a week in Seoul. Twenty daily tools - checklists, quizzes, spoken phrases and a count - each with its own set and persisted use records.

Opening Message: 서울에서 일주일을 보내시나요. 생활 도구 스무 개를 한 권의 수첩으로 써 보세요.

Preview Media:
- `preview-seoul-life-hub-index.png`
- `preview-seoul-life-hub-t01.png`
- `preview-seoul-life-hub-t02.png`
- `preview-seoul-life-hub-t03.png`
- `preview-seoul-life-hub-t04.png`
- `preview-seoul-life-hub-t05.png`
- `preview-seoul-life-hub-t06.png`
- `preview-seoul-life-hub-t07.png`
- `preview-seoul-life-hub-t08.png`
- `preview-seoul-life-hub-t09.png`
- `preview-seoul-life-hub-t10.png`
- `preview-seoul-life-hub-t11.png`
- `preview-seoul-life-hub-t12.png`
- `preview-seoul-life-hub-t13.png`
- `preview-seoul-life-hub-t14.png`
- `preview-seoul-life-hub-t15.png`
- `preview-seoul-life-hub-t16.png`
- `preview-seoul-life-hub-t17.png`
- `preview-seoul-life-hub-t18.png`
- `preview-seoul-life-hub-t19.png`
- `preview-seoul-life-hub-t20.png`
- `preview-seoul-life-hub-t01-s2.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机录制后补。

Change Log — Build 1.0.0:

- Features added: 首个版本；在首尔生活一周的访客用一本手帳把20件日常工具回完
- Improvements: 无（首个版本）
- Fixes: 无（首个版本）
