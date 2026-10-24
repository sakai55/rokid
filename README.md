# Trail Back（返程面包屑）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-trail-back
```

注意力外挂系列 E04（AMBIENT 环境型，本组第四个，系列第 49 个）。商场/展馆/大停车场逛一圈，回去的路完全没印象。本 Agent 把「回去的路」外包出去：沿途关键路口看向停稳点 MARK 登记面包屑（朝向 + 画面），返程点 RETURN 按反向朝向逐点走回起点，每点点 ARRIVED 确认。

## 解决的问题

回去的路是凭印象猜的：逛的时候没记路口，返程每个岔口都要赌一把。本 Agent 管四件事：登记（沿途关键路口看向停稳点 MARK，记朝向 + 画面，最多 8 处）、返程（点 RETURN 从最后一处倒序引导，每点显示反向朝向 + 该点画面）、确认（每点到达点 ARRIVED，走到第一处即回到起点）、小结（登记几处、返程走了几处，确认后清空）。它不是导航——只负责让你返程时每个路口都有据可查。

## 注意力外挂设计（AMBIENT 环境型）

- **它不是导航**：本 Agent 没有室内定位、没有 GPS 路径规划。面包屑只是你登记的朝向 + 画面，不是地图；反向朝向是你登记朝向的反向提示，不是测出来的返程路线，这一点 UI 与本 README 如实写明。
- **照片只用于本次返程对照**：面包屑画面在 MARK 时拍一张（wide 模式），只帮你在返程时认出路口；照片会话内即弃，不存档、不上传，面包屑本身只留一个画面标签，不留图片文件。
- **路口是你自己判断登记的**：它不知道哪个路口关键——你觉得关键就 MARK，不觉得就不记；登记要看向停稳（头动时 MARK 拒绝），点头不能替你登记。
- **纠错便宜，销毁需确认**：登记页或返程页返回键回待机（本轮保留，START 恢复同一轮）；小结页返回键回原态（不删东西，小结重建）；确认（小结页点 END 或头稳点头）才清空本轮；没有 DEL 键。
- **为什么胸前设备做不了**：返程面包屑是「头部朝向 × 画面」的配对——胸前设备既不知道你看向哪个路口、也没法把「反向朝向 + 该点画面」钉在你眼前。路口登记、反向引导、逐点确认三条都只有头戴设备成立。

## 与邻近 Agent 的分工

- 注意力系列 `room-sweep`（C02）：出门前逐项扫视确认。本 Agent 不做离家检查：它的照片是返程对照标签，贴在路口面包屑上。
- 注意力系列 `cue-bag`（P04）：出门行李逐项确认门。本 Agent 不在出门前设门：它记录出去的路，让回来的路存在。
- 注意力系列 `light-change`（E01）：相机定时测光 + 低于阈值提醒开灯。本 Agent 不定时测光：它唯一的输入就是你在路口的 MARK。

## 功能流程

1. **开始（START）**：待机点 START 开始登记；头稳点头也可开始。
2. **登记（MARK）**：沿途关键路口看向停稳点 MARK，记一处面包屑（朝向 + 画面，最多 8 处）；头动时 MARK 拒绝。
3. **返程（RETURN）**：点 RETURN 从最后一处倒序引导，每点显示反向朝向 + 该点画面，开始时出声报一次第一目标。
4. **确认（ARRIVED）**：每点到达点 ARRIVED，自动走到前一点；走到第一处确认后即回到起点出小结。NEXT/PREV 只移动返程目标，不算确认。
5. **结束与小结（END）**：登记中或返程中点 END 出小结（登记几处、返程走了几处、是否回到起点）；返回键回去（不删东西），小结页点 END 或头稳点头确认后清空本轮。

## 权限

- CAMERA（`permissions: [\"CAMERA\"]`）：面包屑画面拍照需要相机。不录音、不定位。

## 手势映射

- 点按（tap / Enter）：待机 START 开始登记；登记中 Enter 记下一处；返程中 Enter 确认到达；小结页 END 确认清空。
- 双击（double-tap / Backspace）：返回上一态（登记/返程→待机保留本轮；小结→原态不删东西）。
- 滑动（swipe / ArrowUp-Down）：登记中在面包屑行间切换焦点；返程中 NEXT/PREV 移动返程目标。
- 头稳 + 点头（head-steady + nod）：待机开始登记；小结页确认清空；登记中与返程中的点头一律忽略（点头不是面包屑，也不是到达）。
- 单指长按：唤出 AI 语音助手（系统默认）；双指长按：AI 快捷指令（固定文本，零 ASR 启动）。

## 打包与预览命令

```bash
cd ~/workspace/rokid/trail-back
~/tools/bin/aix pack . -o ~/workspace/rokid/dist/trail-back.aix
~/tools/bin/aix list ~/workspace/rokid/dist/trail-back.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试信息（Studio 导入后回填）

| 项目 | 值 |
|---|---|
| Studio 名称 | （待回填） |
| Version / Build | 1.0.0 / （待回填） |
| App Category | （待回填） |
| Intent Description | （待回填） |
| Agent ID | （待回填） |
| 状态 | 未导入（SOP 第 9 步，GO 触发） |

## 预览截图

![待机：还没开始](../screenshots/trail-back/preview-trail-back-idle.png)
![登记中：DEMO 第 1 段，已登记 2 处](../screenshots/trail-back/preview-trail-back-marking.png)
![已登记多处：DEMO 第 2 段，已登记 3 处](../screenshots/trail-back/preview-trail-back-registered.png)
![返程反向引导中：DEMO 第 3 段，目标路口3反向前](../screenshots/trail-back/preview-trail-back-returning.png)
![回到第一处：DEMO 第 4 段，目标路口1，已走 2 处](../screenshots/trail-back/preview-trail-back-first.png)
![本次小结：DEMO 第 5 段，登记 3 处、返程 3 处、已回到起点](../screenshots/trail-back/preview-trail-back-summary.png)

## 提审资料 (Review Submission)

### Feature Description

返程面包屑外包：商场/展馆/大停车场逛一圈，沿途关键路口看向停稳点 MARK 登记面包屑（朝向 + 画面，最多 8 处），返程点 RETURN 按反向朝向逐点走回起点，每点点 ARRIVED 确认，走到第一处即回到起点，结束给小结。它不是导航——没有室内定位与路径规划，面包屑只是你登记的朝向与画面，照片会话内即弃。

### Opening Message

返程面包屑已就绪：点 START 开始登记，沿途关键路口看向停稳点一次 MARK——返程点 RETURN，我按反向朝向逐点带你走回起点，每点点 ARRIVED 确认，走到第一处就是起点，结束点 END 看登记几处、返程走了几处。

### Preview Media

- 图片：6 张（待机 / 登记中 / 已登记多处 / 返程反向引导中 / 回到第一处 / 本次小结），见「预览截图」节。
- 视频：真机录制后补齐（提审需 3–5 个文件，至少 1 图 + 1 视频）。

### Change Log

- Features added：路口面包屑登记（看向停稳 MARK，朝向 + 画面，最多 8 处）；返程反向引导（从最后一处倒序，每点反向朝向 + 画面，开始时出声报一次）；逐点确认（ARRIVED 确认并前进，走到第一处即回到起点）；本次小结（登记几处、返程走了几处、是否回到起点，确认后清空）。
- Improvements：无（首版）。
- Fixes：无（首版）。

## 如实说明

- **它不是导航**：平台没有室内定位、没有 GPS 路径规划，面包屑只是你登记的朝向 + 画面，不是地图；反向朝向是你登记朝向的反向提示，不是测出来的返程路线。
- **照片只用于本次返程对照**：MARK 时拍的画面只帮你在返程时认出路口，会话内即弃，不存档、不上传；面包屑本身只留画面标签，不留图片文件。
- **路口是你自己判断登记的**：它不知道哪个路口关键；登记要看向停稳，头动时 MARK 拒绝，点头不能替你登记。
- **只存本次会话**：面包屑、返程进度与小结都在会话内存里，关掉即清；不调用任何存储 API，零落盘。
