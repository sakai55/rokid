# Code Hold（临时码）

注意力外挂系列 H02（HOLD 默念型）。朋友报的 WiFi 密码、临时门锁码、会议号——这类码的共同点是：只听一遍，走到要输入的地方就已经忘了大半。本 Agent 的做法：朋友说完，你自己复述一遍（麦克风只听你一个人），听写结果放大给你逐字核对，你确认了才存住；要输入时，码在你视线里逐段（每 4 个字符一段）显示，你在另一台设备上输一段、翻一段；输完两下焚掉，不留痕。

![预览-首页](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/code-hold/preview-code-hold-index.png)
![预览-演示听写待核对](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/code-hold/preview-code-hold-demo.png)
![预览-演示列表](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/code-hold/preview-code-hold-list.png)
![预览-逐段显示](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/code-hold/preview-code-hold-show.png)

## 解决的问题

听觉短时记忆对「码」最不友好：它无意义、不可复述成故事，还经常混着字母和数字。本 Agent 把这段路外包掉——捕获只花一次复述（你说一遍），保存必过一次逐字核对（防识别听错），输入时零记忆负担（码就挂在视线里，逐段推进），用完立即焚毁（明文落盘的东西不长期留着）。脑子从复读机里解放出来，码交给眼镜记，且只记到你亲手焚掉为止。

## 注意力外包设计（HOLD 默念型）

- **麦克风只听你，不听朋友**：捕获 = 你把刚听到的码用自己的声音复述一遍。本 Agent 从不声称在听、在录、在转写对方说话——界面状态行、EVT 措辞、本文档都写明「只听你复述」。朋友说一遍，你说一遍，眼镜从你这遍接住。
- **确认即存，未确认绝不存**：听写落在核对屏上，标注「ASR 听写 — 可能听错」，只有你点 OK（Enter）才落盘。错了先改再存：DICT 重念更正，或纯数字码用逐位步进（滑动选位、+1/−1 只改那一位，0↔9 回绕）。含字母的码步进会拒绝并指向重念——这个运行时没有文字键盘，字母码的更正通道只有你的声音，如实说明。
- **逐字原文，大小写不丢**：与 H01 不同，这里的解析器绝不把字母转大写——密码是大小写敏感的，`sunny4829` 就存 `sunny4829`。识别把大小写听成什么样，核对屏就显示什么样，最后由你的眼睛把关。
- **明文存储，无加密（如实说明，本 Agent 的第一诚实边界）**：落盘的是 `{标签, 码, 时间}` 纯文字（key `codeHold`，最多 4 条），存在本应用在眼镜上的本地存储里，**是明文，没有任何加密，本 Agent 也不声称有**。这正是「输完即焚」存在的理由。界面常驻行、信息框安全行、计数行都写明这一点。存满 4 条时第 5 条如实拒绝并保留待核对的这条——绝不静默覆盖，也绝不为了腾位置自动焚掉旧码。本 Agent 只负责**显示**码，不存在也不暗示任何自动填充。
- **逐段显示，默认静默**：打开一条码，按 4 字符一段显示（`4829 · 7713`），当前段大字，滑动或 Enter 翻段，你在另一台设备上输一段看一段。**打开时一个字都不朗读**——密码被无人要求地读出声是泄漏，不是功能。SPEAK 只在你主动点时发声：在显示里逐字读当前这一段（逐字读，数字不会被连成一个数），在列表里只报标签和段数、绝不读码本身。
- **焚毁两步，永不自动**：看到最后一段只会升起提示横幅（「输完 BURN 两下焚掉（不会自动焚）」）——看多久都不会被删。BURN 第一下武装、第二下才删，并朗读一次「已焚」；做别的动作或过 6 秒自动解除武装。
- **逐位念是最稳的路**：字母和符号是识别的脆弱点；数字码逐位念（零五零八 → "0508"，前导零保留）几乎不会错。DIG 按钮切换严格逐位模式；整句全是中文数字时也自动逐位解析。中文数值式（二千五 → "2500"）同样支持，适合会议号。听不出码形的输入如实拒绝、原值不变，绝不猜；短于 2 个字符的结果按误听拒绝。
- **为什么胸前设备做不了**：递回要进视线内（输码时眼睛要在另一台设备的键盘和眼镜显示之间来回，胸前设备没有视线内显示）、清除要免手且可控（两步焚毁）、捕获要贴着你的嘴（头部麦克风听你复述最清楚）——三条都只有头戴设备成立。

## 功能流程

