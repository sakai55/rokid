# Curb Ramp Scout（路缘坡侦察）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-curb-ramp-scout
```

路缘坡效应系列 CC08（WATCH 守望型）——本系列的字面原点。轮椅使用者到陌生路口最怕的一刻：路缘坡常常不在正对面而在侧面，推到马路牙子前才发现是台阶，只能退回车流里找坡。本 Agent 把「发现」挪到「推过去」之前：到路口先定向、转头扫两侧、逐向拍照核查是坡还是台阶，最后横幅直接告诉你坡在哪边——双手全程不离轮子。

## 预览截图

![预览-初始](<../../screenshots/curb-ramp-scout/preview-curb-ramp-scout-index.png>)
![预览-扫描中](<../../screenshots/curb-ramp-scout/preview-curb-ramp-scout-scanning.png>)
![预览-结论坡在左](<../../screenshots/curb-ramp-scout/preview-curb-ramp-scout-verdict.png>)
![预览-已清除](<../../screenshots/curb-ramp-scout/preview-curb-ramp-scout-cleared.png>)

## 解决的问题

轮椅者的路口困境不是「不知道路怎么走」，而是「最后 10 米的信息在推过去之前拿不到」：地图导航能把你带到路口，但管不了这个路口的坡在左还是在右；到了牙子前才发现是台阶，退回去找坡的那段路恰恰是最危险的。眼镜在这里的价值是**在安全距离外先看清三向**：面向马路校准前方，转头扫左扫右，每向拍照核查，结论一次给清。普通人推婴儿车、拉行李箱、推购物车、骑行推车上人行道时，遇到的是同一个问题——维基原文的溢出人群本体：先为轮椅者把「不过牙子先知坡向」做扎实，暂时推着东西的人顺带受益。

## 路缘坡效应：立项三问

- **① 坡道本体**：轮椅使用者，在陌生路口，通道断的是「坡向的提前感知」——拿掉这类人群，本 Agent 立刻不成立：能站起来走台阶的人不需要先知道坡在哪边。
- **② 通道改造**：输入通道换成头部朝向 + 远摄核查：定向校准前方（AbsoluteOrientationSensor 相对偏航角）、转头扫向、telephoto 拍照 + LLM 只答坡道/台阶/看不清；输出通道是结论横幅（坡在左/右、三向都不是坡、还没查完），全程语音可听、双手不离轮子。
- **③ 溢出地图**：普通人在这些情境下会用它：推婴儿车过路口、拉行李箱上人行道、推购物车进商场、骑行者推车过街——都是「推着东西，退回去找坡最狼狈」的时刻。

## 注意力外包设计（WATCH 守望型）

- **先定向，后扫向**：定向把「面向马路」定为基准 0°；左扫/右扫记录转头后的相对偏航角（有传感器时显示角度，无传感器时明标「佩戴者自报」，绝不把自报包装成测量）。
- **每向只认拍照结论**：CHECK 用 telephoto + LLM，只答坡道/台阶/看不清三者之一；没拍照核查过的向永远是未核，不从另一向推断、不手动补猜——路口没有「大概是坡」的安全余地。
- **看不清就是结论**：看不清不藏起来，它本身就是一种核查结果：该向读不出来，结论会明说缺哪向，让佩戴者换个角度再核或换个路口。
- **结论三种出口，绝不含糊**：有坡 → 「坡在 X — 朝 X 走」；三向都核过且无坡 → 「三向都不是坡 — 换个路口」；没查完 → 明说缺哪向，先补核再结论。
- **点头只给结论，绝不扫向/拍照**：路口一次误扫就会污染朝向集，所以头稳点头只触发结论；扫向与拍照只能用明确的按钮/滑动操作。
- **与慧眼和已有导航类的分工**：慧眼导航走地图路线，管不了路口这最后 10 米哪侧有坡；已有导航类 Agent 均无「三向坡面核查」任务；本 Agent 不做路线规划，只做路口三向核查。

## 功能流程

1. **IDLE**：面向马路，点定向校准前方（有传感器时以前方偏航角为基准，无传感器时以佩戴者自报为准并明标）。
2. **SCANNING**：转头点左扫/右扫记录朝向；对准该向点 CHECK 拍照核查（telephoto + LLM，只答坡道/台阶/看不清），结果按向存好。
3. **VERDICT**：点结论，横幅定格三种出口之一；复位可回到扫描补核未核方向。
4. **收尾**：清除回 IDLE，到下一个路口重新定向。

## 手势映射

主流程只用滑动 + 单击 + 点头即可全程完成，不依赖盯屏点按钮：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 定向（校准前方） |
| 上滑 | ArrowUp | 左扫（记录左向） |
| 下滑 | ArrowDown | 右扫（记录右向） |
| 点头（头稳时） | `onHeadGesture('nod')` | 只给结论，绝不扫向、绝不拍照 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由）：

| 按钮 | 理由 |
|---|---|
| 左扫 | 记录左向（转头后点） |
| 右扫 | 记录右向（转头后点） |
| CHECK | 拍照核查当前选向（telephoto + LLM，只答坡道/台阶/看不清） |
| SPEAK | 朗读当前结论/进度 |
| HELP | 语音说明用法 |
| 清除 | 回 IDLE，去下一个路口 |
| 定向 | 校准前方基准（Enter 的镜像） |
| 结论 | 定格三种出口之一（点头的镜像） |
| DEMO | 演示：扫描态（左坡道 · 正前方台阶 · 右未核）→ 结论（坡在左）→ 清除；退出后真实状态原样恢复 |

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | telephoto 拍照核查每向路缘（坡道/台阶/看不清） |

只申请 1 项。本 Agent 不用麦克风（找坡是看，不是听）。TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明该属性不生效）；朝向传感器不需要权限。

## 打包与预览

```bash
cd ~/workspace/rokid/curb-ramp-scout
~/tools/bin/aix pack . -o ../dist/curb-ramp-scout.aix
~/tools/bin/aix list ../dist/curb-ramp-scout.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-curb-ramp-scout`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 Curb Ramp Scout 智能体」。
5. 验收点：到真实路口走完一轮（面向马路定向 → 转头左扫/右扫 → 每向 CHECK 拍照核查 → 结论坡向与实际坡向一致）；故意对准台阶核查，确认结论不把台阶报成坡；遮挡镜头/弱光时确认该向显示看不清或保持未核、结论明说缺哪向；点头只给结论、不扫向不拍照；清除后三向全部归零。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Curb Ramp Scout（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Curb-ramp scout for wheelchair users: calibrate facing at a crossing, scan left and right by head turn, verify each side with a telephoto photo (ramp or steps only), and report which side the ramp is on — hands never leave the wheels. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限与实际使用一致（CAMERA 只在 CHECK 拍照路径）；CSS 无纯白与白色 rgba（只用绿色色阶）。
- `aix pack` 成功（8.31 KB），`aix list` 确认包内为源文件。
- 预览截图 4 张已生成并逐张目检：初始、扫描态（左坡道 · 正前方台阶 · 右未核）、结论（坡在左 — 朝左走）、已清除各状态均与设计一致；DEMO 点击坐标经探针标定（画布 400, 280）。

**未验证（如实说明）**
- 宿主 AbsoluteOrientationSensor 在真机上的偏航角读数与实际转头方向的对应关系、telephoto 在路口距离上的坡面成像质量、LLM 对坡道/台阶的二分判断在真实路缘（斜坡 vs 低台阶、破损坡面）上的准确率、头部手势/稳定性事件在真机上的投递均待真机验证；任何一步缺失时如实提示（未核/看不清），绝不猜坡向。
- 本 Agent 不做路线规划、不判断路口交通安全；过街时机与安全仍由佩戴者现场判断，结论只是坡向信息，不是通行许可。

## 提审资料 (Review Submission)

### Feature Description

> Curb-ramp scout for wheelchair users. At an unfamiliar crossing, the ramp is usually off to one side — and discovering steps at the kerb means backing into traffic to look. This agent finds the ramp before you roll: face the road to calibrate, turn your head to scan left and right, photograph each side (telephoto plus on-device vision, answering only ramp or steps), and get one clear verdict — which side the ramp is on. Your hands never leave the wheels, and a side that was never photographed stays honestly unexamined, never guessed.

### Opening Message

> ## Curb Ramp Scout
>
> Don't roll up to the kerb to find out it's steps. At the crossing, face the road, **calibrate**, turn your head to **scan left and right**, and let me photograph each side. One verdict tells you **which side the ramp is on** — before you move.
>
> *Hands never leave the wheels. A side I never photographed stays unexamined — I never guess a ramp.*

### Preview Media

- `preview-curb-ramp-scout-index.png` — 初始（未校准）
- `preview-curb-ramp-scout-scanning.png` — 扫描态（左坡道 · 正前方台阶 · 右未核）
- `preview-curb-ramp-scout-verdict.png` — 结论（坡在左 — 朝左走）
- `preview-curb-ramp-scout-cleared.png` — 已清除

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 定向校准（AbsoluteOrientationSensor 相对偏航角，无传感器时明标佩戴者自报）+ 左扫/右扫转头采样 + CHECK 逐向拍照核查（telephoto + LLM，只答坡道/台阶/看不清）+ 结论三种出口（有坡 / 三向无坡 / 未查完明说缺向）+ 复位补核 + 清除回 IDLE
- 头稳点头只给结论（绝不扫向/拍照）+ HELP 用法语音 + DEMO 全程演示（扫描态 → 结论坡在左 → 清除）

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
