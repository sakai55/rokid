# Step Count Down（下楼倒数）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-step-count-down
```

路缘坡效应系列 CC03（HOLD 倒数型）。低视力或全盲的人下陌生楼梯，最怕的不是「楼梯在哪」，而是「还剩几级」——最后一级踏空是最常见的摔倒点。本 Agent 只替你拿住一个数：在梯口数清总级数，下楼时每下一级你确认一次，它往下倒数；剩 3 级起逐级播报，最后一级单独警告，到底明说「已到底」。它不替你看楼梯，只替你记住还剩几级。

## 预览截图

![预览-初始设置](<../../screenshots/step-count-down/preview-step-count-down-index.png>)
![预览-演示开始](<../../screenshots/step-count-down/preview-step-count-down-demo.png>)
![预览-下楼中](<../../screenshots/step-count-down/preview-step-count-down-counting.png>)
![预览-只剩 3 级](<../../screenshots/step-count-down/preview-step-count-down-low.png>)
![预览-已到底](<../../screenshots/step-count-down/preview-step-count-down-done.png>)

## 解决的问题

下楼梯对视障者是一个倒数问题，不是识别问题：眼睛看不见级数，数错一级就可能踏空。眼镜在这里的价值不是「替你看楼梯」，而是**替你拿住总数、替你倒数**：你只管扶稳、迈步、每级确认一次，剩几级由它报，危险区（剩 3 级起）由它盯。普通人抱箱子、抱娃下楼、双手提满东西时眼睛被挡，同样数不清还剩几级——这就是路缘坡效应的溢出：先为看不见级数的人把「倒数」做扎实，暂时看不见的人顺带受益。

## 路缘坡效应：立项三问

- **① 坡道本体**：低视力/全盲者，下陌生楼梯，通道断的是「剩余级数的计数与到底判定」——拿掉这类人群，本 Agent 立刻不成立：健全人看一眼就知道还剩几级，不需要倒数与到底播报。
- **② 通道改造**：语音是主通道，零屏幕依赖。所有指令、危险区播报、到底宣告都由 TTS 播报；操作只有点头（头稳时 = 下一级）、单击（情境 GO，下楼中 = 下一级）、滑动（调总级数，仅设置阶段）。屏幕只是给有视力帮手和预览看的镜像，流程本身不依赖它；屏幕上的巨大剩余数字与已下/未下色块条是同一信息的视觉版。
- **③ 溢出地图**：普通人在这些情境下会用它：抱箱子下楼、抱娃下楼、双手提重物、夜里楼道灯坏了、穿高跟鞋下楼——都是「暂时看不清级数」的时刻。

## 注意力外包设计（HOLD 倒数型）

- **总数先行，倒数后行**：SETUP 必须先填总级数（>0）才能开始下楼；没填拒绝开始并明说。总级数一旦开始倒数即锁定，防中途误改。
- **COUNT 只数一件事**：`wide` 广角拍整段楼梯 + 主机 LLM，提示词写死为「只回答楼梯级数数字，例如 12；数不清回答 NONE，不要解释」。解析只取第一个 1–2 位数字；数不清、无数字、超范围，一律记为 SKIP，改用步进/口述，绝不猜一个级数出来。
- **绝不自动递减（安全决定）**：每级步幅的头部俯仰变化因步态、拐杖、扶手而异，用俯仰推导级数会悄悄漂移，而漂移的倒数正是让人踏空的原因。所以每级都必须由佩戴者确认（STEP 按钮、头稳点头、情境 GO），俯仰信号根本不读；头稳信号只用来给点头把关。漏确认一次只是可见的差一级，可用 SPEAK 随时核对纠正，绝不会悄悄漂移。
- **危险区分级播报**：剩 3 级起每级播报「还剩 N 级」；最后一级单独警告「最后一级，踩稳再下」；到底明说「已到底，小心站稳」。中途（剩 >3 级）每级不播报——确认动作本身就是确认，SPEAK 随时可听完整状态，避免 TTS 在楼梯上喋喋不休干扰脚步。
- **与慧眼的分工**：慧眼可以描述楼梯，但不替你倒数、不报到底。本 Agent 不做通用场景描述：它不回答「楼梯什么样」，只解决「还剩几级、何时到底」这一个闭环。识别只在 COUNT 一步里出现，且只问总级数。
- **手动备用路径**：相机或 LLM 不可用时，步进（+1/+10/−1、滑动）与 DICT 口述（先做佩戴者麦模式可用性检查，结果单独一行 MIC CHECK，再走宿主 ASR；支持阿拉伯数字与中文数字，解析不了如实拒绝、绝不猜）填入总级数，走同一套倒数逻辑。备用路径不是第二套标准。
- **零持久化**：不调用任何存储 API；总级数与倒数只活在页面内存里，关页即忘，一段楼梯一轮。

## 功能流程

1. **SETUP**：COUNT 拍照数总级数，或步进 +1/+10/−1、滑动、DICT 口述填总级数。GO 开始下楼（总级数未填拒绝）。
2. **COUNTING**：每下一级点 STEP（或头稳点头、或 GO）；剩 3 级起逐级播报；最后一级警告；到底宣告并进入 DONE。
3. **收尾**：DONE 后 GO 开始新的一段（重新数总级数）。

## 手势映射

主流程只用滑动 + 单击 + 点头即可全程完成，不依赖盯屏点按钮：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO：SETUP 时开始下楼；下楼中 = 下一级；DONE 时 = 新的一段 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 总级数 +1 / −1（仅设置阶段，下楼开始后锁定） |
| 点头（头稳时） | `onHeadGesture('nod')` | 下楼中 = 下一级；其他阶段 = 只朗读，绝不开始/结束 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由）：

| 按钮 | 理由 |
|---|---|
| +1 / −1 | 滑动的镜像，精确修正一位 |
| +10 | 大跨度赶步（级数两位数时连按滑动太慢） |
| COUNT | 拍照数总级数（点头/滑动做不了的事） |
| DICT | 口述总级数（双手扶扶手、不想连按时的快速路径，先 MIC CHECK 再 host ASR） |
| STEP | 下一级（点头的镜像，头不方便动时用） |
| GO ✓ | Enter 的镜像（情境主操作） |
| SPEAK | 随时听倒数状态（点头的镜像） |
| DEMO | 演示：总级数 12 级 → 下楼中 → 剩 9 级 → 剩 3 级（警告区）→ 最后一级 → 已到底；退出后真实状态原样恢复 |

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | COUNT 拍整段楼梯（`wide` 广角）；拍不到或 LLM 不可用时如实 SKIP，改用步进/口述 |
| `RECORD_AUDIO` | 佩戴者口述总级数（DICT）；口述前先做 getUserMedia 佩戴者模式可用性检查。Agent 不录环境音 |

只申请 2 项。麦克风模式只作用于 getUserMedia 流，永不影响宿主 `SpeechRecognition`；聆听状态标注为 (host ASR)。TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明该属性不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/step-count-down
~/tools/bin/aix pack . -o ../dist/step-count-down.aix
~/tools/bin/aix list ../dist/step-count-down.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-step-count-down`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 Step Count Down 智能体」。
5. 验收点：真实楼梯走完一轮（梯口 COUNT 或口述填总级数 → 逐级 STEP/点头倒数 → 剩 3 级起逐级播报 → 最后一级警告 → 到底宣告）；故意漏确认一级，确认倒数只差一级且 SPEAK 可核对；故意把镜头对偏一次，确认如实 SKIP 且可改用步进/口述；DICT 口述中文级数（如「十二」）能填入且可核对；扶扶手下楼时确认点头只在头稳时触发。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Step Count Down（待导入后回填） |
| Version / Build | 1.0.1 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Stair countdown: count the total steps at the top, count down one wearer-confirmed step at a time, speak from 3 remaining down, warn on the last step, announce the bottom. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限与实际使用一致（CAMERA 只在 COUNT 路径，RECORD_AUDIO 为 DICT 语音通道）；CSS 无纯白与白色 rgba（只用绿色色阶）。
- `aix pack` 成功（约 16.3 KB），`aix list` 确认 artifacts 已排除、包内为源文件。
- 预览截图 5 张已生成并逐张目检：初始设置、演示开始（总级数 12 级）、下楼中、只剩 3 级（警告区）、已到底各状态均与设计一致；DEMO 点击坐标经探针标定。

