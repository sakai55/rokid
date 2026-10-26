# Eki Dekake（駅のお出かけ）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-eki-dekake
```

JP20 · 日本在地 × 路缘坡 × 指向性。精品线合并重做：由 JP14 `kasa-share`（駅前シェア傘帳簿）与 JP16 `eki-barrier`（駅の昇降機側確認）按同一场景合并而成；原两个 Agent 原样封存、不删不改。一句话场景：雨天或初到车站时，行动不便者在眼镜上完成一段车站出行——找到有电梯的一侧 → 借共享伞 → 守住归还期限 → 确认归还，并留下跨会话的出行记录。

## 预览截图

![预览-index](<../../screenshots/eki-dekake/preview-eki-dekake-index.png>)
![预览-kasa](<../../screenshots/eki-dekake/preview-eki-dekake-kasa.png>)
![预览-kasa-s2](<../../screenshots/eki-dekake/preview-eki-dekake-kasa-s2.png>)
![预览-record](<../../screenshots/eki-dekake/preview-eki-dekake-record.png>)

## 结构与功能（闭环）

三页结构，形态各异（车站出发板 / 傘フロー時計 / 記録ログ）：

- **駅ボード（pages/index）**：6 个车站的设施内容集常驻成「出发板」——每站含电梯侧（左/右/中央）、电梯位置、伞点、归还期限（条目数：6 站 × 4 项）。上下滑选站；AbsoluteOrientationSensor 实时读头部朝向（左/右/正面），与所选站的电梯侧对照显示；点头/GO 定站并写为「前回駅」。
- **傘フロー（pages/kasa）**：借りる登録（以定站的期限小时数生成截止时刻）→ 期限守候（30 秒刷新剩余分钟，大字时钟）→ 返却確認（本人按钮/点头确认，写入出行记录并清贷出状态）。
- **記録（pages/record）**：出行记录最近 5 件 + 最常用车站统计，跨会话持久化（wx storage `ekiDekakeV1`），本人可清空。

方向分工：路缘坡承担「行动不便者的车站出行」本体；指向性承担电梯侧对照（头部朝向传感器实读）；日本在地承担车站设施与共享伞制度场景。非拼盘：三者缺一，出行链断一环。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 定站（駅ボード）／傘フローでは借りる・返却の主确认 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 选站（次/前） |
| 点头（头稳时） | `onHeadGesture('nod')` | 与主确认等价 |
| 双击 | Backspace | 系统返回（子页 BACK 键亦可） |

## 权限

无。AbsoluteOrientationSensor 与 wx storage 不需要权限声明；TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明不生效）。

## 诚实边界

- 设施集为内置 6 站数据，不联网、不保证实时变更；伞的在库/可借状态 Agent 不知道、不代断。
- 传感器不可用时明示「センサーなし（手動で確認してください）」，不假装读数；返却済みは本人の確認だけが記す。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | Eki Dekake（待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | Life（待导入时确认） |
| Intent Description | 駅で昇降機の側を確認し、シェア傘を借りて期限内に返す |
| Agent ID | 待导入后回填 |
| 状态 | 已打包、已推送；未导入 Studio、未真机测试、未提审 |

## 提审资料 (Review Submission)

### Feature Description (≤500 chars)

Station outing, end to end: a departure-board of six stations with elevator side, umbrella point and return deadline; a borrow-to-return umbrella flow with a watched countdown; and a persistent trip record with your most-used station. Built for travellers who need the elevator side and cannot afford a forgotten umbrella.

### Opening Message (≤500, Markdown)

**駅のお出かけへようこそ。** まず駅を選んでください。昇降機の側を頭の向きと照らし合わせ、傘を借りたら期限をずっと見守ります。

### Preview Media

图片 4 张（本页预览截图）；视频待真机阶段补（提审要求 3–5 个文件、≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 三页新作（駅ボード/傘フロー/記録）；JP14+JP16 合并重做，设施内容集 6 站、期限守候、跨会话出行记录。
- Improvements: 无（首版）。
- Fixes: 无（首版）。

## 打包与预览

- 打包：`~/tools/bin/aix pack . -o eki-dekake.aix`（仓库副本在 `aix/eki-dekake.aix`）
- 预览：`~/tools/bin/aix preview . --html-out artifacts/preview.html` 后走本地截图管线（端口 8902）
