# stream-probe

Rokid 眼镜持续视频流探针（AIUI Agent）。为回答「Agent 能不能像实时 AR 一样持续录像并交互」而建：不做产品功能，只在真机上量出三个数。

## 身份

一个运行在 Rokid 眼镜上的视频链路探测工具。单击镜腿开始，顺序跑三项，每项测完语音播报结果，全部数值显示在屏幕上供截图留档。

## 测试项

- **01 持续取流（60 秒）**：`getUserMedia({video})`（理想约束 640×480@30，被拒时回退 `{video:true}` 并在结果中标明）→ 读 `track.getSettings()` 报告实际分辨率/帧率 → 循环 `ImageCapture.grabFrame()` 计数：实测抓帧率（注意：这是 Agent 抓帧速率，不是传感器帧率）、帧间最大间隔、失败次数 → 起止电量（`navigator.getBattery()`，不支持时略）。
- **02 持续录制（30 秒）**：新取一路流 → `MediaRecorder`（先查 `isTypeSupported`：`video/mp4` 优先，其次 `video/webm;codecs=vp8,opus`，都不支持记 SKIP）以 1 秒 timeslice 录制 → 分片数、总字节、折算 MB/分钟、错误数。录制数据只在内存中，测完即弃——平台无通用文件 API、录像无法落盘，这本身就是结论之一。
- **03 抓帧问大模型（3 轮）**：优先走真 AR 帧路径：`grabFrame()` → 脚本 Canvas 缩至 480 宽 → `convertToBlob` JPEG → FileReader 转 data: URL → `LanguageModel` 图片输入；任一步不可用则回退 `takePhoto({mode:'telephoto'})`（舰队已验证路径），并在结果中标明来源（grabFrame / takePhoto），两种来源的耗时不混报。分段报告：抓帧均时、LLM 往返均时、最后一轮的回答摘要。

## 操作（镜腿手势优先）

- 界面只有一个按钮「开始探测」。单击镜腿（Enter / GlobalHook）= 开始；运行中单击 = 中止当前项（按已测部分如实报告，标「部分」），随后自动进入下一项。
- 防重复：Enter 与 GlobalHook 的重复投递在 400ms 内去重；一轮跑完 2 秒内的单击忽略（沿用 glasses-benchmark v2.0.1 的教训，防止刚跑完又自启）。
- 点头只记录事件，不触发任何动作（屏幕事件行可见）。
- 双击（Backspace）= 交给系统（返回/退出），页面不拦截。
- 屏幕按钮同时保留 bindtap，供 Studio 模拟器/预览里用鼠标点击。

## 行为边界

- 只做本机探测：除 LLM 图片输入（宿主托管通道）外不上传任何数据；录制与抓帧数据不落盘、不外发。
- 每项单独取流，测完立即 stop 全部轨道；权限只有 `CAMERA`（无独立的视频/ASR 权限存在）。
- 权限被拒或 API 不存在时记 FAIL/SKIP 并写明原因，不崩溃、不假装通过。预览（Web 运行时）用的是假摄像头：取流/录制能跑通但数值（帧率/码率）只是宿主假设备的，不作结论；LLM 在预览不可用记 SKIP——结论只认真机结果。
- 已知未知：AIUI 官方未公布视频流的保证帧率与最长持续时长，本探针测的就是真机实测值，不预设结论。
