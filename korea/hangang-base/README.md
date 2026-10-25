# Hangang Base（汉江营地持有）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-hangang-base
```

KR05 · 韩国本地化系列。交互哲学：**营地持有 Basecamp Holder**。本 Agent 是坐在垫子上的那个人：交付点暗号、取餐号、垫子归还时刻、片付け四件套，全钉在垫面四格里。你去浪，它替你坐着记；回来瞥一眼，四格状态尽收眼底。它不导航去交付点（底座导航的事）、不替你点外卖，只持有「营地信息」这一件事——这正是出门玩时最容易被快乐冲散的注意力。

## 预览截图

![预览-index](<../../screenshots/hangang-base/preview-hangang-base-index.png>)
![预览-s2](<../../screenshots/hangang-base/preview-hangang-base-s2.png>)
![预览-s3](<../../screenshots/hangang-base/preview-hangang-base-s3.png>)
![预览-s4](<../../screenshots/hangang-base/preview-hangang-base-s4.png>)

## 在地性

周末的한강공원（汉江公园）有一套成熟玩法：铺돗자리（垫子）占位、点外卖到指定交付点自取、吃完把垫子与垃圾按规矩收走。营地一铺，人就四散——拍照的、放风筝的、去取餐的，最后全靠一个人记着所有琐事。

## 功能流程（闭环）

- 四格：暗号（交付点コード）/取餐号/垫子归还时刻/片付け进度，垫面格即信息格
- 轮换：CODE 换交付点暗号预设、FOOD# 取餐号 +1、 CLEAN 片付け四件套逐件推进
- 宣告：GO 轮流播报四格现状；归还时刻到点由计时提醒（页面内存计时，明示）

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 CODE 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 暗号与号牌为演示预设，实际请在 CODE/FOOD# 登记为当次真实值后使用（登记即显示，关页即忘）
- 归还提醒是本页计时，不是系统闹钟；页面被关闭后不保证触达，重要归还请同时设手机提醒

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/hangang-base
~/tools/bin/aix pack . -o ../dist/hangang-base.aix
~/tools/bin/aix list ../dist/hangang-base.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Hangang Base（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a Hangang park picnic: holds delivery code, pickup number, return time and cleanup progress on a mat grid. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Hangang picnic basecamp holder: your mat as four cells - delivery-point code, pickup number, mat return time, cleanup progress. You wander off; the basecamp sits and remembers. Tap GO and it reads the four cells aloud. No navigation, no ordering - it holds the spot's information, nothing more.

### Opening Message

> ## Hangang Base
> 
> The mat is basecamp, and basecamp forgets nothing: delivery code, pickup number, return time, cleanup. Wander as far as you like - one glance at the mat, or one tap, and the whole camp reports in.

### Preview Media

- `preview-hangang-base-index.png` — 初始状态
- `preview-hangang-base-s2.png` — 演示状态 2
- `preview-hangang-base-s3.png` — 演示状态 3
- `preview-hangang-base-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：营地持有 Basecamp Holder；俯视野餐垫：垫面四格分别放暗号、号牌、归还与片付け

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
