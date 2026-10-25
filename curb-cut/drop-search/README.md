# Drop Search（掉落物分区搜索）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-drop-search
```

路缘坡效应系列 K01（COVER 覆盖型）。全盲或低视力的人掉了一件小物——钥匙、耳机、药片、硬币——最难的不是弯腰，而是**不知道自己已经摸过哪块地、哪块还没摸**：同一块地摸两遍，另一块漏掉，最后放弃时也不确定东西到底还在不在这附近。本 Agent 把「覆盖图」外包给眼镜：脚边地面切成 6 个区，一次只说一个区，查过打勾，没查过的一目了然；6 区全查完才如实说没找到，找到了只在你自己确认或照片确实提示时才报。

## 预览截图

![预览-初始设置](<../../screenshots/drop-search/preview-drop-search-index.png>)
![预览-演示开始](<../../screenshots/drop-search/preview-drop-search-demo.png>)
![预览-分区搜索中](<../../screenshots/drop-search/preview-drop-search-sweep.png>)
![预览-找到了](<../../screenshots/drop-search/preview-drop-search-found.png>)
![预览-全查完没找到](<../../screenshots/drop-search/preview-drop-search-notfound.png>)

## 解决的问题

掉落物搜索对视障者是一个记忆问题，不是视力问题：手能摸到的范围一次只有一小块，摸过的顺序全靠脑子记，紧张时顺序一乱，覆盖图就碎了。眼镜在这里的价值不是「替你看」，而是**替你记覆盖图**：你只管按语音指令转头、低头、摸地，哪个区查过、哪个区没查、还剩几个区，全由它拿着。普通人掉耳钉、螺丝、隐形眼镜盖时同样会陷入「这块摸过没有」的循环——这就是路缘坡效应的溢出：先为看不见的人把覆盖图做扎实，暂时看不见小物的人顺带受益。

## 路缘坡效应：立项三问

- **① 坡道本体**：全盲/低视力者，掉落物在脚边地面，通道断的是「覆盖记忆」——拿掉这类人群，本 Agent 立刻不成立：健全人低头看一眼就能完成搜索，不需要 6 区覆盖图。
- **② 通道改造**：语音是主通道，零屏幕依赖。所有指令、进度、结果都由 TTS 播报一次；操作只有点头（头稳时 = 本区查完）、单击（情境 GO）、滑动（换区）。屏幕只是给有视力帮手和预览看的镜像，流程本身不依赖它。
- **③ 溢出地图**：普通人在这些情境下会用它：掉耳钉/螺丝找不着、夜里停电摸黑找东西、抱着东西低头不便时找掉落物——都是「暂时看不见小物」的时刻。

## 注意力外包设计（COVER 覆盖型）

- **6 区覆盖图，查过就是查过**：正前方 / 左前方 / 右前方 / 左侧 / 右侧 / 身后。每个区只接受两种状态：未查、已查。CHECK（或头稳点头）把当前区标为已查并自动跳到下一个未查区；NEXT/PREV 只换区、不改状态。屏幕常驻一行区号标记（如 `1✓ 2✓ 3· 4· 5· 6·`），语音随时可报「已查几区、还剩几区」。
- **FOUND 只有两个诚实来源**：(1) 佩戴者自己点 FOUND 确认；(2) 可选的 PHOTO 路径（`wide` 拍照 + 主机 LLM）确实在本区照片里报出该物品。PHOTO 报「有」仍标注为「请用手确认」的提示，最终以手摸为准；照片没拍到、LLM 不可用、LLM 说没有，一律记为 SKIP / 不是找到，本区仍按手摸流程走。
- **NOT FOUND 是挣来的结论**：只有 6 区全查完才触发，语音与界面都明说「6 区全查完，没找到」，并补充「可能掉在别处，或者滚出去了」——不假装东西一定在脚边，也不把「没查完」说成「没找到」。
- **与慧眼的分工**：慧眼是通用「看图识物/读字」——问一句、答一句。本 Agent 不做通用场景描述：它不回答「前面有什么」，只解决「脚边 6 区查完没有」这一个闭环。识别只在 PHOTO 一步里出现，且只问「这张地面照片里有没有这件物品」，答「有/没有」二选一。
- **零持久化**：不调用任何存储 API；区图只活在页面内存里，关页即忘。每一次搜索都是全新的一轮——这正是设计：覆盖图只对「这次掉落」有意义。

## 功能流程

1. **SETUP**：ITEM 切换丢了什么（钥匙 / 耳机 / 药片 / 硬币 / 其他小物），GO 开始搜索。
2. **SWEEP**：语音一次只说一个区（「第 2 区，左前方。头转向左前方，低头，用手慢慢摸左前方地面」）。摸完点 CHECK（或头稳点头）= 本区查完，自动进下一个未查区；NEXT/PREV 换区；FOUND = 找到了；PHOTO = 可选拍照辅助；SPEAK = 再听一遍进度与当前区指令。
3. **收尾**：FOUND 后语音报区位（「在第 3 区，右前方，慢慢拿」）；NOT FOUND 后语音与界面明说 6 区全查完没找到；两种收尾后 GO 都开始新的一轮。

## 手势映射

主流程只用滑动 + 单击 + 点头即可全程完成，不依赖盯屏点按钮：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO：SETUP 时开始搜索；SWEEP 时朗读进度；FOUND/NOT FOUND 时开始新的一轮 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 下一区 / 上一区（只换区，不改查过状态） |
| 点头（头稳时） | `onHeadGesture('nod')` | CHECK 当前区（= 本区摸完），绝不单独构成 FOUND |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由）：

| 按钮 | 理由 |
|---|---|
| ITEM | 切换丢了什么（搜索开始后锁定，防中途改目标打乱覆盖图） |
| PREV / NEXT | 换区的按钮镜像（滑动的镜像，头不方便动时用） |
| CHECK | 本区摸完（点头的镜像） |
| FOUND | 佩戴者自己确认找到了（唯一的人工 FOUND 来源） |
| PHOTO | 可选拍照 + LLM 辅助（从不代替手摸，失败即 SKIP） |
| GO ✓ | Enter 的镜像（情境主操作） |
| SPEAK | 随时听进度与当前区指令（语音主通道的按钮镜像） |
| DEMO | 演示：钥匙 → 第 1、2 区查完为空 → 第 3 区找到；再一轮 6 区全查完没找到；退出后真实状态原样恢复 |

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | 仅用于可选的 PHOTO 检查（`wide` 拍照 + LLM 看图）；核心分区搜索完全不需要相机，PHOTO 失败即 SKIP |
| `RECORD_AUDIO` | 语音主通道的声明；v1.0.0 不做口述录入、不录音、不存音频 |

只申请 2 项。TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明该属性不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/drop-search
~/tools/bin/aix pack . -o ../dist/drop-search.aix
~/tools/bin/aix list ../dist/drop-search.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-drop-search`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 Drop Search 智能体」。
5. 验收点：闭眼（或请有视力者蒙眼协助）走完一轮——只听语音指令能否不看屏完成 6 区搜索；故意在第 3 区找到，确认 FOUND 只报第 3 区且不改其他区状态；故意 6 区全查完没找到，确认 NOT FOUND 只在全查完后出现；PHOTO 在无相机/无 LLM 时如实 SKIP 且不影响手摸流程；关页重开后确认区图已清零（设计如此）。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Drop Search（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Floor-sector coverage search for dropped small items: 6 spoken sectors, checked map, honest found/not-found. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限与实际使用一致（CAMERA 只在 PHOTO 路径，RECORD_AUDIO 为语音通道声明）。
- `aix pack` 成功（约 15.8 KB），`aix list` 确认 artifacts 已排除、包内为 6 个源文件。
- 预览截图 5 张已生成并逐张目检：初始设置、演示开始、分区搜索中、找到了（第 3 区右前方，区标记 1✓ 2✓）、全查完没找到（6/6）各状态均与设计一致；DEMO 点击坐标经探针标定（400, 250）。

