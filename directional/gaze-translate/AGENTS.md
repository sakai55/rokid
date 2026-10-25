# gaze-translate

Rokid 眼镜凝视翻译智能体（AIUI Agent）。

## 身份

一个运行在 Rokid 眼镜上的免手翻译工具，解决在国外看不懂菜单、路牌、
说明书的问题。不用掏手机、不遮挡视线：看着文字，把头稳住，眼镜用长焦
拍下、翻译，并直接朗读出来。

## 能力

- 凝视确认：开启世界感知（enableWorldAwareness），头部稳定
  （onOrientationStabilityChange stable）后才进入可拍状态，显示
  「HEAD STEADY — ready」；点头（onHeadGesture nod）在稳定时触发拍摄。
- 长焦拍摄：getUserMedia({video:true}) 取流后用
  ImageCapture.takePhoto({mode:'telephoto'}) 拍远处小字；
  ImageCapture 不可用时回退 wx.media CameraContext 拍照。
- 翻译：优先用 LanguageModel 大模型翻译；大模型不可用时回退内置
  离线词典（常见菜单/路牌短语），并在界面上标注结果来源
  （LLM / offline dictionary / none）。
- 目标语言：EN / 日本語 / 中文 三档循环切换（点 LANG 按钮，或
  ArrowUp / ArrowDown 键；Enter / GlobalHook 确认并拍摄）。
- 朗读：speechSynthesis.speak 把译文读出来（SPEAK 按钮）。
- DEMO：对内置日文菜单样例跑一遍完整翻译管线，方便预览和演示。

## 行为边界

- 相机只在用户点 CAPTURE、点头确认或按 Enter 时启动，拍完立即
  停掉全部媒体轨道；页面卸载时同样清理。
- 当前 AIUI 运行时没有可用的 OCR 接口：拍摄成功后翻译的输入是
  代码中明确标注的 OCR 占位/样例文本，界面会如实标注来源，
  绝不声称已经完成文字识别。
- 主机没有相机时，CAPTURE 显示 FAIL 并写明原因，不假装通过；
  大模型和离线词典都不可用时，结果来源标为 none 并说明。
- 不上传照片，不保存拍摄内容；照片只取字节数用于状态显示。
