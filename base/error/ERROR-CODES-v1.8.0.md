> 历史存档：本文件为全局错误码表 v1.8.0 快照，已被新版取代；最新版 = 仓库根目录 `ERROR-CODES.md`。

# Rokid 舰队全局错误码表（Global Error Codes）v1.8.0

GO 2026-10-28 定立，自 AV11 起全舰队执行：**任何 agent 发生任何错误，眼镜上统一显示错误码，用户只报码即可对表定位。**

## 为什么要这张表（眼镜端屏显错误码）

**先说一个现成的例子。** AV11 真机首测一帧没拍出来，代码死在 FileReader 上——而官方 API 参考是清单式的，FileReader 根本不在清单里：这一步首先是开发侧没对着清单核、顺手用了浏览器的习惯 API，错在开发侧。但这个错在模拟器和本地预览里藏得严严实实：那两处是完整 Web 环境，FileReader 跑得好好的，一切「正常」；只有真机第一次运行才把它揭出来，最后靠眼镜上报的 E2005 对表定位。清单内的错靠静态核对事先挡（本舰队已把 FileReader 列入静态检查禁词），清单与环境的不一致则永远要真机这一关和错误码兜底。

**边界要划清。** 模拟器能覆盖的：页面呈现、逻辑流程、静态问题（Problems 那类）——开发期快速迭代靠它，我们也一直在用（预览截图就是这条链路）。模拟器覆盖不了的：真机独有的运行时差异（如 API 清单与浏览器的差异）、真实摄像头 / 麦克风 / 传感器的行为、手势在真机上的触发、AR1 上的性能、蓝牙代理网络的特性。本表 84 码中有 29 码背后的失败原因模拟器模拟不出来（码表中已在典型触发句尾加删除线「模拟器」徽章标出）；官方文档自己的口径也是「真机模拟用于快速迭代，最终体验仍应以真实设备为准」。

**官方真机链路到送达为止。** Studio 打包上传的成功/失败弹窗、手机 App 的「智能体资源包下载成功」，只证明包到了眼镜；agent 跑起来之后报错，官方无回传、无记录、无查看入口（2026-10-28 登记处查实官方 debug 文档与 FAQ），文档给的唯一办法是回 Studio 改代码、重打包、再试一遍。Console / Problems / 网络信息只活在网页模拟环境里，真机运行期看不到。

**错误码也不只是调试工具。** agent 真给人用时，屏幕就 480×352、单色、没有别的信息通道，信息转瞬即逝，摄像头占用时连截图存证都做不到，英文报错原文用户记不住、转述必失真——出错时用户能记住并报出的只有一个短码。故全舰队统一：大字屏显、TTS 读码、写入 `lastError` 持久保存；用户报一个码，维护者对表即可还原失败点与触发原文。

**所以两套是分工，不是重复**：模拟器管开发期能复现的，错误码（及规划中的日志回传）管只有真机才暴露的——后者恰恰是最贵的一类问题，每一个都要戴上眼镜才撞得见。本表即为此立。

## 编码规则（全舰队唯一，锁定）

```
E<4位数字>
例：E2005 ＝「编码转文本失败」
```

**唯一形态：全舰队只用裸码 `E####`，不带任何前缀。** 数字段全舰队共用一张表，同一个码在任何 agent 里含义完全相同。agent 代码内定义、眼镜屏显、TTS 读码、持久数据 `lastError`、各 agent 的 README「错误码」一节、使用者的回报与调试记录——全部只出现 `E####` 这一种写法。具体哪台 agent 出的错，由报错上下文与 `lastError` 里记的本台 slug + 版本锁定，不占码位。

- 眼镜显示：大字 `E2005` + 一行中文说明；自动停机/停拍类错误 TTS 只读码；最近一次错误写入该 agent 的持久数据（字段名 `lastError`，含码、本台 slug、版本与原文），使用者报码、维护者对表定位。

## 治理

