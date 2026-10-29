# Baedal Code（外卖暗号保险箱）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-baedal-code
```

**AIX 直接下载**（最新版）：[baedal-code.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/baedal-code.aix)

KR10 · 韩国本地化系列。交互哲学：**逐字保险箱 Digit Vault**。本 Agent 是只开一条缝的保险箱：四位暗号住在四个数位框里，REVEAL 一次只翻开一位，8 秒后自动合上；GO 永远不播报数字本身（防喊出来），只播报操作指引。订单号在另一格（ORDER 切换显示）。WIPE 一键销毁，全部状态只活在页面内存——零存储调用，关页即忘，这既是隐私设计也是诚实边界：它丢了就是丢了，请同时记住自己的密码。它不管外卖流程（平台 App 的事），只在骑手来电的那十秒里，把暗号安全地递到你眼前。

## 预览截图

![预览-index](<../screenshots/baedal-code/preview-baedal-code-index.png>)
![预览-s2](<../screenshots/baedal-code/preview-baedal-code-s2.png>)
![预览-s3](<../screenshots/baedal-code/preview-baedal-code-s3.png>)
![预览-s4](<../screenshots/baedal-code/preview-baedal-code-s4.png>)

## 在地性

韩国배달（外卖）文化与公寓生活咬合出一个高频小麻烦：공동현관（共用玄关）密码、세대玄关码、订单号——骑手到楼下打电话来问时，你正腾不出手翻手机，密码还不能当着旁边人喊出来。

## 功能流程（闭环）

- 登记：暗号为演示 4 位（真实使用时以当次订单码替换登记，README 有方法），常态全部以 ● 掩盖
- 揭示：REVEAL 逐位翻开（1 位/次），8 秒计时自动掩盖；GO 只播指引、永不读出数字
- 销毁：WIPE 清空暗号与订单显示；全程零存储 API 调用，关页即忘（代码可查）

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 REVEAL 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 演示暗号为假码；真实暗号请勿写进任何仓库文件，只在设备页面内登记（本页内存）
- 自动掩盖依赖本页计时，页面关闭后暗号直接消失（设计如此）；本 Agent 不与外卖平台联网

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/baedal-code
~/tools/bin/aix pack . -o ../dist/baedal-code.aix
~/tools/bin/aix list ../dist/baedal-code.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Baedal Code（待导入后回填） |
| Version / Build | 1.0.2 / 待导入后回填 |
| App Category | Life |
| Intent Description | When a delivery rider calls in Korea: reveals a gate/order code one digit at a time, auto-masking, zero storage. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Delivery code vault for Korean apartment life: your gate code lives behind four digit windows, revealed one digit at a time and auto-masked after 8 seconds. GO speaks guidance but never the digits. WIPE destroys it, nothing is ever stored - close the page and the code is gone by design.

### Opening Message

> ## Baedal Code
> 
> The rider is downstairs, your hands are full, and the gate code should not be shouted. I open one digit window at a time, eight seconds each, and I never say the number aloud. Wipe me, close me - I keep nothing.

### Preview Media

- `preview-baedal-code-index.png` — 初始状态
- `preview-baedal-code-s2.png` — 演示状态 2
- `preview-baedal-code-s3.png` — 演示状态 3
- `preview-baedal-code-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：逐字保险箱 Digit Vault；保险箱数位盘：四位数位框，一次只翻开一位

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）

### Change Log（Build 1.0.1）

**Features added**

- 无

**Improvements**

- 按钮按本 Agent 的 UI 形态单独定型（形态见设计契约），不再与全系列共用同一套按钮

**Fixes**

- 颜色对齐真机单色绿面板：原纯白 #ffffff 改为绿色色阶（最亮绿 #7dff9e），深浅只用绿色表现

### Change Log（Build 1.0.2）

**Features added**

- 无

**Improvements**

- 无

**Fixes**

- 语言纯化：界面与语音文案统一为本地语言（日本=日语 / 韩国=韩语），逐个排查清除了混入的日文、中文文案（含 SCAN 提示词）
