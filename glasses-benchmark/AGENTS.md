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
- 麦克风：设备枚举 + 1 秒录音（MediaRecorder）
- 相机：取流 + ImageCapture 拍照（失败时回退 wx CameraContext）
- 传感器：加速度计、陀螺仪、绝对方向
- 定位：navigator.geolocation 单次定位
- 蓝牙：BLE 可用性 + 已配对设备
- 电池：BatteryManager 电量/充电状态（主机不支持时 SKIP）
- 语音合成 TTS：synthesize 生成 + 手动 SPEAK 播放确认
- 语音识别 ASR：能力查询 + 手动 LISTEN 实时识别
- 大模型：LanguageModel 可用性 + 一次短推理耗时
- 条码：BarcodeDetector 支持格式
- 交互（被动）：按键、头部手势、语音唤醒事件监听

## 行为边界

- 只做本机自检，不上传任何数据；唯一的网络请求是取 example.com 首页测延迟。
- 麦克风/相机/定位在用户点击运行时才启动，用完立即释放轨道与传感器。
- 权限被拒或硬件不支持时记为 FAIL/SKIP 并写明原因，不崩溃、不假装通过。