1. **选标签**：LABEL（或捕获时滑动）在 WiFi密码 / 门锁码 / 会议号 / 其他 间切换。
2. **DICT 复述**：先做佩戴者模式麦克风可用性检查（结果单独一行 `MIC CHECK:`，检查流读完设置立即停轨），再用宿主 SpeechRecognition（zh-CN）在它自己的麦克风上听你复述的码。数字码建议开「逐位念」。
3. **核对屏（CONFIRM）**：码以分段大字显示 + 来源标注（ASR 听写 / DEMO）。OK = 确认存入；DICT = 重念更正；纯数字码可滑动移位 + 步进逐位改；BURN = 放弃这条（它本来就没存）。
4. **逐段输入（SHOW）**：列表 OK 打开选中码——每次只大字显示一段，全码分段图在框首行；滑动/Enter 下一段，SPEAK 逐字读当前段，点头 = SPEAK。
5. **焚（BURN）**：列表或显示里 BURN 两下删除并朗读一次「已焚」；看到最后一段会提示焚，但永远不自动焚。
6. **DEMO**：内存播入 2 条记录（WiFi密码 sunny4829 / 门锁码 0508）+ 1 条模拟听写（会议号 90214478）停在核对屏；演示内确认只进演示列表，全程不写真实存储，退出后真实码原样恢复。

## 手势映射

主流程（复述 → 核对 → 存 → 逐段看 → 焚）靠滑动 + 单击 + 点头即可走完：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境主操作 OK：列表 = 打开逐段显示；显示中 = 下一段；捕获中 = 进核对屏；核对屏 = **确认存入** |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 列表：选上一条 / 下一条；显示中：上一段 / 下一段；捕获中：切标签；核对屏（纯数字码）：左移 / 右移修改位 |
| 点头（头稳时） | `onHeadGesture('nod')` | **只等于 SPEAK**：显示中读当前段、列表里报标签+段数；核对屏/捕获中不存不删，只提示。本 Agent 点头永远不焚码（与 H01 的两下点头清除是刻意区别：输码输到一半的码不能被一个头部动作删掉，焚毁只走 BURN 两步） |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由）：

| 按钮 | 理由 |
|---|---|
| LABEL | 切换码的标签（类型的唯一入口；显示中兼作回列表） |
| DICT | 复述捕获/重念更正的主动作（本 Agent 的捕获全靠它） |
| 逐位念 | 数字码的最稳输入法开关（逐位解析，前导零保留） |
| +1 / −1 | 情境步进：列表切换选中；显示中翻段；捕获中步进纯数字缓冲；核对屏改当前位的数字 |
| OK ✓ | Enter 的镜像（情境主操作，含核对屏上的确认存入与显示中的翻段） |
| SPEAK | 主动朗读：显示中逐字读当前段、列表里只报段数（点头的镜像，头不方便动时用） |
| BURN | 焚毁入口：列表/显示中两步焚一条已存的码；核对屏上 = 放弃未存的这条 |
| DEMO | 演示种子数据走完听写核对与逐段显示全程（提审/自测用） |

## 权限

| 权限 | 用途 |
|---|---|
| `RECORD_AUDIO` | DICT 的佩戴者模式麦克风可用性检查（getUserMedia，检查流立即停轨）+ 宿主 SpeechRecognition 听你复述的码/更正（zh-CN） |

只申请 1 项，无相机（听来的码不需要拍照）、无定位。麦克风模式只作用于 getUserMedia 流，永不影响宿主 `SpeechRecognition`；聆听状态标注为 (host ASR)。TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明该属性不生效）。麦克风只在用户点 DICT 时启动，用完立即停掉全部媒体轨道。

## 打包与预览

```bash
cd ~/workspace/rokid/code-hold
~/tools/bin/aix pack . -o ../dist/code-hold.aix
~/tools/bin/aix list ../dist/code-hold.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线（`shot-code.js`，独立页面副本 `preview-code.html`）。

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-code-hold`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 Code Hold 智能体」。
5. 验收点：DICT 复述真实 WiFi 密码（含大小写字母）时宿主识别返回的原文形态与核对屏把关是否顺手；逐位念对门锁码/会议号的准确率；安静与嘈杂环境各测一轮；逐段显示输码时翻段是否跟手、SPEAK 逐字读段是否听得清；最后一段的焚毁提示出现后不操作、码仍在；BURN 一下不删、两下才删且只报一次「已焚」；存满 4 条后第 5 条被拒且不覆盖、不自动焚旧码；重启眼镜后记录仍在（且提醒自己：它们是明文）。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Code Hold（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Hear-a-code-once holder: repeat it in your own voice, confirm character by character, type it elsewhere chunk by chunk from your view, then burn it. Plain-text on device, stated openly. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**

