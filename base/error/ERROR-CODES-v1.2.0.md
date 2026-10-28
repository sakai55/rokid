> 历史存档：本文件为全局错误码表 v1.2.0 快照，已被新版取代；最新版 = 仓库根目录 `ERROR-CODES.md`。

# Rokid 舰队全局错误码表（Global Error Codes）v1.2.0

GO 2026-10-28 定立，自 AV11 起全舰队执行：**任何 agent 发生任何错误，眼镜上统一显示错误码，用户只报码即可与 Muse 对齐 debug。**

## 回报格式（锁定规则）

```
<系列码>E<4位数字>（全连写，无分隔符）
例：AVE2005 ＝ AV 系列的「编码转文本失败」；CCE1234、BOE0002 同理
```

- 前缀 = **系列码**（两个字母，与 agent 编号的字母段相同：DI / WA / HO / CO / FI / DU / RE / CU / SO / BO / AM / CC / GA / JP / KR / AV），**不含台号**——具体哪台 agent 由报错上下文锁定（GO 当时在测哪台），不占码位（GO 2026-10-28 23:22 修正，覆盖 v1.0.0 的编号前缀格式）。
- 无编号的 base 系列统一用 **BA** 前缀（登记处 2026-10-28 确认）：glasses-benchmark、stream-probe、dabiaoge、my-agent 都记 BAE####，哪台同样由上下文锁定，本台 slug 另记入 `lastError` 以便追溯。v1.0.0 登记的 BENCH / PROBE / DABIAO / MYAGT 四个短码从未实际启用，自 v1.2.0 起废止。
- 数字段全舰队共用同一张表：同一个 4 位码在任何 agent 里含义完全相同。
- 眼镜显示：大字 `AVE2005` + 一行中文说明；自动停机/停拍类错误 TTS 只读码；最近一次错误写入该 agent 的持久数据（字段名 `lastError`，含全码、本台 slug、版本与原文），GO 报码、Muse 按系列与数字段双定位。

## 治理

- **登记处 = 旁聊「Rokid开发环境」**：本表的唯一维护方。新码分配、段位扩展、舰队推广（存量 agent 接入、SOP/验收口径同步）都由该聊处理；其他旁聊需要新码时向登记处申请，不许自行占码。
- **申请新码的流程**：申请方说明三件事——失败点（哪一步、什么操作）、触发原文（真机/日志的原始报错）、自拟归段（1xxx–9xxx 哪个领域）。登记处核对现有码无同义后顺序分配，回告码号；申请方在登记处回告前不许先用临时码上线。紧急真机现场可先用本系列的 E9001 兜底（如 AVE9001）并在 `lastError` 留原文，事后补申请正式码。
- 码一经分配**永不改义、永不复用**；废弃的码保留并标注「已废弃」。
- 新错误类型只能在对应段内顺序追加；段满或新领域出现时由登记处开新段并升次版本号。只增新码的扩编升次版本号；格式/治理规则变更原则上升主版本号（v1.2.0 的格式修正是例外：发生在首个现场码回报当晚、旧格式未形成存量，故以次版本留痕修正）。
- 每个 agent 的代码里：每个失败点必须映射到本表一个码，不许裸抛原文了事（原文只作附带诊断截断显示）；agent 的 README 必须有「错误码」一节，写明本台用到的码与回报约定。
- 本表版本：v1.2.0（2026-10-28，格式修正合并版：GO 的系列前缀格式修正与登记处扩编合一，84 码含义不变）。canonical 位置 = 仓库根目录 `ERROR-CODES.md`（sakai55/rokid，main）；本地镜像 `~/workspace/rokid/ERROR-CODES.md`，两处冲突时以仓库版为准。各 agent 工程内可放副本，冲突时以 canonical 为准。

## 码表

