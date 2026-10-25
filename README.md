# Kairanban Relay（町内回覧板接力）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-kairanban-relay
```

JP13 · 日本本地化系列。交互哲学：**町内リレー Neighborhood Relay**。本 Agent は回覧板の「今どこにあるか」だけを守る帳簿：4 軒の順番を一本の線にし、今持っている家を大きく表示する。受け取ったら STAMP で押印を記し、PASS で次の家へ回す。押印していないのに回そうとすると止めて声で知らせる。一周回って町内会へ戻れば周回数を数える。板の中身・お知らせの内容は一切読まず、期限は各町内会の決まりに従う（界面明示）。

## 预览截图

![预览-index](<../screenshots/kairanban-relay/preview-kairanban-relay-index.png>)
![预览-s2](<../screenshots/kairanban-relay/preview-kairanban-relay-s2.png>)
![预览-s3](<../screenshots/kairanban-relay/preview-kairanban-relay-s3.png>)
![预览-s4](<../screenshots/kairanban-relay/preview-kairanban-relay-s4.png>)

## 在地性

回覧板（かいらんばん）は日本の町内会・自治会の連絡制度：区役所や町内会のお知らせを一枚の板・冊子に挟み、家から家へ順番に回して全員が目を通し、最後に町内会へ戻す。回し忘れ・押印漏れが起きると「回ってこない家」が出て連絡が止まる。眼鏡は板の中身を読まない——「今どの家にあって、押印は済んだか、次はどの家か」だけを外から守る。

## 功能流程（闭环）

- 順番保持：佐藤家→鈴木家→高橋家→田中家の順を線で表示し、今の家だけを満亮ドットで示す
- 押印確認：受け取った家の STAMP を本人が押して初めて PASS が進む。未押印のまま回そうとすると声で止める
- 周回計数：一周して町内会へ戻るたびに周回数 +1。板の内容は読まず、期限は町内会の決まりに従う

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 PASS 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 回覧板の中身・お知らせ文面は Agent は読まないし記録しない。押印の有無は本人の確認結果だけを記す
- 順番・期限・回収先は各町内会の決まりに従う。本 Agent は決まりを作らないし、回収日を自動で知らせない
- 家名は仮の表示順であり、実際の町内順番は本人が町内会の名簿で確認すること

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/kairanban-relay
~/tools/bin/aix pack . -o ../dist/kairanban-relay.aix
~/tools/bin/aix list ../dist/kairanban-relay.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Kairanban Relay（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | At home in a Japanese neighbourhood: tracks which house currently holds the kairanban circular board and whether it has been stamped. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Kairanban relay: the neighbourhood circular notice board, kept on track. Four houses in order on one line, the current holder shown large, a stamp recorded when a house receives it, and the board only moves on when the stamp is done. It never reads what is on the board, and the schedule belongs to the neighbourhood association, not to it.

### Opening Message

> ## Kairanban Relay
> 
> A kairanban only works when every house in turn actually sees it. I keep one thing: where the board is right now. Four houses on a line, the current house large, a stamp when it is received, and the board moves on only after the stamp. I never read what is on the board - that belongs to the neighbourhood, not to me.

### Preview Media

- `preview-kairanban-relay-index.png` — 初始状态
- `preview-kairanban-relay-s2.png` — 演示状态 2
- `preview-kairanban-relay-s3.png` — 演示状态 3
- `preview-kairanban-relay-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：町内リレー Neighborhood Relay；町内ルート線：家並みドット + 現在の家大字 + 押印行

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
