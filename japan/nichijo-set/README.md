# Nichijo Set（日常生活セット）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-nichijo-set
```

JP22 · 日本在地 × 注意力 × 路缘坡（日常生活集合）。精品线合并重做：由 CC11 `left-home-proof`（出门存证回放，日本在地化）＋ JP18 `coin-laundry`（洗衣倒计时守候）＋ JP19 `origami-steps`（点头推进折纸）合并；原三个 Agent 原样封存、不删不改。一句话场景：日本家庭日常里，出门前逐点存证防焦虑、自助洗衣不取忘、双手占满时折纸不中断——三件家事各走完自己的闭环，进度都留在端末。

## 预览截图

![预览-index](<../../screenshots/nichijo-set/preview-nichijo-set-index.png>)
![预览-proof](<../../screenshots/nichijo-set/preview-nichijo-set-proof.png>)
![预览-proof-s2](<../../screenshots/nichijo-set/preview-nichijo-set-proof-s2.png>)
![预览-laundry](<../../screenshots/nichijo-set/preview-nichijo-set-laundry.png>)
![预览-laundry-s2](<../../screenshots/nichijo-set/preview-nichijo-set-laundry-s2.png>)
![预览-origami](<../../screenshots/nichijo-set/preview-nichijo-set-origami.png>)
![预览-origami-s2](<../../screenshots/nichijo-set/preview-nichijo-set-origami-s2.png>)

## 结构与功能（闭环）

四页结构（家务磁贴总览 / 存证印章清单 / 洗衣机器面板 / 折纸步骤卡），共享状态跨会话持久化（wx storage `nichijoSetV1`）：

- **总览（pages/index）**：三模式磁贴＋今日实数汇总（存证是否完成、洗衣稼働台数、折纸完成作品数），全部读持久化数据。
- **存证（pages/proof）**：检查点内容集 5 处（ガスコンロ/玄関の鍵/窓の鍵/水道/エアコン）。每点以相机实拍存证（`ImageCapture.takePhoto`，CAMERA 权限已声明）或本人手动确认，方式（写真/手動）与时刻如实记录；5 点齐全存为今日记录，离家后 REPLAY 带时间播报——承接 CC11 的「出门后焦虑→证据回放断循环」。
- **洗衣（pages/laundry）**：机器内容集 3 台（洗濯機A/B、乾燥機），时长预设 30/45/60 分；结束时刻以时间戳持久化，离开页面或应用后续算，结束只播报一次。
- **折纸（pages/origami）**：作品内容集 3 个共 21 步（つる 8 步/かぶと 6 步/ふうせん 7 步），点头或 NEXT 一步一进，每步持久化，完成记入并自动下一作品。

方向分工：注意力承担三件家事的守候与回放；路缘坡以 CC11 的认知障碍先行场景（存证断焦虑循环）为核；日本在地承担自助洗衣与折纸的日常场景。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 存证页手动确认当前点／洗衣页开始／折纸页下一步 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 切换检查点、机器或步骤 |
| 点头 | `onHeadGesture('nod')` | 存证页下一点位／折纸页下一步 |
| 双击 | Backspace | 系统返回（子页 BACK 键亦可） |

## 权限

CAMERA（仅存证模式拍照用，app.json 已声明）。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## 诚实边界

- 拍照失败（无相机/拒绝权限）时明示失败并只提供手动确认，手动记录如实标「手動」，绝不冒充写真（预览截图 proof-s2 即 Web 运行时无相机时的真实失败提示）。
- 存证只证明「本人在某时确认过」，不做识别判断、不保证设备状态本身（与慧眼辨识的区别）。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | Nichijo Set（待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | Life（待导入时确认） |
| Intent Description | 出かける前の存証、ランドリー守候、おりがみ手順の日常生活セット |
| Agent ID | 待导入后回填 |
| 状态 | 已打包、已推送；未导入 Studio、未真机测试、未提审 |

## 提审资料 (Review Submission)

### Feature Description (≤500 chars)

A Japanese daily-life set with three full modes: leave-home proof (five points proven by a real camera photo or an honest manual check, stored with times and replayed after you leave), a laundry watch (three machines, end times persisted as timestamps, counting down across sessions), and origami steps (three works, 21 steps, advanced by a nod, progress saved).

### Opening Message (≤500, Markdown)

**日常生活セットへようこそ。** 出かける前の存証、ランドリーの守候、おりがみの手順——今日の用事を三つ守ります。

### Preview Media

图片 7 张（本页预览截图，提审时取 3–5 张）；视频待真机阶段补（提审要求 ≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 四页新作（总览/存证/洗衣/折纸）；CC11+JP18+JP19 合并重做，检查点 5 处、机器 3 台、折纸 3 作品 21 步、相机存证接线、状态跨会话持久化。
- Improvements: 无（首版）。
- Fixes: 无（首版）。

## 打包与预览

- 打包：`~/tools/bin/aix pack . -o nichijo-set.aix`（仓库副本在 `aix/nichijo-set.aix`）
- 预览：`~/tools/bin/aix preview . --html-out artifacts/preview.html` 后走本地截图管线（端口 8902）
