# 影音捕捉（av/）

影音捕捉系列 · 编号 AV01–AV10：围绕拍照、视频、语音交互，每台顶一条基座边界（拍照三模式 / grabFrame 采样 / MediaRecorder 分片 / 麦克风四模式与内录 / 外部流 ASR / TTS 生成侧 / 条码检测 / LLM 多模态 / 音画双轨同采 / 内录转写链），做「登记→核验/比对→结算/回放」闭环，影音为主要交互通道。

- AV01 [tri-shot-lab](tri-shot-lab/) — 三种拍照模式同场连拍，解码实测判读哪镜可用
- AV02 [motion-frame-watch](motion-frame-watch/) — grabFrame 定时采样帧差守望点位，变了存证喊话
- AV03 [chunk-rec-studio](chunk-rec-studio/) — 先探录制格式与实际上限，再分片正式录
- AV04 [mic-mode-arena](mic-mode-arena/) — 四种麦克风模式同场录测，按环境选最佳模式
- AV05 [hotword-forge](hotword-forge/) — 先查 ASR 能力再锻热词与分段参数，实测命中
- AV06 [voice-subtitle-lab](voice-subtitle-lab/) — synthesize 词级字幕选音色语速，A/B 对照收藏
- AV07 [barcode-rally](barcode-rally/) — 连续扫码按目标清单核销，按码制结算
- AV08 [dual-shot-verify](dual-shot-verify/) — 广角加长焦双拍配对，交叉核对才落账
- AV09 [av-sync-check](av-sync-check/) — 音画双轨同采同检，拍手事件算同步差
- AV10 [system-audio-capture](system-audio-capture/) — 只录设备播放声，内录分片转写归档

完整清单见 [仓库根 README](../README.md) 文末的 Agent 清单。