- **登记处**：本表的唯一维护方。新码分配、段位扩展、舰队推广（存量 agent 接入、SOP/验收口径同步）都由登记处处理；其他开发方需要新码时向登记处申请，不许自行占码。
- **申请新码的流程**：申请方说明三件事——失败点（哪一步、什么操作）、触发原文（真机/日志的原始报错）、自拟归段（1xxx–9xxx 哪个领域）。登记处核对现有码无同义后顺序分配，回告码号；申请方在登记处回告前不许先用临时码上线。紧急真机现场可先用 E9001 兜底并在 `lastError` 留原文，事后补申请正式码。
- 码一经分配**永不改义、永不复用**；废弃的码保留并标注「已废弃」。
- 新错误类型只能在对应段内顺序追加；段满或新领域出现时由登记处开新段并升次版本号。只增新码的扩编升次版本号；格式/治理规则变更原则上升主版本号（例外情形见变更日志）。
- 每个 agent 的接入按下方「接入规范」一节执行（失败点全映射、三处同码、README「错误码」一节）。
- 本表版本：v1.8.0（2026-10-29）。canonical 位置 = 仓库根目录 `ERROR-CODES.md`（sakai55/rokid，main）。各 agent 工程内可放副本，冲突时以 canonical 为准。本文档为通用件，任何开发方与 AI agent 均可直接采用；另有自成一体的分发版 `ROKID-ERROR-CODES.md`（同在仓库根目录），供其他开发者整份取用。

## 接入规范（给开发者与 AI agent）

把一个 agent 接入本表，做五件事：

**（1）单点定义。** 在工程里建一个错误码模块（如 `err.js`），把本台用到的码以裸码字面量集中定义一次，禁止在业务代码里散写字符串、禁止运行时拼前缀。参考形态：

```js
// err.js —— 本台用到的码，单点定义；码义以全局表为准
export const ERR = {
  CAM_OPEN: 'E1001',
  ENCODE_TEXT: 'E2005',
  ASR_UNAVAILABLE: 'E3001',
  UNKNOWN: 'E9001'
};
// 统一失败出口：屏显 + TTS（停机类）+ 写 lastError
export function fail(code, raw, opts) { /* 见（3） */ }
```

**（2）失败点全映射。** 逐个走查代码里所有会失败的调用（相机、编码、ASR/TTS、LLM、网络、存储、传感器、页面切换……），每个失败点映射到表中一个码；表里没有贴切的码时用 E9001 并保留原文。不许裸抛原文了事——原文只作附带诊断，截断后显示或只进 `lastError`。

**（3）三处同码。** 失败发生时同一个码出现在三处：

- **屏显**：大字码 + 一行中文说明（如 `E2005 编码转文本失败`）；
- **TTS**：自动停机/停拍类错误只读码本身（如「E2005」），不念原文；
- **`lastError`**：写入本台持久存储，字段含码、本台 slug、版本、原始报错文本。使用者报码后，维护者据此对表定位。

**（4）README 留一节。** Agent 的 README 加「错误码」一节，列本台实际用到的码与一句回报约定（模板）：

```markdown
## 错误码
本台遵循全局错误码表（裸码 E####）。出错时屏显 + 播报错误码，
最近一次错误保存在 lastError。回报问题时请带上眼镜上显示的码。
本台用到：E1001、E1002、E2005、E3001、E9001。
```

**（5）静态自查。** 打包前 grep 一遍：本台用到的每个码都在全局表里存在且含义对得上；没有自造码、没有前缀形态。另外提醒：AIUI 的 API 是清单式的，官方参考里没有的浏览器 API（如 `FileReader`）不存在于运行时——Blob 转 dataURL 用 `blob.arrayBuffer()` + 分块 `btoa`，这正是 E2005 的由来。

## 码表

（下表的 `E####` 就是唯一使用形态，全舰队一致，不带任何前缀。）

典型触发句尾带删除线「模拟器」徽章 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> 的，表示这个触发背后的失败原因模拟器模拟不出来（例如真机运行时缺失的接口、眼镜硬件与宿主服务的真实行为），只能靠真机测试撞见；无徽章的触发与环境无关，模拟器里同样会发生。全表共 29 处。新码登记时同步判定是否加徽章。

### 1xxx 相机与取景
| 码 | 说明 | 典型触发 |
|---|---|---|
| E1001 | 相机打开失败 | getUserMedia 抛错/被拒（非权限类） |
| E1002 | 相机权限未给 | NotAllowedError / 权限拒绝 |
| E1003 | 拍照器不可用 | ImageCapture 构造失败/不存在 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E1004 | 取景抓帧失败 | grabFrame 单次抛错 |
| E1005 | 取景连续失败 | 预览绘制连续失败 |
| E1006 | 相机流中断 | track ended / 流被收回 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E1007 | 相机设备不存在 | NotFoundError：无可用摄像头 / 约束无匹配设备 |
| E1008 | 相机不可读 | NotReadableError：相机被占用或硬件读取失败，track 无法启动 |
| E1009 | 拍照失败 | takePhoto 抛错或返回空 |
| E1010 | 拍照模式不可用 | 请求的 wide / telephoto / default 模式不被支持 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E1011 | 取景约束不满足 | 视频约束 OverconstrainedError 且回退默认值亦失败 |

