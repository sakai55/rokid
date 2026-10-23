# cook-along

Rokid 眼镜做饭跟做智能体（AIUI Agent）。

## 身份

一个运行在 Rokid 眼镜上的免手做饭向导，解决「手上全是油和水、
没法翻手机菜谱、步骤做到一半就忘」的问题。菜谱就悬在视线里，
你看着锅做，点头或喊一声「下一步」就翻页，定时步骤在眼前倒计时、
到点出声提醒——全程不用腾手碰任何屏幕。

## 能力

- 凝视确认：开启世界感知（enableWorldAwareness），头部稳定
  （onOrientationStabilityChange stable）后显示「HEAD STEADY」；
  点头（onHeadGesture nod）：未开火时开始做菜（START），进行中
  则推进一步——用点头代替油手点按钮。
- 内置菜谱：RECIPE 在 3 道家常菜间切换（番茄炒蛋 6 步 /
  青椒肉丝 7 步 / 清水煮面 6 步），每道菜第 0 步是备料清单；
  选中菜谱即重置到备料步，START 进入第 1 步；做菜进行中
  RECIPE 锁定，防止误触换菜丢步骤。ArrowUp / ArrowDown 只在
  未开火时换菜，Enter / GlobalHook = START / NEXT。
- 视线内倒计时：带分钟数的步骤（如炒番茄 2 分钟、腌肉 10 分钟、
  烧水 5 分钟）可点 TIMER 启动倒计时，剩余时间（mm:ss）显示在
  步骤框里，再点 TIMER 停止；推进到下一步自动清掉旧计时；归零时
  状态变「TIME UP」并用 TTS 朗读「时间到」+ 当前步骤。
- 语音翻页（wearer 模式）：LISTEN 先按文档方式用
  getUserMedia({audio:{captureSource:'microphone',
  microphoneMode:'wearer'}}) 做佩戴者模式麦克风检查（4 麦阵列
  优先收佩戴者人声，压过抽油烟机噪音，读 track.getSettings()
  确认，检查完立即停轨道），再按基准 Agent 的 SpeechRecognition
  模式启动 zh-CN 识别；听到「下一步」或「好了」自动推进，其它
  内容如实显示为「听到了，但不是口令」。
- 看锅记录（诚实边界）：LOOK 看着锅用 ImageCapture
  takePhoto({mode:'default'}) 拍一张（只作记录，显示字节数；
  不可用时回退 wx.media CameraContext）；火候由你亲眼判断：
  PAN 轮换你看到的状态（还生 / 刚好 / 有点糊），每个状态给一句
  调整建议（如「有点糊 → 关小火，加两勺水快翻匀」）。
- 朗读：SPEAK 用 speechSynthesis.speak 朗读当前步骤（备料步
  朗读备料清单，完成时朗读上菜语）。
- DEMO：直接载入番茄炒蛋并跳到第 3 步（带 2 分钟计时）且启动
  倒计时，方便在没有相机/麦克风的预览环境里看到步骤视图 +
  实时计时行。

## 行为边界

- 照片不判断火候：运行时没有把现拍照片变成「生/熟」结论的
  链路，熟度一律由佩戴者亲眼确认（PAN），界面、代码注释与
  README 都如实标注「record only; YOU judge doneness」，
  绝不声称照片识别了锅里的状态。
- 不发明唤醒词 API：语音翻页只有点 LISTEN 后的一次性
  SpeechRecognition 识别，没有常驻唤醒；识别不到或主机不支持
  时如实显示 SKIP / FAIL，回退点头 / 按键 / 按钮。
- wearer 模式在真实厨房噪音（抽油烟机、沸水声）下的识别率
  未在真机验证，README 如实标注为未验证项。
- 菜谱全部为内置 3 道家常菜，不支持导入外部菜谱，也不联网
  搜菜谱；计时为本机 setInterval 倒计时，页面隐藏/卸载时
  清除计时、abort 识别器、停掉全部媒体轨道。
- 相机/麦克风只在用户点 LOOK / LISTEN 时启动，用完立即释放。
- 不上传照片，不保存拍摄内容；照片只取字节数用于状态显示。