**未验证（如实说明）**
- 宿主 TTS 实际发声、头部手势/稳定性事件在真机上的投递、相机 `wide` 拍照与 LLM 看图的真机表现，均待真机验证；PHOTO 在任何一步缺失时如实 SKIP，核心手摸流程不受影响。
- 搜索只覆盖脚边 6 区；物品滚出该范围、掉在家具下/缝隙里时，本 Agent 只会如实报「6 区查完没找到」，不声称能找到全屋物品。
- 本 Agent 是生活辅助，不替代任何医疗或康复判断；视障用户在真实环境中使用时仍需注意脚下安全。

## 提审资料 (Review Submission)

### Feature Description

> Floor-sector search for blind and low-vision wearers who dropped a small item. Pick the item, then follow one spoken sector at a time around your feet: front, front-left, front-right, left, right, behind. Each sector you sweep by hand is checked off; the agent holds the coverage map so you never re-sweep or skip a patch. It says FOUND only when you confirm or an optional photo check reports the item, and says NOT FOUND only after all 6 sectors are swept.

### Opening Message

> ## Drop Search
>
> Dropped your keys, earphone, or a pill? Don't guess which patches of floor you've already swept. Pick the item, then I'll walk you through 6 sectors around your feet — one spoken instruction at a time. Sweep each patch by hand, check it off, and I'll hold the map. Found it, and I'll tell you exactly which sector. All 6 swept and nothing there, and I'll say so plainly.
>
> *Voice first — no screen needed. The optional photo check never replaces your hand.*

### Preview Media

- `preview-drop-search-index.png` — 初始设置（选丢了什么，6 区待查）
- `preview-drop-search-demo.png` — 演示开始（钥匙已选）
- `preview-drop-search-sweep.png` — 分区搜索中（第 1 区正前方）
- `preview-drop-search-found.png` — 找到了（第 3 区右前方，1✓ 2✓）
- `preview-drop-search-notfound.png` — 全查完没找到（6/6）

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 6 区脚边覆盖图（正前方/左前方/右前方/左侧/右侧/身后），一次只说一个区，查过打勾、未查一目了然
- 语音主通道：全部指令、进度、结果由 TTS 播报，零屏幕依赖；点头（头稳时）= CHECK、滑动换区、单击情境 GO
- FOUND 双诚实来源：佩戴者确认 + 可选 PHOTO（wide 拍照 + LLM），PHOTO 报有仍标注「请用手确认」，任何一步缺失即 SKIP
- NOT FOUND 只在 6 区全查完后触发，明说没找到并补充可能滚出范围
- DEMO 双弧线演示（找到 / 全查完没找到），退出后真实状态原样恢复

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
