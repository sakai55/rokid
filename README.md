# High Shelf Ask（高层货架求助话 Shelf Ask）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-high-shelf-ask
```

CC09 · 路缘坡（CC）。轮椅/坐姿人群在超市够不着高层货架时，锁定一件商品并生成一句准确求助话。交互哲学：**高层货架求助话 Shelf Ask**。

## 预览截图

![预览-index](<../screenshots/high-shelf-ask/preview-high-shelf-ask-index.png>)
![预览-s2](<../screenshots/high-shelf-ask/preview-high-shelf-ask-s2.png>)
![预览-s3](<../screenshots/high-shelf-ask/preview-high-shelf-ask-s3.png>)
![预览-s4](<../screenshots/high-shelf-ask/preview-high-shelf-ask-s4.png>)

## 方向构成

- 本 Agent 的方向构成：路缘坡（CC）。每个方向在场景里承担不可替代的一环，非功能拼盘（日本组概念按精品线组合通则判定；自由组概念按场景核心定主方向编号）。
- 一句话场景：轮椅/坐姿人群在超市够不着高层货架时，锁定一件商品并生成一句准确求助话。

## 功能流程（闭环）

- 进入：打开即显示当前项与进度，当前项大字在视线中央。
- 过程：NEXT 选下一项、GOT 确认当前项、PREV 回上一项；点头（头稳时）等价于主确认；SPEAK 随时播报当前状态。
- 结果：全部项确认后计一轮（周回/完成数 +1），可反复使用；DEMO 演示状态机，退出后真实状态原样恢复。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（确认当前项 / 播报） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 GOT 等价） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用 |

## 诚实边界

- 商品位置是本人登记的层位，不是相机测量的结果；相机不参与定位。
- 求助话由本人确认后才代说；店员是否取货以实际为准。

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明不生效）。
- 绿色色阶：CSS 只用绿色色阶，禁用纯白与白色 rgba；按钮样式随本 Agent 的 UI 形态定型，不共用默认按钮。

## 打包与预览

```bash
cd ~/workspace/rokid/git-rokid/curb-cut/high-shelf-ask
~/tools/bin/aix pack . -o ../../aix/high-shelf-ask.aix
~/tools/bin/aix list ../../aix/high-shelf-ask.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | High Shelf Ask（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | High shelf ask: for wheelchair and seated shoppers, a high shelf is visible but out of reach. Lock one item, get one exact ask sentence for staff, spoken aloud or shown large, and mark it taken only when it is really in hand. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> High shelf ask: for wheelchair and seated shoppers, a high shelf is visible but out of reach. Lock one item, get one exact ask sentence for staff, spoken aloud or shown large, and mark it taken only when it is really in hand.

### Opening Message

> ## High Shelf Ask
>
> High shelf ask: for wheelchair and seated shoppers, a high shelf is visible but out of reach. Lock one item, get one exact ask sentence for staff, spoken aloud or shown large, and mark it taken only when it is really in hand.

### Preview Media

- `preview-high-shelf-ask-index.png` — 初始状态
- `preview-high-shelf-ask-s2.png` — 演示状态 2
- `preview-high-shelf-ask-s3.png` — 演示状态 3
- `preview-high-shelf-ask-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：高层货架求助话 Shelf Ask；轮椅/坐姿人群在超市够不着高层货架时，锁定一件商品并生成一句准确求助话

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