**未验证（如实说明）**
- 宿主 TTS 实际发声、头部手势/稳定性事件在真机上的投递、`wide` 拍照与 LLM 数级数的真机表现（长楼梯、转角楼梯、光线差、级数多）均待真机验证；COUNT 在任何一步缺失时如实 SKIP，手动备用路径始终可用。
- 本 Agent 只报剩余级数与到底，不判断楼梯是否湿滑、有无扶手、有无障碍物；下楼时仍需扶稳、注意脚下，本 Agent 不替代任何安全判断。
- 本 Agent 是生活辅助，不替代任何医疗或康复判断；视障用户在楼梯上使用时仍需注意脚下与扶手安全。

## 提审资料 (Review Submission)

### Feature Description

> Stair countdown for blind and low-vision wearers. At the top of an unfamiliar flight, count the total steps — a photo plus the host language model counts them, or enter the number by stepper or voice. Walking down, confirm each step you take with a tap or a steady nod and the agent counts down: it speaks every remaining step from 3 down, warns on the last step, and announces the bottom plainly. The count is never advanced automatically, so it can never silently drift.

### Opening Message

> ## Step Count Down
>
> Unfamiliar stairs, and the scary part is never knowing **how many steps are left**? Count the total at the top, then walk down: confirm each step with a tap or a nod, and I'll count down — speaking every step from **3 remaining**, warning on the **last step**, and announcing **the bottom**.
>
> *One number held for you. Never auto-advanced, never guessed.*

### Preview Media

- `preview-step-count-down-index.png` — 初始设置（总级数未填）
- `preview-step-count-down-demo.png` — 演示开始（总级数 12 级已选）
- `preview-step-count-down-counting.png` — 下楼中（共 12 级）
- `preview-step-count-down-low.png` — 只剩 3 级（警告区）
- `preview-step-count-down-done.png` — 已到底

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 总级数登记（拍照 COUNT + 步进 + 口述三路径，口述支持中文数字，先 MIC CHECK 再 host ASR）+ 开始前总级数必填诚实校验
- 佩戴者确认式倒数（STEP/头稳点头/情境 GO，绝不自动递减）+ 剩 3 级起逐级播报 + 最后一级警告 + 到底宣告
- 危险区分级播报与中途静默规则（剩 >3 级不逐级播报，SPEAK 随时核对）+ 纯手势主流程（滑动调级数、单击情境主操作、点头 = 下一级）+ DEMO 全程演示（12 级 → 剩 9 级 → 剩 3 级 → 最后一级 → 已到底）

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）

### Change Log（Build 1.0.1）

**Features added**

- 无

**Improvements**

- 无

**Fixes**

- 删除 FileReader（Ink 运行时不存在，真机必死）：照片 Blob→dataURL 改走官方文档路径 `blob.arrayBuffer()` + 分块 `btoa`，失败接全局错误码 E2005 并如实提示。
