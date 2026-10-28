# Color Order Check（线序核对）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-color-order-check
```

路缘坡效应系列 CC04（COVER 核对型）。红绿色弱的人接线、查线序时，问题不是看不见线，而是**颜色编码读不准**：电阻色环、网线线序、电线颜色排错了，轻则返工，重则出故障。本 Agent 只做一件事：先逐根登记颜色名，排成一张顺序表；再逐根重拍核对，错位立刻停住，明说第几根不对、登记是什么色、现在是什么色。它绝不用颜色本身来告诉你颜色——因为用断了的通道纠错，等于没纠。

## 预览截图

![预览-初始登记](<../../screenshots/color-order-check/preview-color-order-check-index.png>)
![预览-演示登记](<../../screenshots/color-order-check/preview-color-order-check-demo.png>)
![预览-复查中](<../../screenshots/color-order-check/preview-color-order-check-verify.png>)
![预览-第 2 根不对](<../../screenshots/color-order-check/preview-color-order-check-mismatch.png>)
![预览-全部对上](<../../screenshots/color-order-check/preview-color-order-check-done.png>)

## 解决的问题

查线序对色弱者是一个顺序核对问题，不是识别问题：单根颜色也许能蒙对，整排顺序一错就全错。眼镜在这里的价值不是「替你看颜色」，而是**替你拿住顺序表、替你逐根比对**：你只管逐根看向线材、拍照或手动登记，登记与复查的比对交给它，错位时它停住并报出三个事实——第几根、登记色、现在色。普通人在昏暗光线下接线、给孩子分药分线、新手第一次排线序时，色觉同样下降——这就是路缘坡效应的溢出：先为色觉读不准的人把「名字核对」做扎实，暂时色觉下降的人顺带受益。

## 路缘坡效应：立项三问

- **① 坡道本体**：红绿色弱/色盲者，电线、电阻色环、网线线序靠颜色排序，通道断的是「颜色编码的可靠读取与顺序比对」——拿掉这类人群，本 Agent 立刻不成立：色觉正常的人看一眼就能排对顺序，不需要逐根登记与复查。
- **② 通道改造**：输出通道彻底换掉：一切结果都用**文字与语音报色名**，绝不只用颜色本身提示（屏幕上也没有纯色块，只有带编号的颜色名）。输入靠看向线材 + 拍照，确认靠点头/单击，不依赖分辨颜色的能力。语音是主通道，所有结论都由 TTS 播报一次。
- **③ 溢出地图**：普通人在这些情境下会用它：昏暗灯光下接线、新手电工第一次排线、手工分线、给孩子分药片颜色、老人分药——都是「暂时色觉不可靠」的时刻。

## 注意力外包设计（COVER 核对型）

- **登记先行，复查后行**：REGISTER 必须先登记至少 2 根才能开始复查；不足 2 根拒绝开始并明说。复查开始后顺序表锁定，CLEAR 是唯一的重开路径。
- **CHECK 只问一件事**：`telephoto` 长焦拍单根线 + 主机 LLM，提示词写死为「只回答颜色名，例如红色、绿色、黄色；看不清回答 NONE，不要解释」。答案按 11 色固定调色板归一化（子串匹配，「红色」→ 红）；调色板之外、看不清、无答案，一律记为 SKIP，改用手动登记，绝不猜一个颜色出来。
- **错位停住，不跳过**：复查中某根不对，停在该位置并播报「第 N 根不对，登记是 X 色，现在是 Y 色」，直到重拍 CHECK 纠正；SKIP 只能主动跳过，且记为跳过、不算对上。DONE 汇总分开报「对上 N 根，跳过 M 根」，跳过的线永远冒充不了查过的线。
- **手动路径同口径**：相机或 LLM 不可用时，COLOR 换手动色、ADD 登记、DEL 删末位，走同一套登记 → 复查 → 错位停住逻辑。备用路径不是第二套标准。
- **与慧眼的分工**：慧眼通用识色是答一句「这是什么颜色」。本 Agent 不做通用识色：它做的是**顺序核对表闭环**——登记、锁定、逐根复查、错位停住、汇总，识别只在 CHECK 一步里出现，且只问单根颜色名。
- **零持久化**：不调用任何存储 API；顺序表与复查进度只活在页面内存里，关页即忘，一组线一轮。

## 功能流程

1. **REGISTER**：逐根看向线材点 CHECK 拍照登记颜色名，或 COLOR 换手动色 + ADD 登记、DEL 删末位。登记至少 2 根。
2. **VERIFY**：GO 开始复查，从第 1 根起逐根重拍 CHECK：对了自动进下一根；不对停住并报三事实，纠正后重拍；拍不了可 SKIP（记为跳过）。
3. **收尾**：全部位置走完进入 DONE，汇总对上/跳过根数；GO 开始新的一组，CLEAR 随时清空重来。

## 手势映射

主流程只用滑动 + 单击 + 点头即可全程完成，不依赖盯屏点按钮：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO：登记时开始复查；复查中 = CHECK 重拍；DONE 时 = 新的一组 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 手动色下一个 / 上一个（登记阶段） |
| 点头（头稳时） | `onHeadGesture('nod')` | 登记或复查中 = CHECK 拍照；DONE 时 = 只朗读，绝不开始/结束 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由）：

| 按钮 | 理由 |
|---|---|
| COLOR | 换手动色（滑动的镜像，手动登记时的选色器） |
| ADD | 手动登记当前手动色（拍照路径不可用时的登记路径） |
| DEL | 删末位（登错一根时的纠正） |
| CHECK | 拍照识色（点头的镜像，头不方便动时用） |
| SPEAK | 随时听顺序表/复查状态（点头的镜像） |
| SKIP | 跳过当前复查位置（记为跳过，不算对上） |
| GO ✓ | Enter 的镜像（情境主操作） |
| CLEAR | 清空全部重来（登记错乱时的唯一重开路径） |
| DEMO | 演示：登记红黄绿 → 复查第 1 根对了 → 第 2 根不对（登记黄、现在蓝）→ 纠正 → 第 3 根对了 → 全部对上；退出后真实状态原样恢复 |

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | CHECK 拍单根线（`telephoto` 长焦）；拍不到或 LLM 不可用时如实 SKIP，改用 COLOR + ADD 手动路径 |

只申请 1 项。本 Agent 不录音、不口述，TTS 输出不需要权限。麦克风模式不适用。

## 打包与预览

```bash
cd ~/workspace/rokid/color-order-check
~/tools/bin/aix pack . -o ../dist/color-order-check.aix
~/tools/bin/aix list ../dist/color-order-check.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-color-order-check`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 Color Order Check 智能体」。
5. 验收点：真实线材走完一轮（逐根 CHECK 登记 → GO 复查 → 故意换一根颜色确认停住并报三事实 → 纠正后继续 → DONE 汇总）；故意把镜头对偏/遮挡一次，确认如实 SKIP 且可改用手动路径；光线差时确认 LLM 认色失败如实 SKIP、不猜；DEMO 全程与设计一致。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Color Order Check（待导入后回填） |
| Version / Build | 1.0.1 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Wire colour-sequence checker: register each wire's colour name in order, re-photograph in the same order, stop on any mismatch with position, registered colour and observed colour. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限与实际使用一致（CAMERA 只在 CHECK 路径）；CSS 无纯白与白色 rgba（只用绿色色阶）。
- `aix pack` 成功（约 14.8 KB），`aix list` 确认 artifacts 已排除、包内为源文件。
- 预览截图 5 张已生成并逐张目检：初始登记、演示登记（红黄绿）、复查中、第 2 根不对（登记黄、现在蓝）、全部对上各状态均与设计一致；DEMO 点击坐标经探针标定。

**未验证（如实说明）**
- 宿主 TTS 实际发声、头部手势/稳定性事件在真机上的投递、`telephoto` 拍照与 LLM 认色的真机表现（细线、反光、昏暗、相近色如橙/红、棕/黑）均待真机验证；CHECK 在任何一步缺失时如实 SKIP，手动备用路径始终可用。
- 本 Agent 只核对颜色顺序，不判断线材通断、电压、接线工艺是否正确；接线作业仍需按电气安全规范操作，本 Agent 不替代任何专业判断。
- 本 Agent 是生活辅助，不替代任何医疗判断；色弱只是色觉差异，不是疾病诊断对象。

## 提审资料 (Review Submission)

### Feature Description

> Wire colour-sequence checker for people who cannot reliably read colour codes. Look at each wire in turn and photograph it: the agent registers its colour name in order. Then re-photograph the wires in the same order and it compares: a match advances, a mismatch stops and says exactly which position is wrong, what was registered, and what is there now. Colours are always reported by name in speech and text, never by colour alone, and an unrecognised colour is reported, never guessed.

### Opening Message

> ## Color Order Check
>
> Wiring by colour, but colour codes don't read reliably? Register each wire's colour **by name, in order** — then re-check them one by one. A match advances; a mismatch stops and tells you **which wire, what was registered, and what is there now**.
>
> *Names, not colours. A mismatch stops the run; a skip is never counted as a pass.*

### Preview Media

- `preview-color-order-check-index.png` — 初始登记（顺序表为空）
- `preview-color-order-check-demo.png` — 演示登记（红黄绿）
- `preview-color-order-check-verify.png` — 复查中（第 1 根已对上）
- `preview-color-order-check-mismatch.png` — 第 2 根不对（登记黄、现在蓝）
- `preview-color-order-check-done.png` — 全部对上

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 顺序表登记（拍照 CHECK + COLOR/ADD/DEL 手动路径，拍照答案按 11 色调色板归一化，认不出如实 SKIP）+ 复查前至少 2 根诚实校验
- 逐根复查（对了进下一根、不对停住报三事实、SKIP 记为跳过不算对上、DONE 分开汇总）+ 纯手势主流程（滑动换手动色、单击情境主操作、点头 = CHECK）+ DEMO 全程演示（红黄绿 → 第 1 根对 → 第 2 根不对 → 纠正 → 第 3 根对 → 全部对上）

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

- 删除 FileReader（Ink 运行时不存在，真机必死）：照片 Blob→dataURL 改走官方文档路径 `blob.arrayBuffer()` + 分块 `btoa`，失败接全局错误码 E2005 并如实走 PHOTO SKIP 提示。
