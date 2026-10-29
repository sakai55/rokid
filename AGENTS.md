# 真境探针 Real MUD Probe — Design Contract

v1.0.0：真境漫游（RealMUD）阶段 1 的前置合并探针。目的只有一个：把正式版开工前说不准的四组数测出来——存储配额、开掌手势 LLM 定格判定认对率、头部朝向误差与头稳耗时、拍照建房判定分段耗时。探针不占正式游戏本体、不进根 README 清单、**不提审**（内部真机验证用）。

## Design contract

- 7 页：首页（四站入口 + 进度摘要）、存储、手势、朝向、判定耗时、结果单、设置/自检。app.json 页数 = 7，实数对齐。
- 结果统一落 `mud.probe.results.v1`（wx 存储），键结构：`storage` / `gesture.trials[]` / `heading{trials[], nods, calibrated}` / `timing.runs[]`。每站完成即落盘，关掉重开不丢；设置页可整体清除重测。
- **存储站**：localStorage 与 wx 存储各测——单值 1/10/50/100KB 写+读回校验（长度 + checksum）、累计 10KB 一块堆到失败或 500KB 上限、样本房间块 JSON（约 2.4KB）往返逐字比对、时间戳标记（进页先读旧标记再被本轮覆盖，结果单显示上轮标记在/不在）。测完清测试键。
- **手势站**：开掌静态判定 10 次，管线 = 拍照（default）→ 缩图宽 480（失败回退原图并标注）→ `arrayBuffer` + 分块 `btoa` 转 data URL → `LanguageModel` 图片输入，只收结构化 JSON `{gesture: open_palm|other|none, confidence, recognized[]}`，枚举外/把握非数按 E6011 失败处理、不占次数。对错由测试者标真值（对/错），LLM 的答案永远不自任真值。认对 <5/10 时阶段 1 手势开门按探针门降级自评——判定在本探针之外由数据说话。
- **朝向站**：`AbsoluteOrientationSensor` 四元数 → yaw（舰队既有公式）。首读 null 是正常态不当错误；启动 5 秒无读数才报 E7008；构造/出错 E7001；`enableWorldAwareness` 失败 E7006。校准 = 以当前朝向为中心（相对北 0°），四向（东 90/南 180/西 270/北 0）依次测：进入 ±10° 窗口连续 800ms 记到达，记误差度数与从出题到锁定的总耗时。点头在本站只计数（`onHeadGesture` 通道单测），不触发任何操作。中心角度不跨会话保存（磁北会漂），`calibrated` 只记曾校准过，进页必须重校。
- **耗时站**：default 拍照建房判定 3 次，分段 = 拍照（开流+takePhoto）/ 编码（缩图+data URL）/ LLM 往返 / 总。判定走架构 §5 的房间 JSON 结构（recognized / sceneSummary / confidence / uncertain / facesPresent / privateOrDanger / gesture）。每次并行发起一次非阻塞定位：成功补记精度米数，失败记 E7002/E7003（权限拒绝时经 fail 落 lastError），永不阻塞判定、不计入总耗时。LLM 45 秒超时熔断 E6003。
- **结果单**：四站大字汇总（存储各档 ✓/✗ 与累计 KB、手势认对 x/10 与平均把握、朝向平均误差与点头数、判定总耗时中位数与平均把握）+ 逐次明细。进页同时经 logq 上报一条汇总（配了才发）。
- **错误码**：单点定义在 `err.js`，裸码，`fail()` 三处同码（屏显行 / lastError / 可选 TTS 只读码）。本台可出码：E1001 E1002 E1003 E1007 E1009 E2013 E5001 E5002 E6001 E6002 E6003 E6005（data URL 形状自检）E6009 E6011 E7001 E7002 E7003 E7006 E7008 E8001 E9001。业务代码不散写码字面量（EVT 调试行除外，与舰队惯例一致）。
- **日志回传**：`logq.js` 照 AV11 v1.2.0 形态（本地队列上限 100、按 session 分批 ≤50、fire-and-forget、失败留队）。配置在 `config.js` 一处：`BASE_URL` + `CHANNEL_KEY` 两件齐才启用，缺一即完全 no-op 静默。仓库只存占位符，真钥只在 Studio 就地填、永不回推。flush 时机：各站完成、进结果单、下次启动。
- 手势映射（全页）：滑动 = 切焦点（ArrowUp/Down）；单击 = 执行焦点（Enter）；双击 = 返回（Backspace，页面 onKeyDown 自接，不依赖 bindtap）；点头 = 执行焦点（朝向页例外：只计数）。每页都接 onKeyDown——bindtap-only 在真机不可触发的教训。

## Technical honesty

- Web 预览里：存储站可真跑（浏览器存储宽松，全过 + 撞 500KB 人为上限——只证明逻辑，不证明眼镜配额）；相机/LLM/传感器/定位在预览里不可用或不真实，相关站会以裸码如实失败（如朝向页预览出 E7001），不模拟结果。全部四站的真实数字只能来自真机一轮。
- 照片与 data URL 永不落盘、永不进日志；存档只留数字、判定摘要与一句场景概括。
- 朝向的「北」是校准相对角，不是磁北真值——探针测的是相对转头的误差与稳定性，不宣称绝对指向精度。

## Permissions

- `CAMERA` — 手势站与耗时站的定格拍照判定。
- `GEOLOCATION` — 耗时站的非阻塞定位读取（精度记录）。
- 不用 ASR，不声明 `RECORD_AUDIO`。与 app.json 声明一致。

## Validation

- Static（2026-10-29 已跑）：app.json/package.json JSON 解析通过；全部 .js 与 7 页 .ink setup 脚本 `node --check` 通过；禁用 API grep（代码文件）0 命中（含 FileReader 字面 0）；过时模式（App(/Page(/require/workers 字段等）0 命中；纯白 0 命中；错误码逐个对根表 v1.14.0 核义。
- 预览：本地管线 7 页截图全产出、互异、无 pageerror；存储站在预览里实跑一轮全过（见上 honesty 注）。
- Device stage (pending)：GO 真机一轮回结果单（或日志回传），四站数字回填 MUD/README.md 台账后，才冻结《操作定义 v1》并开阶段 1 本体。
