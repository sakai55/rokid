# stream-probe — Rokid 眼镜持续视频流探针（AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-stream-probe
```

为回答「Rokid 的 Agent 能不能持续录像并像实时 AR 一样交互」而建的探针：不预设结论，在真机上量三个数——持续取流能跑成什么样、持续录制产出多少数据、抓一帧问大模型的往返要多久。

## 预览截图

截图统一存放于仓库根目录 `screenshots/stream-probe/`。

![首页（就绪状态）](../screenshots/stream-probe/preview-stream-probe-index.png)

![预览里跑完后的结果页（Web 预览用假摄像头：取流/录制可跑通但数值仅供参考，LLM 不可用记 SKIP；结论只认真机）](../screenshots/stream-probe/preview-stream-probe-done.png)

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 待回填（本地 package.json 1.0.1） |
| App Category | 待回填（建议 Work） |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| AIX Package Size | 约 12.7 KB（本地 pack；Studio 打包值待回填） |
| 状态 | 本地已打包 · 待 GO 在 Studio 导入并真机运行 |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 测试项

| # | 项目 | 测什么 |
|---|------|--------|
| 01 | 持续取流 | `getUserMedia` 视频流跑满 60 秒：`track.getSettings()` 实际分辨率/帧率、`grabFrame` 实测抓帧率与帧间最大间隔、失败次数、起止电量 |
| 02 | 持续录制 | `MediaRecorder` 录像 30 秒（mp4 优先）：分片数、总字节、折算 MB/分钟；数据只在内存、测完即弃（平台无文件 API，录像无法落盘） |
| 03 | 抓帧问大模型 | 3 轮抓帧→LLM：优先 grabFrame→Canvas 缩图→JPEG→data: URL 路径，不可用回退 telephoto 拍照并标明来源；分段报告抓帧与 LLM 往返耗时 |

状态：PASS / FAIL / SKIP（API 不存在或主机不支持）。单击开始后顺序跑完三项，约 2 分半；每项测完语音播报结果。运行中单击 = 中止当前项，按已测部分如实报告。

预期判读：取流项若 60 秒抓帧率稳定且最大间隔不爆，说明「前台采样式伪实时」可行；录制项给出持续录像的真实数据率与内存代价；视觉项的 LLM 往返均时就是「拍照式 AR」每一步的最低延迟——这三项共同决定实时 AR 类玩法能做到哪一步。

## 操作方式（镜腿手势映射）

| 手势 | 键事件 | 作用 |
|---|---|---|
| 单击 | Enter / GlobalHook | 开始探测；运行中单击 = 中止当前项（跑完 2 秒内的单击忽略，防重复触发） |
| 点头 | onHeadGesture 'nod' | 只记录事件，不触发动作 |
| 滑动 | ArrowUp / ArrowDown | 本页无滚动，未占用 |
| 双击 | Backspace | 交给系统：返回 / 退出（页面不拦截） |

## 权限与边界

- 权限：`CAMERA` 一项（平台只有 GEOLOCATION / CAMERA / RECORD_AUDIO 三种权限；本探针不用定位与麦克风）。
- 除 LLM 图片输入走宿主托管通道外，不上传任何数据；录制与抓帧数据不落盘。
- 每项单独取流、测完立即释放轨道。用完必须 stop 是平台的资源生命周期红线，也是「不能后台常录」的实证之一。

## 本地命令

```bash
~/tools/bin/aix pack . -o stream-probe.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 提审资料 (Review Submission)

本 Agent 是开发探针，不计划提审上架；以下按 SOP 留档。

### Feature Description

视频流探针：真机实测 Rokid 眼镜 Agent 的持续取流抓帧率、MediaRecorder 录像数据率与抓帧到大模型往返延迟，为实时 AR 类玩法的可行性提供实测依据。

### Opening Message

单击镜腿开始探测：60 秒持续取流、30 秒持续录制、3 轮抓帧问大模型，约两分半出全部实测数值。

### Preview Media

- 图片：`screenshots/stream-probe/preview-stream-probe-index.png`、`preview-stream-probe-done.png`
- 视频：真机阶段补录（探针不提审，可略）

### Change Log

#### v1.0.0

- Features added：三项视频链路探针（持续取流 60s / 持续录制 30s / 抓帧→LLM 3 轮），LIVE 实时读数行，每项结果语音播报
- Improvements：—
- Fixes：—

#### v1.0.1

- Features added：—
- Improvements：—
- Fixes：删除 FileReader（Ink 运行时不存在，原第 03 项的抓帧路径在真机必然回退）：Blob→dataURL 改走官方文档路径 `blob.arrayBuffer()` + 分块 `btoa`，使 grabFrame 路径成为实际被测路径，失败仍按来源如实回退/标注并接全局错误码 E2005。