### 1xxx 相机与取景
| 码 | 说明 | 典型触发 |
|---|---|---|
| E1001 | 相机打开失败 | getUserMedia 抛错/被拒（非权限类） |
| E1002 | 相机权限未给 | NotAllowedError / 权限拒绝 |
| E1003 | 拍照器不可用 | ImageCapture 构造失败/不存在 |
| E1004 | 取景抓帧失败 | grabFrame 单次抛错 |
| E1005 | 取景连续失败 | 预览绘制连续失败 |
| E1006 | 相机流中断 | track ended / 流被收回 |
| E1007 | 相机设备不存在 | NotFoundError：无可用摄像头 / 约束无匹配设备 |
| E1008 | 相机不可读 | NotReadableError：相机被占用或硬件读取失败，track 无法启动 |
| E1009 | 拍照失败 | takePhoto 抛错或返回空 |
| E1010 | 拍照模式不可用 | 请求的 wide / telephoto / default 模式不被支持 |
| E1011 | 取景约束不满足 | 视频约束 OverconstrainedError 且回退默认值亦失败 |

### 2xxx 拍帧与编码
| 码 | 说明 | 典型触发 |
|---|---|---|
| E2001 | 拍帧抓帧失败 | 拍摄中 grabFrame 抛错 |
| E2002 | 画布创建失败 | Canvas 不可得 |
| E2003 | 编码失败（画布） | convertToBlob 抛错/空 |
| E2004 | 编码失败（直编） | createImageBlob 抛错/空 |
| E2005 | 编码转文本失败 | Blob→dataURL 失败（含 FileReader 缺失；首个现场码 AVE2005，出自 AV11） |
| E2006 | 编码超时已切换 | 编码超时熔断、已切备用模式 |
| E2007 | 无可用出帧路径 | 主备出帧路径都不可用 |
| E2008 | 内存帧读取失败 | getImageData 抛错且位图直存也失败 |
| E2009 | 单帧处理超时 | 看门狗强制复位 |
| E2010 | 连续失败已停拍 | 连续失败达上限自动停（主码见 lastError） |
| E2011 | 图片解码失败 | createImageBitmap 对照片/帧数据解码抛错 |
| E2012 | 图像源为空 | drawImage 源为空或已失效（InvalidStateError） |
| E2013 | 文本编码失败 | arrayBuffer / 分块 btoa 转码抛错（无 FileReader 替代路径自身的失败） |

### 3xxx 语音（ASR / TTS）
| 码 | 说明 | 典型触发 |
|---|---|---|
| E3001 | 语音识别不可用 | SpeechRecognition 不存在 |
| E3002 | 语音识别没启动 | rec.start() 抛错 |
| E3003 | 语音识别出错 | rec.onerror（未细分事件的兜底） |
| E3004 | 语音识别反复掉线 | onend 重启连续失败 |
| E3005 | 播报失败 | speechSynthesis.speak 抛错 |
| E3006 | 无语音输入 | ASR 事件 no-speech：静音超时无人声 |
| E3007 | 麦克风采集失败 | ASR 事件 audio-capture：宿主侧采音失败 |
| E3008 | 识别权限未给 | ASR 事件 not-allowed：RECORD_AUDIO 未授权 |
| E3009 | 识别网络错误 | ASR 事件 network：识别服务网络失败 |
| E3010 | 麦克风模式回退 | OverconstrainedError：exact 麦克风模式不满足，已回退默认模式（AV04 现场；全舰队 23 处引用） |
| E3011 | 麦克风流获取失败 | getUserMedia 音频流抛错（非权限、非约束类） |
| E3012 | 识别服务不可用 | ASR 事件 service-not-allowed |
| E3013 | 识别语言不支持 | ASR 事件 language-not-supported |
| E3014 | 识别会话配置失败 | SpeechRecognitionSession 热词 / VAD / updateContext 更新被拒（AV05） |
| E3015 | 语音合成失败 | speechSynthesis.synthesize 生成侧抛错（与 E3005 的 speak 播报失败区分，AV06） |

