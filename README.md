# Freeze Step Cue（步态冻结节律提示 Step Cue）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-freeze-step-cue
```

CC10 · 路缘坡（CC）。v2.0.0 原地重做：精品线首批复查后，GO 裁定本 Agent 不合并（帕金森人群会被稀释）、原地加厚重做。v1 是单页薄形态；v2 是三页结构＋真实节拍器与记步接线＋跨会话记录。一句话场景：帕金森步态冻结者在门口、电梯口迈不开步时，选一组节律，跟着视线内的节律线与 TTS 拍子一步一拍走起来；走不起来就超时扶稳休息。

## 预览截图

![预览-index](<../screenshots/freeze-step-cue/preview-freeze-step-cue-index.png>)
![预览-cue](<../screenshots/freeze-step-cue/preview-freeze-step-cue-cue.png>)
![预览-cue-s2](<../screenshots/freeze-step-cue/preview-freeze-step-cue-cue-s2.png>)
![预览-record](<../screenshots/freeze-step-cue/preview-freeze-step-cue-record.png>)

## 结构与功能（闭环）

三页结构（节律卡清单 / 节律线大字步数 / 会话记录日志）：

- **节律选择（pages/index）**：节律内容集 4 组——慢稳 50 BPM·目标 16 步／日常 60·20／门口短程 72·12／长廊 56·24，每组带适用场景；下方实时显示历史汇总（次数/走起来次数/累计步数）。
- **提示进行（pages/cue）**：节拍器按所选 BPM 推进节律线（20 格方块），TTS 每 4 拍报数、每 8 步报步数。记步接线：AbsoluteOrientationSensor 的 pitch 下探（开始时以当前姿态为中心校准，下探→回正记一步）；无传感器时明示以镜腿单击记步，不伪装。结算规则：达到目标步数 → 「走起来了」；超过时限（目标 × 120 / BPM 秒）→ 「超时休息」，语音先扶稳再休息；手动停下也如实入账。
- **会话记录（pages/record）**：每次会话（日期/节律/步数/结果）与累计步数跨会话持久化（wx storage `freezeStepCueV2`），本人可清空。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 选节律页开始／提示页在无传感器时记步 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 切换节律组 |
| 点头 | `onHeadGesture('nod')` | 选节律页开始提示 |
| 头部下探→回正 | AbsoluteOrientationSensor pitch | 记一步 |
| 双击 | Backspace | 系统返回（子页 BACK 键亦可） |

## 权限

无。传感器与 wx storage 不需要权限声明；TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## 诚实边界

- 生活辅助，不是医疗判断：不评估病情、不给治疗建议；「走起来了」只表示本次会话达到自设目标步数。cue 页常驻提示：头晕或站不稳，立刻停下扶稳。
- 预览截图中提示页步数为 0：Web 运行时传感器无头部下探动作，记步不触发——这是如实状态，不做演示造假。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | Freeze Step Cue（待导入后回填） |
| Version / Build | 2.0.0 |
| App Category | Life（待导入时确认） |
| Intent Description | 步态冻结时用节律线和拍子一步一拍走起来 |
| Agent ID | 待导入后回填 |
| 状态 | v2 已打包、已推送；未导入 Studio、未真机测试、未提审 |

## 提审资料 (Review Submission)

### Feature Description (≤500 chars)

A rhythm aid for gait freezing at doorways and lift entrances, rebuilt in v2 as three pages: four rhythm sets (50-72 BPM, 12-24 step targets), a cue page with a visible rhythm line and TTS counting that counts steps from head pitch dips on the orientation sensor, and honest settlement - target reached means walking, time limit means hold on and rest. Sessions persist. A life aid, not a medical judgement.

### Opening Message (≤500, Markdown)

**迈不开步的时候，先选一组节律。** 跟着线和拍子，一步，一步。走不起来，就先扶稳休息，不着急。

### Preview Media

图片 4 张（本页预览截图）；视频待真机阶段补（提审要求 3–5 个文件、≥1 图 ≥1 视频）。

### Change Log

#### Build 2.0.0
- Features added: 精品线合并重做裁定下的原地加厚——三页结构（节律选择/提示进行/会话记录）；节律内容集 4 组；节拍器与节律线实装；头部 pitch 记步接线（无传感器时单击记步并明示）；达标/超时/手动停下三种如实结算；会话跨会话持久化。
- Improvements: 结算规则由 v1 的本人单点确认，改为目标步数与时限双规则。
- Fixes: 废弃 v1 单页演示状态机形态（与探索舰队同模板的问题）。

#### Build 1.0.0
- Features added: 首版（单页节律提示，已由 v2 取代，记录保留备查）。
- Improvements: 无。
- Fixes: 无。

## 打包与预览

- 打包：`~/tools/bin/aix pack . -o freeze-step-cue.aix`（仓库副本在 `aix/freeze-step-cue.aix`）
- 预览：`~/tools/bin/aix preview . --html-out artifacts/preview.html` 后走本地截图管线（端口 8902）