### 2xxx 拍帧与编码
| 码 | 说明 | 典型触发 |
|---|---|---|
| E2001 | 拍帧抓帧失败 | 拍摄中 grabFrame 抛错 |
| E2002 | 画布创建失败 | Canvas 不可得 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E2003 | 编码失败（画布） | convertToBlob 抛错/空 |
| E2004 | 编码失败（直编） | createImageBlob 抛错/空 |
| E2005 | 编码转文本失败 | Blob→dataURL 失败（含 FileReader 缺失；首个现场码 E2005，出自 AV11） <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E2006 | 编码超时已切换 | 编码超时熔断、已切备用模式 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E2007 | 无可用出帧路径 | 主备出帧路径都不可用 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E2008 | 内存帧读取失败 | getImageData 抛错且位图直存也失败 |
| E2009 | 单帧处理超时 | 看门狗强制复位 |
| E2010 | 连续失败已停拍 | 连续失败达上限自动停（主码见 lastError） |
| E2011 | 图片解码失败 | createImageBitmap 对照片/帧数据解码抛错 |
| E2012 | 图像源为空 | drawImage 源为空或已失效（InvalidStateError） |
| E2013 | 文本编码失败 | arrayBuffer / 分块 btoa 转码抛错（无 FileReader 替代路径自身的失败） |

### 3xxx 语音（ASR / TTS）
| 码 | 说明 | 典型触发 |
|---|---|---|
| E3001 | 语音识别不可用 | SpeechRecognition 不存在 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E3002 | 语音识别没启动 | rec.start() 抛错 |
| E3003 | 语音识别出错 | rec.onerror（未细分事件的兜底） |
| E3004 | 语音识别反复掉线 | onend 重启连续失败 |
| E3005 | 播报失败 | speechSynthesis.speak 抛错 |
| E3006 | 无语音输入 | ASR 事件 no-speech：静音超时无人声 |
| E3007 | 麦克风采集失败 | ASR 事件 audio-capture：宿主侧采音失败 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E3008 | 识别权限未给 | ASR 事件 not-allowed：RECORD_AUDIO 未授权 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E3009 | 识别网络错误 | ASR 事件 network：识别服务网络失败 |
| E3010 | 麦克风模式回退 | OverconstrainedError：exact 麦克风模式不满足，已回退默认模式（AV04 现场；全舰队 23 处引用） <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E3011 | 麦克风流获取失败 | getUserMedia 音频流抛错（非权限、非约束类） |
| E3012 | 识别服务不可用 | ASR 事件 service-not-allowed <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E3013 | 识别语言不支持 | ASR 事件 language-not-supported |
| E3014 | 识别会话配置失败 | SpeechRecognitionSession 热词 / VAD / updateContext 更新被拒（AV05） <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E3015 | 语音合成失败 | speechSynthesis.synthesize 生成侧抛错（与 E3005 的 speak 播报失败区分，AV06） <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |

### 4xxx 录制、合成与播放
| 码 | 说明 | 典型触发 |
|---|---|---|
| E4001 | 没有可合成的帧 | 0 帧结束 |
| E4002 | 帧解码失败 | 帧数据→ImageBitmap 解码抛错 |
| E4003 | 播放绘制失败 | 播放 drawImage 抛错 |
| E4004 | 播放帧率过低 | 实测低于设定一半 |
| E4005 | 帧数据丢失 | 跨页/跨会话后帧与记录不符 |
| E4006 | 录制器不可用 | MediaRecorder 不存在 / 构造失败 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E4007 | 录制格式不支持 | isTypeSupported 候选格式全否（AV03 探针） <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E4008 | 录制启动失败 | MediaRecorder.start 抛错 |
| E4009 | 录制无数据 | ondataavailable 无数据 / 分片全空 |
| E4010 | 音频解码失败 | decodeAudioData 抛错（AV04 分析路径） |
| E4011 | 音频播放失败 | SpeechAudioPlayer / 媒体元素播放抛错 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |

