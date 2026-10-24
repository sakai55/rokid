# glasses-benchmark

Rokid 眼镜全功能基准测试智能体（AIUI Agent）。

## 身份

一个运行在 Rokid 眼镜上的硬件/运行时自检工具。打开后点「RUN ALL」，
按顺序对眼镜的全部 AIUI 功能逐项打分，最后给出 PASS / FAIL / SKIP 汇总。

## 能力（测试项）

- 设备信息：navigator 身份、语言、地区、Ink/Skia 版本
- 显示：视口尺寸、渲染开关、连续重绘耗时
- 算力：JS 数学循环吞吐
- 加密：Web Crypto 随机数 + SHA-256
- 存储：localStorage + wx 同步存储读写
- 网络信息：在线状态、连接类型/质量
- 网络请求：HTTPS fetch 往返耗时
- Canvas 2D：渐变、图形、文字绘制 + flush
- 音频：Web Audio 振荡器发声（扬声器链路）
- 麦克风：设备枚举 + 四种官方麦克风模式逐个探测（wearer / far-field / near-field / omnidirectional，不支持的模式记为不支持而非失败）+ wearer 模式 0.9 秒录音
- 相机：取流 + ImageCapture 三种官方模式各拍一张（wide 扫码 / telephoto 远读 / default），解码报告实际像素（失败时回退 wx CameraContext，该路径无模式参数）
- 传感器：加速度计、陀螺仪、绝对方向
- 定位：navigator.geolocation 单次定位
- 蓝牙：BLE 可用性 + 已配对设备
- 电池：BatteryManager 电量/充电状态（主机不支持时 SKIP）
- 语音合成 TTS：synthesize 生成 + 手动 SPEAK 播放确认
- 语音识别 ASR：能力查询 + 手动 LISTEN 实时识别
- 大模型：LanguageModel 可用性 + 一次短推理耗时
- 条码：BarcodeDetector 支持格式
- 交互（被动）：按键、头部手势（点头）、头部朝向稳定性、语音唤醒事件监听
- 平台边界（恒为 SKIP，永不 PASS）：眼动追踪——平台无此 API，「凝视」=头部朝向（绝对方向传感器）+头稳+点头；OCR——平台无 OCR API，读文字的官方路径是 telephoto 拍照 + LLM 图片输入

## 操作（镜腿手势优先）

- 单击镜腿（Enter / GlobalHook）= 触发当前焦点，打开页面时焦点默认在 RUN ALL，单击即开跑。
- 滑动（ArrowUp / ArrowDown）= 在 RUN ALL / SPEAK / LISTEN / 23 个测试行之间移动焦点（高亮显示，列表自动滚动到焦点行），单击焦点行即单独重跑该项。
- 点头（onHeadGesture 'nod'）= 与单击相同，触发当前焦点。
- 双击（Backspace）= 交给系统（返回/退出），页面不拦截。
- 屏幕上的按钮同时保留 bindtap，供 Studio 模拟器/预览里用鼠标点击。

## 行为边界

- 只做本机自检，不上传任何数据；唯一的网络请求是取 example.com 首页测延迟。
- 麦克风/相机/定位在用户点击运行时才启动，用完立即释放轨道与传感器。
- 权限被拒或硬件不支持时记为 FAIL/SKIP 并写明原因，不崩溃、不假装通过。
