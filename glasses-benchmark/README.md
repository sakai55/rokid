# glasses-benchmark — Rokid 眼镜全功能 Benchmark（AIUI Agent）

第一个开发测试智能体：一键跑完 Rokid 眼镜在 AIUI 下的全部功能，共 21 项。

## 测试项

| # | 项目 | 测什么 |
|---|------|--------|
| 01 | Device | navigator 身份 / Ink·Skia 版本 / 语言 / 地区 |
| 02 | Display | 视口尺寸 / 渲染开关 / 12 次连续重绘 |
| 03 | CPU | 30 万次数学循环吞吐 (ops/s) |
| 04 | Crypto | getRandomValues + SHA-256 + randomUUID |
| 05 | Storage | localStorage + wx 同步存储读写 |
| 06 | Net Info | 在线状态 / 连接类型 / RTT / 下行估算 |
| 07 | Net Fetch | HTTPS 请求 example.com 往返 |
| 08 | Canvas 2D | 渐变 / 图形 / 文字 / flush（画布直接可见） |
| 09 | Audio Out | Web Audio 880Hz 振荡器（扬声器） |
| 10 | Microphone | 设备枚举 + 0.9 秒录音字节数 |
| 11 | Camera | 取流 + 拍照字节数（回退 wx CameraContext） |
| 12 | Accel | 加速度计读数 |
| 13 | Gyro/Ori | 陀螺仪 + 绝对方向四元数 |
| 14 | Geolocation | 单次定位 + 精度 |
| 15 | Bluetooth | BLE 可用性 + 已知设备数 |
| 16 | Battery | 电量 + 充电状态（不支持时 SKIP） |
| 17 | TTS Synth | speechSynthesis.synthesize；SPEAK 按钮做真人耳确认 |
| 18 | ASR Caps | 识别能力查询；LISTEN 按钮做实时识别 |
| 19 | LLM | LanguageModel 可用性 + 一次短推理 |
| 20 | Barcode | BarcodeDetector 支持格式 |
| 21 | Interaction | 按键 / 点头手势 / 语音唤醒（被动监听，触发即 PASS） |

状态：PASS / FAIL / SKIP（硬件或主机不支持）/ MANUAL（需人触发）。
点任意一行可单独重跑该项；RUN ALL 顺序跑完 01–20。

## 打包

```bash
~/tools/bin/aix pack . -o ../dist/glasses-benchmark.aix
~/tools/bin/aix preview .
```

## 真机测试（路径一）

1. 推到 GitHub → Global AIUI Studio 从 GitHub 导入
2. Studio「构建与提审」打包保存新版本
3. Rokid AI App → 设置 → 开发者选项 → AIUI → 更新眼镜资源包
4. 对眼镜说「乐奇，打开 glasses-benchmark」，点 RUN ALL

注意：07 Fetch 需要眼镜联网（经手机蓝牙/Wi-Fi）；14 定位、10/11 麦克风/相机
第一次会弹系统授权，拒绝会记 FAIL 并写明原因——这正是要测的。
