# Kasa Share（駅前シェア傘帳簿 Umbrella Ledger）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-kasa-share
```

JP14 · 日本在地 × 路缘坡 × 注意力（HOLD/WATCH）。雨天駅前、片手・車椅子の人がシェア傘を借りて返し忘れない。交互哲学：**駅前シェア傘帳簿 Umbrella Ledger**。

## 预览截图

![预览-index](<../screenshots/kasa-share/preview-kasa-share-index.png>)
![预览-s2](<../screenshots/kasa-share/preview-kasa-share-s2.png>)
![预览-s3](<../screenshots/kasa-share/preview-kasa-share-s3.png>)
![预览-s4](<../screenshots/kasa-share/preview-kasa-share-s4.png>)

## 方向构成

- 本 Agent 的方向构成：日本在地 × 路缘坡 × 注意力（HOLD/WATCH）。每个方向在场景里承担不可替代的一环，非功能拼盘（日本组概念按精品线组合通则判定；自由组概念按场景核心定主方向编号）。
- 一句话场景：雨天駅前、片手・車椅子の人がシェア傘を借りて返し忘れない。

## 功能流程（闭环）

- 进入：打开即显示当前项与进度，当前项大字在视线中央。
- 过程：NEXT 选下一项、RETURN 确认当前项、PREV 回上一项；点头（头稳时）等价于主确认；SPEAK 随时播报当前状态。
- 结果：全部项确认后计一轮（周回/完成数 +1），可反复使用；DEMO 演示状态机，退出后真实状态原样恢复。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（确认当前项 / 播报） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 RETURN 等价） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用 |

## 诚实边界

- 返却先・期限は本人の登録だけを守る。駅の傘在庫や返却可否は Agent は知らないし決めない。
- 返却済みは本人の確認だけが記す。Agent が返却を代行することはない。

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明不生效）。
- 绿色色阶：CSS 只用绿色色阶，禁用纯白与白色 rgba；按钮样式随本 Agent 的 UI 形态定型，不共用默认按钮。

## 打包与预览

```bash
cd ~/workspace/rokid/git-rokid/japan/kasa-share
~/tools/bin/aix pack . -o ../../aix/kasa-share.aix
~/tools/bin/aix list ../../aix/kasa-share.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Kasa Share（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | Kasa share: a borrowed station umbrella, kept on track. Register the return station, watch the return deadline, and mark it returned only when it is really back. It never guesses a station and never auto-returns anything. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Kasa share: a borrowed station umbrella, kept on track. Register the return station, watch the return deadline, and mark it returned only when it is really back. It never guesses a station and never auto-returns anything.

### Opening Message

> ## Kasa Share
>
> Kasa share: a borrowed station umbrella, kept on track. Register the return station, watch the return deadline, and mark it returned only when it is really back. It never guesses a station and never auto-returns anything.

### Preview Media

- `preview-kasa-share-index.png` — 初始状态
- `preview-kasa-share-s2.png` — 演示状态 2
- `preview-kasa-share-s3.png` — 演示状态 3
- `preview-kasa-share-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：駅前シェア傘帳簿 Umbrella Ledger；雨天駅前、片手・車椅子の人がシェア傘を借りて返し忘れない

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
