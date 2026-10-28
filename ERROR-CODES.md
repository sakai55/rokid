# Rokid 全局错误码表（Global Error Codes）v1.11.0

GO 2026-10-28 定立：任何 Agent 发生任何错误，眼镜上统一显示错误码，用户只报码即可对表定位。

**这是唯一文件**：编码规则、治理、接入规范（含可直接照抄的代码示例）与全部码表都在本文件内，分区见目录。任何开发者或 AI agent 整份取用即可。

## 目录

- [给 AI agent 的执行指令（先读这一节）](#给-ai-agent-的执行指令先读这一节)
- [1. 编码规则](#1-编码规则)
- [2. 治理](#2-治理)
- [3. 接入规范（给开发者与 AI agent）](#3-接入规范给开发者与-ai-agent)
- [4. 码表](#4-码表)
- [5. 现场已回报码](#5-现场已回报码)
- [6. 变更日志](#6-变更日志)
- [7. 为什么需要错误码](#7-为什么需要错误码)

## 给 AI agent 的执行指令（先读这一节）

这套错误码不是官方规范，是开发者在自己的项目里实际用下来的一套约定，分享给同样做 Rokid AIUI Agent 的开发者和 AI agent。要给一个 Agent 接入错误码，按下面五步做就行：

1. **错误码只认本表**（第 4 节）：只用表里存在的码；不自造码、不改码义、不用任何前缀，唯一形态是裸码 `E####`。
2. **接入步骤在第 3 节**：五件事——单点定义、失败点全映射、三处同码、README 留一节、静态自查。代码示例可直接照抄后按本台情况改名增删，不要另行设计结构。
3. **选码方法**：按失败点在第 4 节逐段查最贴切的码；查不到贴切的，用兜底码 `E9001` 并在 `lastError` 留原文，事后按第 2 节流程申请新码。回告之前不要用自拟码上线。
4. **三件不要做的事**：不把英文报错原文直接显示给用户，原文只进 `lastError`；不用已停用的码（当前为 E6006）；不在业务代码里散写码字符串，一律走单点定义模块。
5. **打包前必跑第 3 节第（5）步的静态自查**，grep 结果留痕。

还有一条总原则：**错误处理不许制造新错误**。报错、记录、回传的代码全程不抛错、不惊动使用者，细则在第 3 节开头。

## 1. 编码规则

- **唯一形态：裸码 `E<4 位数字>`**，如 E2005。代码定义、眼镜屏显、TTS 播报、`lastError`、README 与调试沟通全部只用裸码，不加任何前缀。
- **同码同义**：同一个码在所有 Agent 里含义相同。定位到具体哪个 Agent，靠报错上下文与 `lastError` 里记录的 slug 与版本。
- **段位按错误领域分**，不按 Agent 分：
  - 1xxx 相机与图像采集
  - 2xxx 帧数据与编码转换
  - 3xxx 语音（ASR / TTS）
  - 4xxx 录制、合成与播放
  - 5xxx 存储与文件
  - 6xxx 网络与大模型
  - 7xxx 传感器、定位与检测
  - 8xxx 页面与运行时
  - 9xxx 系统兜底：E9001 未分类兜底、E9002 宿主或系统级异常

## 2. 治理

- **维护方**：本表由登记处唯一维护。新码分配、段位扩展都经登记处；需要新码时按下面流程申请，不许自行占码。
- **申请新码**：说明三件事——失败点、触发原文、自拟归段。登记处核对无同义码后顺序分配并回告；回告前不许先用自拟码上线。紧急现场可先用 E9001 兜底、在 `lastError` 留原文，事后补申请。
- 码一经分配**永不改义、永不复用**；废弃的码保留原义并标注「已停用」。
- 新码只在对应段内顺序追加；段满或出现新领域时由登记处开新段。只增新码升次版本号；规则或格式变更升主版本号；纯措辞、排版修订升修订号。每次升版在变更日志记一条。
- **版本存档**：每次升版，被取代的旧版全文快照存入 `base/error/ERROR-CODES-v<旧版本号>.md`，仓库根目录只留最新版。现行规则与码义只认根目录最新版。
- 每个 Agent 的接入按第 3 节「接入规范」执行。
- 本表版本：v1.11.0（2026-10-29），位置 = 仓库根目录 `ERROR-CODES.md`。各 Agent 工程内可放副本，冲突时以根目录版为准。

## 3. 接入规范（给开发者与 AI agent）

**总原则：错误处理不许制造新错误。** 为报错而加的代码——屏显、播报、写 `lastError`、日志队列与回传——本身不许成为新的错误来源：统一失败出口全程不抛错，各动作失败各自静默吞掉，主流程的成败不因报错动作改变。日志回传是独立可选件，不接不影响本规范任何一条；接了但没配置钥匙、或发送失败时，同样完全静默，不给使用者添困惑。

把一个 agent 接入本表，做五件事：

**（1）单点定义。** 在工程里建一个错误码模块（如下 `err.js`），把本台用到的码以裸码字面量集中定义一次，禁止在业务代码里散写字符串、禁止运行时拼前缀。下面的模块可直接照抄，按本台用到的码增删 `ERR` 与 `MESSAGES` 两张表即可：

```js
// err.js —— 错误码单点定义 + 统一失败出口
// 码义以全局错误码表为准；业务代码只许引用 ERR.*，不许散写 'E####' 字符串。

export const ERR = {
  CAM_OPEN: 'E1001',        // 相机打开失败
  PHOTO: 'E1009',           // 拍照失败
  ENCODE_TEXT: 'E2005',     // 编码转文本失败
  ASR_ERROR: 'E3003',       // ASR 其他错误（兜底）
  ASR_DENIED: 'E3008',      // 麦克风未授权
  UNKNOWN: 'E9001'          // 未分类兜底
};

const MESSAGES = {
  E1001: '相机打开失败',
  E1009: '拍照失败',
  E2005: '编码转文本失败',
  E3003: '语音识别出错',
  E3008: '麦克风未授权',
  E9001: '未分类错误'
};

// 页面把自己的屏显函数注册进来（大字码 + 一行说明）；err.js 不直接碰页面结构。
let showOnScreen = null;
export function onShowError(fn) { showOnScreen = fn; }

// 统一失败出口：屏显 +（停机类）TTS 只读码 + 写 lastError，三处同一个码。
// raw 传原始 error 对象或字符串，只进 lastError，截断 300 字，永不直接上屏。
export function fail(code, raw, opts = {}) {
  const entry = {
    code,
    slug: opts.slug || '',
    version: opts.version || '',
    raw: String((raw && raw.message) || raw || '').slice(0, 300),
    at: new Date().toISOString()
  };
  try { wx.setStorageSync('lastError', entry); } catch (e) { /* 存储再失败也不许抛错 */ }
  if (showOnScreen) showOnScreen(code, MESSAGES[code] || '未分类错误');
  if (opts.speak) {
    try {
      speechSynthesis.speak(new SpeechSynthesisUtterance(code)); // 只读码本身，不念原文
    } catch (e) { /* 播报失败不再抛错 */ }
  }
  return entry;
}
```

**（2）失败点全映射。** 逐个走查代码里所有会失败的调用（相机、编码、ASR/TTS、LLM、网络、存储、传感器、页面切换……），每个失败点映射到表中一个码；表里没有贴切的码时用 E9001 并保留原文。不许裸抛原文了事——原文只作附带诊断，截断后显示或只进 `lastError`。接线形态照下面两个例子：

```js
// 例 1：拍照失败点 —— try/catch 后调 fail()，然后降级返回，不裸抛
async function takeShot(capture) {
  try {
    return await capture.takePhoto({ mode: 'telephoto' });
  } catch (e) {
    fail(ERR.PHOTO, e);   // 屏显 E1009 + 写 lastError
    return null;          // 调用方拿到 null 走降级流程
  }
}

// 例 2：ASR 错误事件 —— 只映射自己真正处理过的类别，其余一律兜底 E3003
// 注意：ASR 错误类别字符串官方文档没有枚举表，未经真机验证的类别不要细分新码。
rec.onerror = (event) => {
  if (event.error === 'not-allowed') fail(ERR.ASR_DENIED, event, { speak: true });
  else fail(ERR.ASR_ERROR, event);
};
```

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

**（5）静态自查。** 打包前跑下面三条，结果留痕：

```bash
grep -rn "FileReader" <工程目录>                 # 必须 0 命中（运行时不存在此 API）
grep -rEoh "E[0-9]{4}" <工程目录> | sort -u      # 本台用到的全部码，逐个对第 4 节核义
grep -rn "'E[0-9]" <业务代码目录> --include=*.js | grep -v err.js
                                                 # 业务代码里散写的码字符串，必须 0 命中
```

**附例：Blob 转 dataURL 的正确写法（E2005 的由来）。** AIUI 的 API 是清单式的，官方参考里没有的浏览器 API（如 `FileReader`）不存在于运行时；需要把 Blob 转文本时照下面写，不要用 FileReader：

```js
// blobToDataUrl —— arrayBuffer + 分块 btoa（整块转换大图会爆栈，必须分块）
export async function blobToDataUrl(blob) {
  const bytes = new Uint8Array(await blob.arrayBuffer());
  let bin = '';
  const CHUNK = 0x8000;
  for (let i = 0; i < bytes.length; i += CHUNK) {
    bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CHUNK));
  }
  return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
}
```

## 4. 码表

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

## 5. 现场已回报码

- E2005 —— 真机回报：Ink 运行时无 FileReader，Blob 转 dataURL 须用 `arrayBuffer()` 加分块 `btoa`，写法见第 3 节附例。

## 6. 变更日志

### v1.11.0（2026-10-29）

总原则入规范（GO 指令）：第 3 节开头立「错误处理不许制造新错误」——失败出口全程不抛错、各动作失败各自静默、主流程成败不因报错动作改变；并写明日志回传是独立可选件，没配置钥匙或发送失败时完全静默。执行指令一节末尾同步加总原则提示。第 4 节码表与 84 码含义一字未动（MINOR：规范增补）。

### v1.10.1（2026-10-29）

口吻：执行指令一节的开头去掉命令式语气，改为开发者之间分享约定的平实说法，并写明这套错误码不是官方规范、维护方也只是开发者之一；「三条禁令」改称「三件不要做的事」。内容与 84 码含义未动（PATCH：措辞）。

### v1.10.0（2026-10-29）

全文精简（GO 指令）：「为什么」一节移到文末并压缩；删除「前缀（已废止）」一节，其沿革留在本日志 v1.2.0 至 v1.4.0 各条内；编码规则、治理、执行指令、现场记录去掉内部表述与括号赘述，改通用开发者口径；标题去掉「舰队」；章节重新编号为 1 编码规则 / 2 治理 / 3 接入规范 / 4 码表 / 5 现场已回报码 / 6 变更日志 / 7 为什么。第 3、4 节内容与 84 码含义一字未改（MINOR：结构与表述精简）。


### v1.9.2（2026-10-29）

归档制度（GO 指令）：老版本快照统一存入 `base/error/`（文件名 `ERROR-CODES-v<版本号>.md`，首行加存档横幅），仓库根目录只留最新版，治理一节增「版本存档」一条。本次补齐 v1.1.0–v1.9.1 共 17 个历史快照入档；v1.0.0 无独立存世快照（canonical 落仓库根目录始于 v1.1.0）、v1.5.3 与 v1.5.4 同一提交落地无独立快照，两处缺口已在存档索引中注明。84 码含义一字未动（PATCH：治理增补）。

### v1.9.1（2026-10-29）

排版：变更日志由两列表格改为条目式——每版一条，首行「版本号（日期）」作小标题、内容成段（GO 指令）。此前各版内容与 84 码含义一字未动（PATCH：排版）。

### v1.9.0（2026-10-29）

单文件定版（GO 指令）：只需要一个文件——分发版 `ROKID-ERROR-CODES.md` 退役删除，其内容并入本文件；本文件加目录与编号分区（1 原理 / 2 规则 / 3 治理 / 4 接入规范 / 5 码表 / 6 前缀 / 7 现场码 / 8 变更日志），开头新增「给 AI agent 的执行指令」一节；第 4 节代码示例补全为可直接照抄的完整形态（err.js 完整模块、拍照/ASR 接线示例、三条静态自查 grep、附 Blob 转 dataURL 正确写法）。84 码含义一字未动（MINOR：结构与规范完善）。

### v1.8.0（2026-10-29）

规范合并（GO 指令）：分发版的「接入指令」并入本表，新增「接入规范（给开发者与 AI agent）」一节——单点定义（含 err.js 参考形态）、失败点全映射、三处同码、README 模板、静态自查五件事，治理一节的接入要求改为指向该节。84 码含义一字未动（MINOR：规范增补）。

### v1.7.0（2026-10-29）

E6006 停用（GO 裁定）：该码原触发写作 availability 为 downloadable / downloading 中间态——同日官方文档全量审计查实 `LanguageModel.availability()` 只有 available / unavailable 两态，该前提系当年按 Chrome 习惯臆测、并不存在。码义保留原样、永不复用，新开发不得再引用；大模型不可用一律用 E6001。其余各码一字未动（MINOR：码状态变更）。

### v1.6.3（2026-10-29）

首段如实归因：GO 指出原写法像把责任推给模拟器——官方 API 参考是清单式的、FileReader 查无此项，首错在开发侧未对清单核对；改写为开发侧误用清单外 API 在先、模拟器与本地预览的完整 Web 环境把此错藏住在后、真机靠 E2005 揭出。立表理由与判定不变（PATCH）。

### v1.6.2（2026-10-29）

变更日志重排版：GO 指令改为两列表格（版本日期 | 内容），今后按此版式追加。各版内容一字未动（PATCH）。

### v1.6.1（2026-10-29）

徽章醒目化：GO 指令——删除线「模拟器」徽章由深灰改亮红（#e53935）、行内显示高度 18→20，一眼可见。判定与码义不变（PATCH）。

### v1.6.0（2026-10-29）

标记改徽章：GO 指令删除「模拟器无法触发」列——29 码的标记改为在典型触发句尾加删除线「模拟器」徽章（新增 `assets/badges/badge-nosim.svg`，本表专用标记、非系列徽章）。判定集合与 84 码含义一字未变。

### v1.5.5（2026-10-29）

说明去重：GO 指令——已记入变更日志的沿革，正文说明不再赘述：编码规则去掉前缀试行史、治理的版本规则去掉例外叙事、本表版本行只留版本号与日期、前缀节与现场记录同步收紧。规则本体与 84 码一字未变。今后正文只写现行规则，沿革只进本日志。

### v1.5.4（2026-10-29）

列定义收紧：GO 指出「模拟器无法触发」列的原说明有歧义，定义改为一句话——**是 = 这个码背后的失败原因，模拟器模拟不出来**（如真机运行时缺失的接口、眼镜硬件与宿主服务的真实行为），在模拟器里不会真实发生；否 = 原因与环境无关、模拟器里同样会发生。逐码判定一字未变（29 是 / 55 否），84 码含义不变。

### v1.5.3（2026-10-29）

通用化：GO 指令——本文档做成通用件、供其他 AI agent 直接使用，全文去除特定 AI 助手与内部工作环境的指向：对表定位的主体改称「维护者」，登记处不再指向某个具体工作环境而只作通用维护方，删除环境专属的本地镜像路径说明。84 码含义与各列判定一字未变。

### v1.5.2（2026-10-29）

「为什么要这张表」重整：GO 指令把其认可的论证整理进本节——以 AV11 / FileReader 为现成反例（模拟器全绿、真机全灭、靠 E2005 对表定位），划清模拟器能覆盖与覆盖不了的边界（并引官方「最终体验以真机为准」口径），点明官方真机链路到送达为止、运行期是黑盒，再补一层：错误码不只是调试工具，也是小屏单色、无其他信息通道条件下用户唯一能记住并报出的失败语言；结论 = 两套分工不重复。纯文字重整，84 码含义与各列判定一字未变。

### v1.5.1（2026-10-29）

「为什么要这张表」一节：GO 指令在编码规则前补上立表理由：官方真机链路只提示送达（打包上传结果、资源包下载成功），运行期错误无回传、无记录、无查看入口；模拟器是另一套运行时，29 码的触发在其中不存在；眼镜端屏幕小、信息转瞬、摄像头占用时无法截图、原文转述必失真——故以全舰队同义短码屏显 + TTS + `lastError` 对齐 debug。纯说明增补，84 码含义与各列判定一字未变。

### v1.5.0（2026-10-28）

「模拟器无法触发」列：GO 指令核查哪些码的触发是 Studio 网页模拟器无法复现的，码表新增一列逐码标注。判定口径 = 典型触发依赖真机 Ink 运行时 / 眼镜硬件 / 宿主服务 / 设备资源状态者标「是」（模拟器不存在该条件），与环境无关或浏览器有同类机制者标「否」。结果：29 码标「是」——1xxx 3（E1003/E1006/E1010）、2xxx 4（E2002/E2005/E2006/E2007）、3xxx 7（E3001/E3007/E3008/E3010/E3012/E3014/E3015）、4xxx 3（E4006/E4007/E4011）、5xxx 1（E5005）、6xxx 1（E6010）、7xxx 7（E7001/E7005/E7006/E7007/E7008/E7009/E7010）、8xxx 3（E8002/E8004/E8005）、9xxx 0；其余 55 码标「否」。84 码含义一字未变。此列即「只能真机覆盖」的清单：模拟器全绿也证明不了这 29 码不触发（首个现场码 E2005 正是其一）。

### v1.4.0（2026-10-28）

裸码定版：GO 改判——数字段本身全舰队唯一同义，系列前缀不提供额外定位信息、属多此一举。唯一形态改回裸码 `E####`（代码 / 屏显 / TTS / lastError / README / debug 全用它），系列前缀与 BA / 短码前缀全部废止；agent 身份由上下文与 `lastError` 的 slug 锁定。格式在定版当晚三易（编号式 → 系列式 → 裸码），均未形成存量（唯一用过全连写的 AV11 v1.1.2 待复验版已通知其下一版改正），故仍以次版本留痕；此为最终格式，除 GO 再下令外不再变更。84 码含义一字未变。

### v1.3.0（2026-10-28）

唯一形态定版：GO 指令全舰队只用一套编码规则——全码 `<系列码>E<4位>` 定为唯一形态（代码定义 / 屏显 / TTS / lastError / README / debug 对齐全用它），裸 `E####` 降为仅限本表的登记形态、运行时与沟通禁用；agent 代码内以全码字面量定义、不再运行时拼接。84 码含义一字未变。

### v1.2.0（2026-10-28）

格式修正合并版：GO 23:22 修正回报格式——前缀改**系列码**、全连写无分隔符（AVE2005 / CCE1234 / BOE0002），台号不占码位、具体哪台由报错上下文锁定；登记处确认无编号 base 系列统一 **BA** 前缀，v1.0.0 的 BENCH / PROBE / DABIAO / MYAGT 短码未启用即废止。本版将该格式修正与登记处 v1.1.0 扩编（+39 码）合并定版：84 码含义一字未变，仅格式与前缀登记册变更。

### v1.1.0（2026-10-28）

登记处扩编：登记处接管本表。枚举目前能够知道的全部错误信息并编码：依据 = 能力档案红线、全舰队代码实查（OverconstrainedError 23 处、ASR 错误事件六种、LanguageModel availability 调用 41 处、isTypeSupported / decodeAudioData / createImageBitmap / getCurrentPosition 等引用面）与既有真机教训。新增 39 码：1xxx +5（E1007–E1011）、2xxx +3（E2011–E2013）、3xxx +10（E3006–E3015）、4xxx +6（E4006–E4011，段题扩为「录制、合成与播放」）、5xxx +2（E5004–E5005）、6xxx +6（E6006–E6011）、7xxx +4（E7007–E7010）、8xxx +3（E8004–E8006）、9xxx +0；既有 45 码含义一字未改。治理补「申请新码流程」与版本规则；canonical 落仓库根目录。

### v1.0.0（2026-10-28）

立表：源自 AV11 现场表扩展：回报格式、编号前缀规则、九段约 45 码、无编号前缀登记册（BENCH/PROBE/DABIAO/MYAGT）与治理骨架。

## 7. 为什么需要错误码

真机运行期没有日志回传：Studio 的打包结果与手机 App 的资源包下载提示只证明包送到了眼镜，Agent 跑起来之后出的错没有回传、没有记录、没有查看入口，只能靠使用者回报。

模拟器替不了真机：模拟器是完整 Web 环境，与真机运行时的 API 清单并不一致，一类问题在模拟器里毫无征兆、只在真机暴露。例如 FileReader 在模拟器里能跑，真机运行时根本不存在。本表第 4 节码表中标出的 29 个码，其失败原因模拟器模拟不出来。

眼镜端屏幕小、单色、信息转瞬即逝，出错时使用者记不住英文原文、转述必然失真，能准确报出的只有一个短码。所以统一约定：错误大字屏显、TTS 读码、写入 `lastError` 保存；使用者报一个码，维护者对表即可还原失败点。
