# Sijang Shopping（시장 장보기）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-sijang-shopping
```

KR15 · 韩国在地 × 路缘坡 × 注意力。精品线合并重做：由 CC09 `high-shelf-ask`（超市高货架求助话）与 KR14 `sijang-basket`（시장 바구니 核销）按同一场景（韩国传统市场购物）合并而成；原两个 Agent 原样封存、不删不改。一句话场景：坐轮椅或坐姿逛韩国传统市场的人，高处摊位前生成一句准确的求助话（TTS 代说或大字出示），再按摊位逐件核销篮子，差一件不结账。

## 预览截图

![预览-index](<../screenshots/sijang-shopping/preview-sijang-shopping-index.png>)
![预览-ask](<../screenshots/sijang-shopping/preview-sijang-shopping-ask.png>)
![预览-ask-s2](<../screenshots/sijang-shopping/preview-sijang-shopping-ask-s2.png>)
![预览-basket](<../screenshots/sijang-shopping/preview-sijang-shopping-basket.png>)

## 结构与功能（闭环）

三页结构（市场摊位招牌网格 / 大字求助卡 / 篮子核销清单），状态跨会话持久化（wx storage `sijangShoppingV1`）：

- **总览（pages/index）**：6 个摊位（채소가게/생선가게/과일가게/반찬가게/잡화가게/떡집）× 每摊 2 件商品的进度网格，总进度（已装件数/求助完成数/完成趟数）一目了然。
- **求助卡（pages/ask）**：高处商品内容集 4 件（사과/수세미/멸치볶음/송편）× 求助话模板 4 句。看向锁定商品后，大字卡出示整句韩语，SPEAK 由 TTS 代说；点头（头稳时）或 CONFIRM 把「요청 완료」写入持久化。求助话只生成与出示/代说，Agent 不代断是否得到帮助。
- **篮子核销（pages/basket）**：12 件商品按摊位逐件打勾，缺件清单实时显示；未满 12 件时 CHECKOUT 锁定并语音说明，齐全后结算、记一次完成、清单清空待下次。

方向分工：路缘坡（轮椅/坐姿者先行）是本体，不为一般购物便利稀释；注意力承担逐件核销与缺件守候；韩国在地承担 시장 摊位与礼貌求助话的真实场景。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 篮子页勾选当前摊位第一件／求助页确认请求 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 切换摊位或高处商品 |
| 点头（头稳时） | `onHeadGesture('nod')` | 求助页记「요청 완료」 |
| 双击 | Backspace | 系统返回（子页 BACK 键亦可） |

## 权限

无。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## 诚实边界

- 摊位与商品为内置内容集，不联网，无实时价格/库存。
- 语言纯度机检：全部 .ink 假名 = 0、CJK 汉字 = 0。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | Sijang Shopping（待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | Life（待导入时确认） |
| Intent Description | 시장에서 높은 선반 도움 요청과 장바구니 확인 |
| Agent ID | 待导入后回填 |
| 状态 | 已打包、已推送；未导入 Studio、未真机测试、未提审 |

## 提审资料 (Review Submission)

### Feature Description (≤500 chars)

A full traditional-market trip for wheelchair and seated shoppers: six stalls and twelve items on one checklist that refuses checkout while anything is missing, plus a big-text help-phrase card for high stalls - four polite Korean phrases, spoken by TTS or shown large, with each request recorded on a nod.

### Opening Message (≤500, Markdown)

**시장 장보기에 오신 것을 환영합니다.** 높은 선반에서는 도움 카드를, 장바구니에서는 빠진 물건을 확인하세요.

### Preview Media

图片 4 张（本页预览截图）；视频待真机阶段补（提审要求 3–5 个文件、≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 三页新作（总览/求助卡/篮子核销）；CC09+KR14 合并重做，摊位 6 个、商品 12 件、高处求助 4 商品 × 4 句式、状态跨会话持久化。
- Improvements: 无（首版）。
- Fixes: 无（首版）。

## 打包与预览

- 打包：`~/tools/bin/aix pack . -o sijang-shopping.aix`（仓库副本在 `aix/sijang-shopping.aix`）
- 预览：`~/tools/bin/aix preview . --html-out artifacts/preview.html` 后走本地截图管线（端口 8902）
