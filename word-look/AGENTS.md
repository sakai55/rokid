# word-look

Rokid 眼镜看词查词智能体（AIUI Agent）。

## 身份

一个运行在 Rokid 眼镜上的「抬头查词」助手，解决看书、看路牌、
看说明书时遇到生词、掏手机查词把当下打断的问题。流程只有四步，
全程不用手：看向生词所在的页面（长焦拍一张留档），把生词说
出来，眼镜把听到的词原样大字摆出来等你核对，对了就查——中文
释义、简单英文解释、一个例句，即时朗读——再按场景存进生词本，
之后按场景翻出来复习。它全程不读你的书：这个运行时没有 OCR，
词是你说出来的，不是它认出来的。

## 能力

- 看（LOOK）：看着生词所在的页面点 LOOK，用
  `ImageCapture.takePhoto({mode:'telephoto'})` 长焦拍下这一页
  （不可用时回退 wx.media CameraContext，同 #01）。照片只作
  记录——锚定「这个词是在哪儿遇到的」，界面只显示字节数，
  拍完立即停掉全部媒体轨道。它永远不会被读取：AIUI 运行时
  没有 OCR 接口（同 #01 的结论）。
- 说（SAY）：词靠你说。先按文档方式用
  `getUserMedia({audio:{captureSource:'microphone',
  microphoneMode:'wearer'}})` 做佩戴者模式麦克风检查，再用
  SpeechRecognition 一次性识别。识别的词是英文，所以先用
  `en-US`；主机拒绝这个语言（language 类错误）时，只重试
  一次 `zh-CN`，并把「已回退、可能听错」的警告留在屏幕上；
  主机根本没有识别能力时如实 SKIP，改为轮换内置离线词典的
  词条当演示输入，绝不假装在听。
- 核对（产品本身）：听到的词**原样**（只去首尾空白）大字
  显示，先给你看再查——同 #21 的逐字纪律，眼镜从不悄悄
  「纠正」它。听错一个词，就会理直气壮地查出一个错误
  意思，所以核对这一步不是礼貌，是防线；不对就再 SAY
  一次，点头（`onHeadGesture`）只推进你正在走的流程
  （DEFINE、然后 SAVE），从不替你编词、改词。
- 查（DEFINE）：只把你核对过的词以**纯文本**发给主机
  LanguageModel 大模型（同 #01 的调用方式），要三行：
  一行中文释义、一行简单英文解释、一句短例句，结果标注
  来源 LLM；大模型不可用时回退内置离线小词典（24 个常见
  词：itinerary、boarding、receipt、prescription、
  appointment、deadline、warranty、ingredient、fragile、
  refund、detour、luggage、signature、discount、
  reservation、urgent、available、direction、platform、
  entrance、exit、caution、volunteer、schedule），标注
  OFFLINE；两边都没有，如实显示 none，不编造释义。
- 朗读（SPEAK）：speechSynthesis 把「词 + 中文释义」（生词
  本复习时再加例句）读出来；查成功后自动朗读一次。它是
  **合成语音**——把词读出声而已，不是真人发音录音，读音
  只能当参考。
- 生词本（BOOK）：SAVE 把 {词， 中文释义， 英文解释，
  例句， 来源， 场景， 日期} 存入 wx 同步存储（key
  `wordBook`，最多 60 条，超了挤掉最旧的）。SCENE 轮换四
  个场景（阅读 / 旅行 / 工作 / 日常）：在 LOOK 模式决定
  存到哪个场景，在 BOOK 模式决定按哪个场景过滤浏览；
  REVIEW 在当前场景里逐个走词（大字词 + 释义），SPEAK
  朗读当前词。
- DEMO：不经过麦克风和相机，把 itinerary 走一遍**离线**
  查词通道（强制离线、来源标注 OFFLINE (DEMO)），存进
  旅行场景，并用**一次** Date 快照纯算术播入另外两个旅行
  词（boarding 今天、luggage 昨天），落在结果视图。全部
  只在内存里，不写真实存储；CLEAR 退出 DEMO 时恢复你
  真实的生词本。

## 行为边界

- **没有 OCR，一个字都读不出来**：照片只是留档。任何
  「看一眼就知道词是什么」都不存在——词必须由你说出来，
  它听成什么就是什么，核对环节因此不可省略。
- **释义来源只有一个是实时生成的**：LLM 是文本进、文本
  出，照片进不了大模型（同 #01 的边界）；离线词典只有
  24 个词，查不到就明说 none。两种来源都在界面上标注，
  离线释义不会冒充在线结果。
- **朗读不是发音示范**：speechSynthesis 是合成音，读
  错重音、读错音节都有可能；拿它当「听个大概」，不要
  当发音课。
- 麦克风/相机只在用户点 SAY / LOOK 时启动，用完立即停
  掉全部媒体轨道；不录音、不保存照片（只取字节数显示）；
  生词本只存本机 wx 同步存储，不上传。
- 声明权限：CAMERA（长焦拍页面留档）与 RECORD_AUDIO
  （佩戴者模式麦克风检查 + 词的一次性识别）。
