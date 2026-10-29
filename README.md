# TR04 Trace Origami · 折纸描红

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-trace-origami
```

**AIX 直接下载**（最新版）：[trace-origami.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/trace-origami.aix)

描红系列 TR04：中央范本 + 边上步骤 + 做一步验一步。照着眼镜一步步折完一件折纸作品：每步范本是 Canvas 自绘的折形图（本步折线最亮），折完把纸举到眼前拍照验形，只查粗项，过了才进下一步；折错当步就知道，不等成品散架。

## 功能（6 页闭环）

| 页 | 内容 |
|---|---|
| 今日（工坊） | 没折完的作品优先续折、今日推荐（按日期轮换）、作品集总进度 |
| 作品集 | 8 件作品分页陈列：难度、步数、完成次数、折到第几步；半成品从断点续折 |
| 折叠 | 中央折形图逐歩呈现：纸面轮廓暗绿、被折纸片中绿、本步折线最亮绿；右侧折法名 + 本步要点，TTS 同步念；可回看上一步（只看不改进度） |
| 验形 | 把这一步举到眼前拍照，LLM 对照本步目标折形粗查三项：轮廓大形、多边少边、折线方向反没反；看不清如实说、重拍；「算过，进下一步」才推进度，机器说不过而本人坚持进会记改判 |
| 成品结算 | 已验步数、本轮改判次数；全部验完直接结算，没验完可本人改判结算（如实记 partial，不冒充全验） |
| 进度 | 逐件完成次数 / 断点 / 改判数、汇总与动手天数，跨会话保存 |

## 内容集（自撰，可数）

8 件作品共 63 步，每步在 `works.js` 里有折法名、操作要点、目标折形描述与折形多边形数据（轮廓 / 被折纸片 / 本步折线）：纸鹤 10 步、跳跳蛙 8 步、纸船 7 步、纸飞机 6 步、幸运星 8 步、气球兔 7 步、蝴蝶 8 步、纸盒 9 步。范本图为本系列自绘折形示意图，以轮廓与折线方向为准，不是精密折纸图纸；要点为自撰练习提示，不抄图库与折纸书图。

## 方向性 / 交互

核心 = SCAN（逐步拍照验形）+ HEAD（点头执行 / 验形页点头拍照）。手势：点头 = 执行焦点；单指点按 = 确认（Enter）；上下滑 = 切焦点 / 翻页；双击 = 返回（Backspace）。折叠页 TTS 同步念每步要点。按钮为纸签式（直角 + 左侧亮绿粗边条），呼应折痕虚线框。

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | 每步折完后拍纸面折形，转 data URL 给 LLM 图片输入粗查 |

## 错误码

本台遵循全局错误码表（仓库根 `ERROR-CODES.md`，裸码 `E####`）。出错时屏显裸码 + 一行说明，最近一次错误保存在 `lastError`（含码、slug、版本、原文截断）。回报问题时请带上眼镜上显示的码。
本台用到：E1001 相机打开失败、E1002 相机权限未给、E1003 拍照器不可用、E1007 相机设备不存在、E1009 拍照失败、E2002 画布创建失败、E2013 文本编码失败、E5001 记录保存失败、E5002 记录读取失败、E6001 大模型不可用、E6002 大模型请求失败、E6011 大模型输出不可用、E8001 页面切换失败、E9001 未分类错误。

## 真机信息

| 项 | 值 |
|---|---|
| Studio name | （待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | （待导入后回填） |
| Intent Description | 折纸描红：8 件作品 63 步逐折范本，逐步拍照粗查三项，本人改判，断点续折 |
| Agent ID | （待导入后回填） |
| 状态 | 已打包，待 GO 导入真机测试（提审等 GO 确认真机测试完成） |

## 打包 / 预览命令

```bash
~/tools/bin/aix pack . -o trace-origami.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 预览截图

（Web 预览渲染：折形图为真实分步数据绘制；验形页无相机时如实显示待拍状态。）

![今日页](../../screenshots/trace-origami/preview-trace-origami-index.png)
![作品集页](../../screenshots/trace-origami/preview-trace-origami-gallery.png)
![折叠页](../../screenshots/trace-origami/preview-trace-origami-fold.png)
![验形页](../../screenshots/trace-origami/preview-trace-origami-check.png)
![成品结算页](../../screenshots/trace-origami/preview-trace-origami-finish.png)
![进度页](../../screenshots/trace-origami/preview-trace-origami-progress.png)

## 提审资料 (Review Submission)

- **Feature Description**（≤500 字）：折纸描红练习：8 件折纸作品共 63 步，每步的折形范本浮在眼前（本步折线最亮），照着在真纸上折，折完把纸举到眼前拍照，只查轮廓大形、多边少边和折线方向，过了才进下一步；判定可由本人改判，半成品下次续折，完成次数跨会话保存。
- **Opening Message**：今天折一件：一步一折，一折一验，折错当步就知道。
- **Preview Media**：见「预览截图」6 张（图片）；视频待真机阶段补（提审需 3–5 个文件、含 ≥1 视频 ≤60s）。
- **Change Log**（Build 1.0.0）：Features added — 6 页闭环（今日 / 作品集 / 折叠 / 验形 / 成品结算 / 进度）、8 件作品 63 步折形数据、逐步拍照粗查三项、TTS 要点、本人改判与 partial 结算、断点续折与跨会话进度；Improvements — 无；Fixes — 无。
