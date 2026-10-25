# Taxfree Ledger（免税购物账本）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-taxfree-ledger
```

JP11 · 日本本地化系列。交互哲学：**免税账本 Taxfree Ledger**。本 Agent 是一本只记免税的账：按店铺记一般物品与消耗品两笔金额，合计满 5,000 日元线才算该店达标，达标后由你亲手确认密封袋已封。店铺一换，账就换一页；达标店数单独计数。它不判断免税资格（最终判断在店铺收银台，界面明写），不扫条码、不识商品，只守「凑线与封袋」这两件事。

## 预览截图

![预览-index](<../../screenshots/taxfree-ledger/preview-taxfree-ledger-index.png>)
![预览-s2](<../../screenshots/taxfree-ledger/preview-taxfree-ledger-s2.png>)
![预览-s3](<../../screenshots/taxfree-ledger/preview-taxfree-ledger-s3.png>)
![预览-s4](<../../screenshots/taxfree-ledger/preview-taxfree-ledger-s4.png>)

## 在地性

日本免税购物（Tax Free）是外国游客在店内当场适用的制度：同一店铺同一天购物满线才能免税，消耗品必须装进密封袋且在日本境内不得开封，护照要在店头出示。最容易出错的不是价格，而是「这家店到底凑够线没有、密封袋到底封了没有」。

## 功能流程（闭环）

- 分店记账：同一店铺内一般物品与消耗品分开加（各按 1,000 日元一档手动加），合计实时对照 5,000 日元线
- 封袋确认：合计达线后 GO/点头才把密封袋记为已封，并 TTS 一句「日本国内では開けないでください」
- 换店结算：换店时若该店已达线，达标店数 +1，否则不计，账页清零重记

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 STORE 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 5,000 日元线是本账本的目安合计口径，实际免税可否、分类口径与退税手续以店铺收银台的判断为准，界面明示
- 密封袋是否真的封好、护照是否出示，均由本人确认，Agent 只记确认结果，不做光学核验
- 金额为手动登记（无收银系统对接），输错请用换店前复核，关页后账本即忘

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/taxfree-ledger
~/tools/bin/aix pack . -o ../dist/taxfree-ledger.aix
~/tools/bin/aix list ../dist/taxfree-ledger.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Taxfree Ledger（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a tax-free shop in Japan: tallies one store purchase toward the 5,000 yen line and records the sealed-bag confirmation. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Japan tax-free shopping ledger: per store, general goods and consumables are tallied separately against a 5,000 yen line, and once the line is met you confirm the sealed bag yourself before leaving the store. Stores are counted only when they meet the line. It never judges tax-free eligibility - the shop register does - and it never scans or identifies goods.

### Opening Message

> ## Taxfree Ledger
> 
> Tax-free shopping fails on two small things: whether this store has reached the line, and whether the sealed bag is actually sealed. I keep one page per store, count general and consumable amounts toward the 5,000 yen line, and I only mark a store done when you confirm the bag is sealed. The register makes the final call, not me.

### Preview Media

- `preview-taxfree-ledger-index.png` — 初始状态
- `preview-taxfree-ledger-s2.png` — 演示状态 2
- `preview-taxfree-ledger-s3.png` — 演示状态 3
- `preview-taxfree-ledger-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：免税账本 Taxfree Ledger；护照本页：阈值横条 + 店铺三行账 + 大字合计

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
