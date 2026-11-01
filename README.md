# 现实合影（trace-reality）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-trace-reality
```

**AIX 直下（最新版）**：[trace-reality.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/trace-reality.aix)

描红系列的现实合成变体：描红壳是「范本浮在眼前、对齐了再验」，这一台把范本换成**贴纸式叠加**——气泡、名牌、横幅摆在真人头上，进纯净页后用手机 App 截图，系统把眼镜画面与现实景象合成一张照片。本台自己不拍照、不合成，合成是系统截图做的；它负责把叠加画对位置、把纯净画面交出来。

## 场景（6 种预置，台词可换）

| 场景 | 叠加画法 | 预置台词 |
|---|---|---|
| 对话气泡 | 圆角气泡 + 向下尾巴，准星对头顶 | 6 句 |
| 双人对话 | 左右双气泡，一人一句 | 4 对 |
| 心声吐槽 | 虚线云朵气泡 + 小圆点 | 6 句 |
| 头衔名牌 | 名牌 + 向下尖角 | 6 块 |
| 庆祝横幅 | 画面上方横幅 + 双星 | 6 条 |
| 纪念相框 | 全幅相框 + 底部字幕条（台词 + 自动日期） | 5 条 |

流程：选景 → 选台词（预置点选，或按「说一句」语音现说，存入「我的句子」跨会话复用；大小三档）→ 取景页对位（准星对准头顶）→ 纯净页倒数 3-2-1 后只剩叠加画 → 这时按 App 截图合成 → 完成页去相册验图。

## 如实边界

- 合成靠系统截图（Hi Rokid App 截图把屏幕画面与现实合成）；若截图设置只截屏幕不带现实，出来的是黑底叠加图。本台无法代按截图、也无法知道你是否按了——完成页只统计「纯净画面展示次数」。
- 平台没有人脸/人体识别 API，对位全靠用户转头把准星对准头顶；没有自动对准。
- 眼镜是透视显示，画布黑底在真机上等于透明；气泡填充为半透明绿，让现实透出来、字又读得清。

## 交互（手势优先）

上下滑动/方向键移动焦点，单击/Enter/点头执行焦点项，双击/Backspace 返回。选词页的焦点贯穿预置句与动作（说一句、说 B 句、换大小、去取景），全程不用点按钮；取景页 Enter 进纯净页、下键去完成页；纯净页任意键退出。

## 权限

- `RECORD_AUDIO`：仅用于「说一句」的语音输入（宿主 SpeechRecognition，存在性守卫；不可用时预置句库照常全流程可用）。
- 不申请相机：本台不拍照（合成由系统截图完成）。

## 错误码

本台可报的裸码（定义只在 `err.js`，全局表见仓库根 `ERROR-CODES.md`）：

- E3001 语音识别不可用 / E3002 语音识别没启动 / E3003 语音识别出错
- E5001 记录保存失败 / E5002 记录读取失败
- E8001 页面切换失败 / E9001 未分类错误

失败时写 `lastError`（码 + slug + 版本 + 原文截断）；纯净页绘制失败保持黑屏、不出错误字。

## 真机测试信息

| 项 | 值 |
|---|---|
| Studio 名称 | （待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | （打包时选定后回填） |
| Intent Description | 现实合影：给真人叠加气泡台词并用系统截图合成照片 |
| Agent ID | （待回填） |
| 状态 | 已建成，待 GO 真机测：重点验系统截图是否真把叠加与现实合成 |

## 预览截图

![选景页](../../screenshots/trace-reality/preview-trace-reality-index.png)
![选台词页](../../screenshots/trace-reality/preview-trace-reality-edit.png)
![取景页（对话气泡）](../../screenshots/trace-reality/preview-trace-reality-frame.png)
![纯净页（只剩叠加）](../../screenshots/trace-reality/preview-trace-reality-clean.png)
![完成页](../../screenshots/trace-reality/preview-trace-reality-done.png)
![我的句子](../../screenshots/trace-reality/preview-trace-reality-lines.png)
![说明页](../../screenshots/trace-reality/preview-trace-reality-about.png)
![取景页（头衔名牌）](../../screenshots/trace-reality/preview-trace-reality-frame-plate.png)
![取景页（纪念相框）](../../screenshots/trace-reality/preview-trace-reality-frame-keepsake.png)

## 提审资料 (Review Submission)

### Feature Description

现实合影：把对话气泡、双人台词、心声云朵、头衔名牌、庆祝横幅、纪念相框六种叠加摆到真人身上，取景对位后进入无任何按钮文字的纯净画面，用手机 App 截图把眼镜画面与现实合成一张照片。台词可从预置句点选，也可语音现说并保存复用；大小三档；全程手势操作。

### Opening Message

对着朋友选个气泡吧——把台词摆到他头上，进纯净页截图，一张和现实的合影就成了。

### Preview Media

- 图片：本页预览截图 9 张（见上）
- 视频：（真机阶段补）

### Change Log

#### v1.0.0

- Features added：六种预置叠加场景（气泡/双人对话/心声/名牌/横幅/相框）与各自预置台词；取景对位（准星 + 画角）与纯净页（倒数后无任何 UI 元素）；语音现说台词并存入「我的句子」跨会话复用；大小三档；纯净展示计数。
- Improvements：—
- Fixes：—
