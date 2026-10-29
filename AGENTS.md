# Trace Probe Seals — Agent Notes

描红系列识别探针（不占 TR 编号、不上根清单、不挂徽章）。壳版本：描红壳 v1（ModelView / StepRail / PhotoJudge / Progress 四部件的探针形态）。

## Design contract

- 目的只有一个：测 LLM 定格拍照认十二基本印（子丑寅卯辰巳午未申酉戌亥）的命中率，探针结果决定 TR02 结印描红正式版的收录范围（认对进计分、认错只进不计分练习、看不清复测后不收、全集认对不足一半则正式版降级自评描红）。
- 说明页：摆位（双手举到眼前 30–40cm、素背景、匀光）、佩戴者视角声明、进度续测。
- 轮测页：每印连续 3 帧范本（①起手 ②交指中段 ③成印定格），中央大图逐帧推进 + 下方缩略帧带；范本是 Canvas 自绘的佩戴者视角线条示意图，手指配置以每印要点文字为准（示意画法已在 UI 与 README 标注）。摆到定格帧后点头（或选「拍照判定」）拍照；判定只对定格帧，不是连续追踪。
- 判定：拍照 → 缩图（失败回退原图并标注）→ `arrayBuffer` + 分块 `btoa` 转 data URL → `LanguageModel` 图片输入，固定三行输出（GUESS / MATCH / FINGER），认不出写 NONE、看不清写 UNSURE，不编造。
- 真值：判定后由佩戴者点「判定对 / 判定错」定对错（真值不由 LLM 定），记录落盘 `trace.probe.seals.v1`；结果页逐项表 + 汇总认对数，回传 = 口述汇总数。
- 手势映射：点头 = 拍照判定（轮测页）/ 执行焦点（其余页）；单指点按 = 确认（Enter）；上下滑动 = 切焦点（ArrowUp/Down）；双击 = 返回（Backspace）。

## Technical honesty

- 范本是示意线条图，不是精确手形图谱：每印的手指配置以要点文字为准，页内与 README 均已标注。
- LLM 判定会出错、会看不清：MATCH=UNSURE 与 GUESS=NONE 都如实呈现，不包装成结论；探针不下任何「识别率」结论，只交原始逐项记录。
- Web 预览无相机与 LLM 时，拍照 / 判定会以裸错误码如实失败，不模拟结果。

## Permissions

`CAMERA`（定格拍照判定），仅此一项，与 app.json 声明一致。

## Validation

- Static: app.json / package.json JSON parse；全部 .js 与 .ink setup 脚本 `node --check`；禁用 API grep 电池 0 命中；绿色色阶（无纯白）。
- Device stage (pending): GO 真机摆一轮回汇总数后，按 PLAN §4 门槛回填 TR02 收录表。