- 静态校验：app.json / package.json / `<script def>` 三处 JSON 解析通过；抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(`/`workers:` 误用。
- Node harness **154 条断言全过**：确认门纪律（未确认听写绝不落盘、OK 之前零存储写入）、原文捕获且大小写保留、重念更正与逐位步进更正都先于保存替换原值（光标移位、单字改、9→0 回绕、含字母码步进拒绝）、逐位解析（前导零保留、严格逐位模式、单位数值式、包装词剥离、垃圾拒绝、单字符按误听拒绝）、麦克风检查先于 ASR 且检查轨道先停（OverconstrainedError 回退有标注、无 ASR 主机如实 SKIP 且步进路径可用）、4 条封顶拒绝且待核对条目保留不覆盖不自动焚、分段数学（7/8/12 字符）、焚毁两步（列表/显示、其他动作解除武装、已焚只报一次）、最后一段只提示永不自动删、SPEAK 分段顺序与逐字拼读、打开显示零朗读、列表 SPEAK 绝不读码本身、点头全场景只等于 SPEAK（核对屏点头永不保存、显示中点头永不焚）、纯键位流程（Enter/方向键走完捕获到逐段）、DEMO 全程真实存储逐字节不变、持久化往返、存档条目恰为 {label, code, time} 三个字符串字段、明文诚实行存在于界面字符串中、TTS 从不设置 lang。
- `aix pack` 成功（约 24 KB），`aix list` 确认 README.md 在包内、artifacts 已排除。
- 预览截图 4 张已生成并逐张目检：EVT 行与底部常驻诚实行均在画面内（点击坐标经帧哈希探针逐状态标定）。

**未验证（如实说明）**

- **明文存储（第一位）**：码在本应用的眼镜本地存储里是明文文字，没有加密——这是平台存储的现实，本 Agent 不粉饰。它意味着：能拿到这台眼镜存储内容的人/程序就能读到这些码。对策只有使用纪律：码只在要输入的那几分钟里存着，输完立即焚；长期密码不要存进来。真机上存储的实际隔离程度（其他应用/调试通道能否读到）未经验证。
- **字母码的识别脆弱性（第一位并列）**：宿主 ASR 对英文字母、大小写、符号（`._-`）的返回形态未经真机验证——中文识别器可能把字母听成单词、丢掉大小写、或把符号吞掉。核对屏是为此设的：识别成什么样就显示什么样，错了一眼可见；但若真机识别对字母码系统性不可用，字母码的实际可用性就只取决于重念运气，数字码（逐位念）不受此影响。
- 真机 DICT 识别率：安静/嘈杂环境下宿主识别器听复述的准确度、中文数字两种读法的实际返回形态（wearer 检查流不参与识别）；头部稳定性事件与点头手势在真机上的投递与误触率（点头在这里最坏只是多读一段，不删东西）。
- 宿主 TTS 逐字拼读英文字符的实际效果（如字母 y 与数字的连读是否清楚）；wx 存储在眼镜重启后的持久性。

## 提审资料 (Review Submission)

### Feature Description（435 字符）

> Code Hold keeps the codes you hear once: a friend's WiFi password, a temporary door code, a meeting number. You repeat it in your own voice, check it character by character, and only then is it held - in plain text on the glasses, stated openly, because no encryption is claimed. When you type it elsewhere it appears in view in chunks of four, silent unless you ask for a spoken chunk. Done typing? Burn it in two taps and it is gone.

### Opening Message（447 字符）

> ## Code Hold
>
> A friend reads out a WiFi password or door code once - and it is gone. **DICT** it back in your own voice (the mic hears you, not them), check every character, tap **OK** to hold it. Codes are held in **plain text** on the glasses - no encryption is claimed, so burn them after use. Open a code to type it: chunk by chunk in view, silent by default; **SPEAK** reads one chunk aloud on demand. Finished? **BURN** twice and it is gone.

### Preview Media

- `preview-code-hold-index.png` — 首页初始态：空列表 + 常驻诚实行（明文存储无加密 · 麦克风只听你复述 · 显示默认不出声）
- `preview-code-hold-demo.png` — DEMO 核对屏：模拟听写 会议号 90214478 分段大字待核对（标注 DEMO，非真实听写）
- `preview-code-hold-list.png` — DEMO 列表：WiFi密码 sunny4829 / 门锁码 0508 / 会议号 90214478 三条（演示内确认后）
- `preview-code-hold-show.png` — 逐段显示：会议号第 1 段 9021 大字 + 全码分段图

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 复述捕获 + 确认门：你用自己的声音复述刚听到的码（佩戴者模式麦克风检查在前、宿主 ASR 在后），听写原文（大小写保留）落核对屏，只有你确认才落盘；重念更正 / 纯数字码逐位步进更正都先于保存
- 逐位念：数字码逐位口述解析（前导零保留），字母/符号靠整段复述 + 核对屏逐字把关；听不成码形如实拒绝，绝不猜
- 明文持有 + 输完即焚：最多 4 条 `{标签, 码, 时间}` 明文存本机（无加密，明说）；存满如实拒绝不覆盖不自动焚；BURN 两步焚毁并朗读一次「已焚」
- 逐段显示、默认静默：码按 4 字符一段在视线内显示，滑动/Enter 翻段；打开不出声，SPEAK 只在主动要求时逐字读当前段，列表里只报段数不读码
- DEMO：2 条种子记录 + 1 条模拟听写走完核对全程，不写真实存储，退出精确恢复

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