### 4xxx 录制、合成与播放
| 码 | 说明 | 典型触发 |
|---|---|---|
| E4001 | 没有可合成的帧 | 0 帧结束 |
| E4002 | 帧解码失败 | 帧数据→ImageBitmap 解码抛错 |
| E4003 | 播放绘制失败 | 播放 drawImage 抛错 |
| E4004 | 播放帧率过低 | 实测低于设定一半 |
| E4005 | 帧数据丢失 | 跨页/跨会话后帧与记录不符 |
| E4006 | 录制器不可用 | MediaRecorder 不存在 / 构造失败 |
| E4007 | 录制格式不支持 | isTypeSupported 候选格式全否（AV03 探针） |
| E4008 | 录制启动失败 | MediaRecorder.start 抛错 |
| E4009 | 录制无数据 | ondataavailable 无数据 / 分片全空 |
| E4010 | 音频解码失败 | decodeAudioData 抛错（AV04 分析路径） |
| E4011 | 音频播放失败 | SpeechAudioPlayer / 媒体元素播放抛错 |

### 5xxx 存储
| 码 | 说明 | 典型触发 |
|---|---|---|
| E5001 | 记录保存失败 | localStorage/wx 存储写入抛错 |
| E5002 | 记录读取失败 | 读取/JSON 解析抛错 |
| E5003 | 存储空间不足 | 写入被配额拒绝 |
| E5004 | 存档版本不兼容 | 持久数据结构版本不符、解析或迁移失败 |
| E5005 | 持久化不可用 | localStorage / 存储接口不存在或被禁用 |

### 6xxx 网络与 LLM
| 码 | 说明 | 典型触发 |
|---|---|---|
| E6001 | 大模型不可用 | LanguageModel.availability 非 available |
| E6002 | 大模型请求失败 | prompt/promptStreaming 抛错或流失败 |
| E6003 | 大模型超时 | 请求超时未返回 |
| E6004 | 网络不可达 | fetch/wx.request 失败 |
| E6005 | 图片输入失败 | 图片 dataURL 构造/传入失败（非 FileReader 类，FileReader 类归 E2005） |
| E6006 | 大模型未就绪 | availability 为 downloadable / downloading：需下载或准备中，暂时不可用（与 E6001 的 unavailable 区分） |
| E6007 | 服务端错误 | HTTP 5xx 或接口业务错误 |
| E6008 | 请求被拒 | HTTP 4xx / 鉴权失败（401/403；dabiaoge 通道 401 属此） |
| E6009 | 响应解析失败 | 网络响应 JSON / 结构解析抛错 |
| E6010 | 域名不在白名单 | 请求域名未报备白名单、被宿主拦截 |
| E6011 | 大模型输出不可用 | 空响应或结构不符预期、无法解析为业务数据 |

### 7xxx 传感器、定位与检测
| 码 | 说明 | 典型触发 |
|---|---|---|
| E7001 | 朝向传感器不可用 | AbsoluteOrientationSensor 构造/启动失败 |
| E7002 | 定位失败 | getCurrentPosition error 2/3 |
| E7003 | 定位权限未给 | getCurrentPosition error 1 |
| E7004 | 条码检测失败 | BarcodeDetector.detect 抛错 |
| E7005 | 码制不支持 | getSupportedFormats 不含目标码制 |
| E7006 | 手势通道异常 | 世界感知开启失败 enableWorldAwareness 抛错 |
| E7007 | 惯性传感器不可用 | Accelerometer / Gyroscope 构造或启动失败 |
| E7008 | 传感器无数据 | 传感器已启动但超时无读数（benchmark 朝向/动作项超时类） |
| E7009 | 条码检测器不可用 | BarcodeDetector 不存在 / 构造失败（与 E7004 的 detect 抛错区分） |
| E7010 | 头部校准失败 | 校准无法完成，或校准中心漂移过大（头部游戏 / 指向类） |