### 5xxx 存储
| 码 | 说明 | 典型触发 |
|---|---|---|
| E5001 | 记录保存失败 | localStorage/wx 存储写入抛错 |
| E5002 | 记录读取失败 | 读取/JSON 解析抛错 |
| E5003 | 存储空间不足 | 写入被配额拒绝 |
| E5004 | 存档版本不兼容 | 持久数据结构版本不符、解析或迁移失败 |
| E5005 | 持久化不可用 | localStorage / 存储接口不存在或被禁用 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |

### 6xxx 网络与 LLM
| 码 | 说明 | 典型触发 |
|---|---|---|
| E6001 | 大模型不可用 | LanguageModel.availability 非 available |
| E6002 | 大模型请求失败 | prompt/promptStreaming 抛错或流失败 |
| E6003 | 大模型超时 | 请求超时未返回 |
| E6004 | 网络不可达 | fetch/wx.request 失败 |
| E6005 | 图片输入失败 | 图片 dataURL 构造/传入失败（非 FileReader 类，FileReader 类归 E2005） |
| E6006 | 大模型未就绪（已停用） | 停用，不得再用：官方文档明文 `availability` 只有 available / unavailable 两态、无中间态；大模型不可用用 E6001。本码永不复用 |
| E6007 | 服务端错误 | HTTP 5xx 或接口业务错误 |
| E6008 | 请求被拒 | HTTP 4xx / 鉴权失败（401/403；dabiaoge 通道 401 属此） |
| E6009 | 响应解析失败 | 网络响应 JSON / 结构解析抛错 |
| E6010 | 域名不在白名单 | 请求域名未报备白名单、被宿主拦截 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E6011 | 大模型输出不可用 | 空响应或结构不符预期、无法解析为业务数据 |

### 7xxx 传感器、定位与检测
| 码 | 说明 | 典型触发 |
|---|---|---|
| E7001 | 朝向传感器不可用 | AbsoluteOrientationSensor 构造/启动失败 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E7002 | 定位失败 | getCurrentPosition error 2/3 |
| E7003 | 定位权限未给 | getCurrentPosition error 1 |
| E7004 | 条码检测失败 | BarcodeDetector.detect 抛错 |
| E7005 | 码制不支持 | getSupportedFormats 不含目标码制 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E7006 | 手势通道异常 | 世界感知开启失败 enableWorldAwareness 抛错 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E7007 | 惯性传感器不可用 | Accelerometer / Gyroscope 构造或启动失败 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E7008 | 传感器无数据 | 传感器已启动但超时无读数（benchmark 朝向/动作项超时类） <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E7009 | 条码检测器不可用 | BarcodeDetector 不存在 / 构造失败（与 E7004 的 detect 抛错区分） <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E7010 | 头部校准失败 | 校准无法完成，或校准中心漂移过大（头部游戏 / 指向类） <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |

### 8xxx 页面与运行时
| 码 | 说明 | 典型触发 |
|---|---|---|
| E8001 | 页面切换失败 | wx.navigateTo/navigateBack 抛错 |
| E8002 | 页面被系统回收 | 非正常 onUnload 且任务未完 <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E8003 | 权限未声明 | 调用能力与 app.json 权限不符（开发期自查码） |
| E8004 | 运行时接口缺失 | 所需全局接口不存在（X is not defined 通用码；编码上下文的 FileReader 归 E2005） <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E8005 | 输入事件未达页面 | 按键/手势事件未送达页面（开发期自查码：onKeyDown 未接线、bindtap-only 在真机不可触发类） <img src="assets/badges/badge-nosim.svg" height="20" alt="模拟器无法触发"> |
| E8006 | 会话状态丢失 | 跨页/重进后会话状态缺失（媒体帧丢失归 E4005） |

### 9xxx 系统
| 码 | 说明 | 典型触发 |
|---|---|---|
| E9001 | 未分类错误 | 兜底（原文截断附带） |
| E9002 | 配置缺失 | 必需配置/常量为空 |

## 前缀（已废止）
不使用任何前缀：系列前缀（AV / CC / BO …连写）与无编号短码（BENCH / PROBE / DABIAO / MYAGT、BA）全部废止，沿革见变更日志。

