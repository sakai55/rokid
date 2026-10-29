# Left Home Proof（出门证据回放 Home Proof）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-left-home-proof
```

**AIX 直接下载**（最新版）：[left-home-proof.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/left-home-proof.aix)

CC11 · 路缘坡（CC）。轻度失智/健忘者出门后焦虑“燃气关没、门锁没”时，用出门前拍下的证据回放断循环。交互哲学：**出门证据回放 Home Proof**。

## 预览截图

![预览-index](<../screenshots/left-home-proof/preview-left-home-proof-index.png>)
![预览-s2](<../screenshots/left-home-proof/preview-left-home-proof-s2.png>)
![预览-s3](<../screenshots/left-home-proof/preview-left-home-proof-s3.png>)
![预览-s4](<../screenshots/left-home-proof/preview-left-home-proof-s4.png>)

## 方向构成

- 本 Agent 的方向构成：路缘坡（CC）。每个方向在场景里承担不可替代的一环，非功能拼盘（日本组概念按精品线组合通则判定；自由组概念按场景核心定主方向编号）。
- 一句话场景：轻度失智/健忘者出门后焦虑“燃气关没、门锁没”时，用出门前拍下的证据回放断循环。

## 功能流程（闭环）

- 进入：打开即显示当前项与进度，当前项大字在视线中央。
- 过程：NEXT 选下一项、PROOF 确认当前项、PREV 回上一项；点头（头稳时）等价于主确认；SPEAK 随时播报当前状态。
- 结果：全部项确认后计一轮（周回/完成数 +1），可反复使用；DEMO 演示状态机，退出后真实状态原样恢复。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（确认当前项 / 播报） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 PROOF 等价） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用 |

## 诚实边界

- 存证是本人的确认记录，不是传感器或照片的自动判定；照片（如有）仅作本人回看。
- 本 Agent 不判断燃气/电器是否真正安全，有疑虑时以现场检查为准。

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明不生效）。
- 绿色色阶：CSS 只用绿色色阶，禁用纯白与白色 rgba；按钮样式随本 Agent 的 UI 形态定型，不共用默认按钮。

## 打包与预览

```bash
cd ~/workspace/rokid/git-rokid/curb-cut/left-home-proof
~/tools/bin/aix pack . -o ../../aix/left-home-proof.aix
~/tools/bin/aix list ../../aix/left-home-proof.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Left Home Proof（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | Left home proof: for people who loop back home doubting the gas or the lock. Check each point before leaving, then replay one dated proof in sight afterwards: you saw it, it was off. Evidence ends the loop, not another reminder. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Left home proof: for people who loop back home doubting the gas or the lock. Check each point before leaving, then replay one dated proof in sight afterwards: you saw it, it was off. Evidence ends the loop, not another reminder.

### Opening Message

> ## Left Home Proof
>
> Left home proof: for people who loop back home doubting the gas or the lock. Check each point before leaving, then replay one dated proof in sight afterwards: you saw it, it was off. Evidence ends the loop, not another reminder.

### Preview Media

- `preview-left-home-proof-index.png` — 初始状态
- `preview-left-home-proof-s2.png` — 演示状态 2
- `preview-left-home-proof-s3.png` — 演示状态 3
- `preview-left-home-proof-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：出门证据回放 Home Proof；轻度失智/健忘者出门后焦虑“燃气关没、门锁没”时，用出门前拍下的证据回放断循环

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