### 8xxx 页面与运行时
| 码 | 说明 | 典型触发 |
|---|---|---|
| E8001 | 页面切换失败 | wx.navigateTo/navigateBack 抛错 |
| E8002 | 页面被系统回收 | 非正常 onUnload 且任务未完 |
| E8003 | 权限未声明 | 调用能力与 app.json 权限不符（开发期自查码） |
| E8004 | 运行时接口缺失 | 所需全局接口不存在（X is not defined 通用码；编码上下文的 FileReader 归 E2005） |
| E8005 | 输入事件未达页面 | 按键/手势事件未送达页面（开发期自查码：onKeyDown 未接线、bindtap-only 在真机不可触发类） |
| E8006 | 会话状态丢失 | 跨页/重进后会话状态缺失（媒体帧丢失归 E4005） |

### 9xxx 系统
| 码 | 说明 | 典型触发 |
|---|---|---|
| E9001 | 未分类错误 | 兜底（原文截断附带） |
| E9002 | 配置缺失 | 必需配置/常量为空 |

## 系列前缀登记册
| 前缀 | 系列 |
|---|---|
| DI / WA / HO / CO / FI / DU / RE / CU / SO / BO / AM | 指向性（DI）与注意力外挂各组 |
| CC | 路缘坡 |
| GA | 头部动作小游戏 |
| JP / KR | 日本 / 韩国本地化 |
| AV | 影视听（影音捕捉） |
| BA | 无编号基础项（base：glasses-benchmark / stream-probe / dabiaoge / my-agent 共用，哪台由上下文锁定） |
（新系列立项时由登记处在此追加一行；BENCH / PROBE / DABIAO / MYAGT 短码已废止，见回报格式节。）

## 现场已回报码
- **AVE2005**（2026-10-28 真机，AV11 v1.1.0 首报；当日曾按旧格式记作 AV11-E2005，v1.2.0 起按系列前缀格式记为 AVE2005）：原文「FileReader is not defined」——Ink 运行时无 FileReader（aiui-dev 官方参考全文亦无），编码后转 dataURL 每帧必死、0 帧超时退出。全舰队 grep 实查共 39 个文件用了 FileReader（AV01/02/08/10、stream-probe、games 多台、directional 4 台、curb-cut 5 台、cover/hold/filter/review/japan/korea 若干），真机同环同死，批量修复由登记处统筹（修法样板 = AV11 验证中的 arrayBuffer + 分块 btoa，AV11 本台由影音交互聊负责，登记处不直接动）。

## 变更日志
- **v1.2.0（2026-10-28，格式修正合并版）**：GO 23:22 修正回报格式——前缀改**系列码**、全连写无分隔符（AVE2005 / CCE1234 / BOE0002），台号不占码位、具体哪台由报错上下文锁定；登记处确认无编号 base 系列统一 **BA** 前缀，v1.0.0 的 BENCH / PROBE / DABIAO / MYAGT 短码未启用即废止。本版将该格式修正与登记处 v1.1.0 扩编（+39 码）合并定版：84 码含义一字未变，仅格式与前缀登记册变更。
- **v1.1.0（2026-10-28，登记处扩编）**：登记处（旁聊「Rokid开发环境」）接管本表。枚举目前能够知道的全部错误信息并编码：依据 = 能力档案红线、全舰队代码实查（OverconstrainedError 23 处、ASR 错误事件六种、LanguageModel availability 调用 41 处、isTypeSupported / decodeAudioData / createImageBitmap / getCurrentPosition 等引用面）与既有真机教训。新增 39 码：1xxx +5（E1007–E1011）、2xxx +3（E2011–E2013）、3xxx +10（E3006–E3015）、4xxx +6（E4006–E4011，段题扩为「录制、合成与播放」）、5xxx +2（E5004–E5005）、6xxx +6（E6006–E6011）、7xxx +4（E7007–E7010）、8xxx +3（E8004–E8006）、9xxx +0；既有 45 码含义一字未改。治理补「申请新码流程」与版本规则；canonical 落仓库根目录。
- **v1.0.0（2026-10-28，影音交互聊立表）**：源自 AV11 现场表扩展：回报格式、编号前缀规则、九段约 45 码、无编号前缀登记册（BENCH/PROBE/DABIAO/MYAGT）与治理骨架。