## 现场已回报码
- **E2005**（2026-10-28 真机，AV11 v1.1.0 首报）：原文「FileReader is not defined」——Ink 运行时无 FileReader（aiui-dev 官方参考全文亦无），编码后转 dataURL 每帧必死、0 帧超时退出。全舰队 grep 实查共 39 个文件用了 FileReader（AV01/02/08/10、stream-probe、games 多台、directional 4 台、curb-cut 5 台、cover/hold/filter/review/japan/korea 若干），真机同环同死，批量修复由登记处统筹（修法样板 = AV11 验证中的 arrayBuffer + 分块 btoa，AV11 本台由其开发方负责，登记处不直接动）。

## 变更日志

| 版本日期 | 内容 |
|---|---|
| v1.8.0（2026-10-29） | 规范合并（GO 指令）：分发版的「接入指令」并入本表，新增「接入规范（给开发者与 AI agent）」一节——单点定义（含 err.js 参考形态）、失败点全映射、三处同码、README 模板、静态自查五件事，治理一节的接入要求改为指向该节。84 码含义一字未动（MINOR：规范增补）。 |
| v1.7.0（2026-10-29） | E6006 停用（GO 裁定）：该码原触发写作 availability 为 downloadable / downloading 中间态——同日官方文档全量审计查实 `LanguageModel.availability()` 只有 available / unavailable 两态，该前提系当年按 Chrome 习惯臆测、并不存在。码义保留原样、永不复用，新开发不得再引用；大模型不可用一律用 E6001。其余各码一字未动（MINOR：码状态变更）。 |
| v1.6.3（2026-10-29） | 首段如实归因：GO 指出原写法像把责任推给模拟器——官方 API 参考是清单式的、FileReader 查无此项，首错在开发侧未对清单核对；改写为开发侧误用清单外 API 在先、模拟器与本地预览的完整 Web 环境把此错藏住在后、真机靠 E2005 揭出。立表理由与判定不变（PATCH）。 |
| v1.6.2（2026-10-29） | 变更日志重排版：GO 指令改为两列表格（版本日期 \| 内容），今后按此版式追加。各版内容一字未动（PATCH）。 |
| v1.6.1（2026-10-29） | 徽章醒目化：GO 指令——删除线「模拟器」徽章由深灰改亮红（#e53935）、行内显示高度 18→20，一眼可见。判定与码义不变（PATCH）。 |
| v1.6.0（2026-10-29） | 标记改徽章：GO 指令删除「模拟器无法触发」列——29 码的标记改为在典型触发句尾加删除线「模拟器」徽章（新增 `assets/badges/badge-nosim.svg`，本表专用标记、非系列徽章）。判定集合与 84 码含义一字未变。 |
| v1.5.5（2026-10-29） | 说明去重：GO 指令——已记入变更日志的沿革，正文说明不再赘述：编码规则去掉前缀试行史、治理的版本规则去掉例外叙事、本表版本行只留版本号与日期、前缀节与现场记录同步收紧。规则本体与 84 码一字未变。今后正文只写现行规则，沿革只进本日志。 |
| v1.5.4（2026-10-29） | 列定义收紧：GO 指出「模拟器无法触发」列的原说明有歧义，定义改为一句话——**是 = 这个码背后的失败原因，模拟器模拟不出来**（如真机运行时缺失的接口、眼镜硬件与宿主服务的真实行为），在模拟器里不会真实发生；否 = 原因与环境无关、模拟器里同样会发生。逐码判定一字未变（29 是 / 55 否），84 码含义不变。 |
| v1.5.3（2026-10-29） | 通用化：GO 指令——本文档做成通用件、供其他 AI agent 直接使用，全文去除特定 AI 助手与内部工作环境的指向：对表定位的主体改称「维护者」，登记处不再指向某个具体工作环境而只作通用维护方，删除环境专属的本地镜像路径说明。84 码含义与各列判定一字未变。 |
| v1.5.2（2026-10-29） | 「为什么要这张表」重整：GO 指令把其认可的论证整理进本节——以 AV11 / FileReader 为现成反例（模拟器全绿、真机全灭、靠 E2005 对表定位），划清模拟器能覆盖与覆盖不了的边界（并引官方「最终体验以真机为准」口径），点明官方真机链路到送达为止、运行期是黑盒，再补一层：错误码不只是调试工具，也是小屏单色、无其他信息通道条件下用户唯一能记住并报出的失败语言；结论 = 两套分工不重复。纯文字重整，84 码含义与各列判定一字未变。 |
| v1.5.1（2026-10-29） | 「为什么要这张表」一节：GO 指令在编码规则前补上立表理由：官方真机链路只提示送达（打包上传结果、资源包下载成功），运行期错误无回传、无记录、无查看入口；模拟器是另一套运行时，29 码的触发在其中不存在；眼镜端屏幕小、信息转瞬、摄像头占用时无法截图、原文转述必失真——故以全舰队同义短码屏显 + TTS + `lastError` 对齐 debug。纯说明增补，84 码含义与各列判定一字未变。 |
| v1.5.0（2026-10-28） | 「模拟器无法触发」列：GO 指令核查哪些码的触发是 Studio 网页模拟器无法复现的，码表新增一列逐码标注。判定口径 = 典型触发依赖真机 Ink 运行时 / 眼镜硬件 / 宿主服务 / 设备资源状态者标「是」（模拟器不存在该条件），与环境无关或浏览器有同类机制者标「否」。结果：29 码标「是」——1xxx 3（E1003/E1006/E1010）、2xxx 4（E2002/E2005/E2006/E2007）、3xxx 7（E3001/E3007/E3008/E3010/E3012/E3014/E3015）、4xxx 3（E4006/E4007/E4011）、5xxx 1（E5005）、6xxx 1（E6010）、7xxx 7（E7001/E7005/E7006/E7007/E7008/E7009/E7010）、8xxx 3（E8002/E8004/E8005）、9xxx 0；其余 55 码标「否」。84 码含义一字未变。此列即「只能真机覆盖」的清单：模拟器全绿也证明不了这 29 码不触发（首个现场码 E2005 正是其一）。 |
| v1.4.0（2026-10-28） | 裸码定版：GO 改判——数字段本身全舰队唯一同义，系列前缀不提供额外定位信息、属多此一举。唯一形态改回裸码 `E####`（代码 / 屏显 / TTS / lastError / README / debug 全用它），系列前缀与 BA / 短码前缀全部废止；agent 身份由上下文与 `lastError` 的 slug 锁定。格式在定版当晚三易（编号式 → 系列式 → 裸码），均未形成存量（唯一用过全连写的 AV11 v1.1.2 待复验版已通知其下一版改正），故仍以次版本留痕；此为最终格式，除 GO 再下令外不再变更。84 码含义一字未变。 |
| v1.3.0（2026-10-28） | 唯一形态定版：GO 指令全舰队只用一套编码规则——全码 `<系列码>E<4位>` 定为唯一形态（代码定义 / 屏显 / TTS / lastError / README / debug 对齐全用它），裸 `E####` 降为仅限本表的登记形态、运行时与沟通禁用；agent 代码内以全码字面量定义、不再运行时拼接。84 码含义一字未变。 |
| v1.2.0（2026-10-28） | 格式修正合并版：GO 23:22 修正回报格式——前缀改**系列码**、全连写无分隔符（AVE2005 / CCE1234 / BOE0002），台号不占码位、具体哪台由报错上下文锁定；登记处确认无编号 base 系列统一 **BA** 前缀，v1.0.0 的 BENCH / PROBE / DABIAO / MYAGT 短码未启用即废止。本版将该格式修正与登记处 v1.1.0 扩编（+39 码）合并定版：84 码含义一字未变，仅格式与前缀登记册变更。 |
| v1.1.0（2026-10-28） | 登记处扩编：登记处接管本表。枚举目前能够知道的全部错误信息并编码：依据 = 能力档案红线、全舰队代码实查（OverconstrainedError 23 处、ASR 错误事件六种、LanguageModel availability 调用 41 处、isTypeSupported / decodeAudioData / createImageBitmap / getCurrentPosition 等引用面）与既有真机教训。新增 39 码：1xxx +5（E1007–E1011）、2xxx +3（E2011–E2013）、3xxx +10（E3006–E3015）、4xxx +6（E4006–E4011，段题扩为「录制、合成与播放」）、5xxx +2（E5004–E5005）、6xxx +6（E6006–E6011）、7xxx +4（E7007–E7010）、8xxx +3（E8004–E8006）、9xxx +0；既有 45 码含义一字未改。治理补「申请新码流程」与版本规则；canonical 落仓库根目录。 |
| v1.0.0（2026-10-28） | 立表：源自 AV11 现场表扩展：回报格式、编号前缀规则、九段约 45 码、无编号前缀登记册（BENCH/PROBE/DABIAO/MYAGT）与治理骨架。 |
