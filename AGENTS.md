# far-ear

Rokid 眼镜远听助手智能体（AIUI Agent）。

## 身份

一个运行在 Rokid 眼镜上的「远处人声再听一遍」助手，解决看得见
说话的人、却听不清他说什么的问题 — 会议室前排的发言、隔着
客厅的电视、另一个房间喊你的话。捂耳朵没用，眼镜有办法：你
脸朝向哪儿，4 麦阵列就朝哪儿收音；先用远场模式把远处的人声
拾起来、电平条帮你对准，再把听到的内容转成文字，最后由贴在
你耳边的眼镜扬声器用 TTS 清清楚楚地再说一遍。

## 能力

- 瞄准（AIM）：界面常驻显示头部朝向（`AbsoluteOrientationSensor`
  约 5Hz 的 yaw）与来源标注（SENSOR / DEMO / NONE），并提示
  「脸朝向声源 — 你的头就是阵列的瞄准器」。朝向只是显示与
  引导，不参与任何计算造假。
- 远场拾音 + 电平瞄准（LISTEN）：点 LISTEN 后按文档方式用
  `getUserMedia({audio:{captureSource:'microphone',
  microphoneMode:'far-field', echoCancellation:true}})` 开麦 —
  远场模式让 4 麦阵列去收远处的声音，而不是佩戴者自己的
  声音；流接 Web Audio `AudioContext` + `AnalyserNode`
  （只接分析器，绝不接 destination 防啸叫），每 100ms 算
  一次 RMS 显示电平条：脸对准声源时电平升高，把头转到
  电平最高就是瞄准了。开麦后读回 `track.getSettings()` 如实
  显示设备实际选中的模式；`far-field` 被设备拒绝
  （OverconstrainedError）时回退默认麦克风并如实提示，
  不假装模式生效。麦克风 / Web Audio 不可用时 FAIL 写明
  原因。STOP 立即停轨道、关 AudioContext。
- 远处字幕（CAPTION）：按基准 Agent 的 `SpeechRecognition`
  模式（zh-CN）做一次识别尝试，结果行永远带前缀
  「HEARD (far - may be wrong):」— 识别远处语音很
  容易出错，界面每次都如实标注；识别不可用时显示
  SKIP 并写明，识别失败显示 FAIL 与原因。**管线如实
  拆分**：CAPTION 的识别由宿主 SpeechRecognition 用它
  自己的麦克风完成，far-field 模式只作用于 LISTEN 的
  电平流（getUserMedia），不作用于识别 — LISTEN 的
  远场流只喂 `AnalyserNode` 算电平，从不喂给识别器。
- 近耳重播（REPEAT，本 Agent 的核心把戏）：把最近一条
  字幕用 `speechSynthesis` 朗读出来。眼镜的扬声器就贴在
  你耳边 — 一句在房间那头没听清的话，被拾音、转成文字、
  再在你耳边清楚地说一遍。头部稳定时点头 = REPEAT，
  不用腾手。
- DEMO：不用麦克风不用传感器：合成约 3 秒起伏的假电平，
  然后给出一条明确标注 [DEMO] 的样例字幕「请大家看
  第三页」，REPEAT 可直接朗读它，预览可完整演示
  「电平 → 字幕 → 重播」的全流程。

## 行为边界

- **不放大直播音频**：AIUI 运行时没有文档化的音频透传 /
  监听（passthrough/monitoring）API，本 Agent 绝不声称把
  房间声音放大送进耳朵。它做的只有四件事：远场拾音、
  电平引导瞄准、字幕转写、近耳 TTS 重播。界面页脚、README
  都常驻如实说明。
- 宿主 ASR 识别远处语音的错误率在真机上未验证：距离、
  混响、口音都会让它错得更多；字幕只能当「大概听到了
  什么」的参考，重要场合请走近确认，不要把字幕当记录。
- 麦克风只在用户点 LISTEN / CAPTION 后开启：LISTEN 停止
  （STOP / 页面隐藏 / 卸载）立即停掉全部媒体轨道并关闭
  AudioContext；识别器在停止与卸载时 abort。电平是实时
  算出的 RMS 数值，音频数据不保存、不上传；字幕只留
  最近一条在内存里，CLEAR 清空。
- 声明权限只有 RECORD_AUDIO；朝向传感器在 AIUI 里不
  需要单独的权限声明。
