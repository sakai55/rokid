# 唐诗游戏集 - Agent Notes

GA95. 中国在地 × 游戏 × 指向性（头动方向游戏）× 注意力（最佳成绩守候）。

## Design contract

中国家庭等待时间，全家用眼镜一本玩 20 个唐诗游戏，背诗、认诗、算诗句，计分结算。

## Counts

唐诗 20 首，机制：数数 4（目标字数 20/18/28/20）、方向 4（g02/g07/g12/g17，各 6 轮）、问答 4、步骤 4（每首 5 步）、算数 3、记录 1。20 个游戏名与全部已建 hub 标题及龙舟/民间/春节/中秋/灯会/京剧 6 个 hub 逐一比对，0 碰撞。

## Storage

存储键 `chinaTangPoetryGamesShuuV1`（已选游戏、各游戏最佳成绩、已结算记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 分数只来自真实点头与点按，不虚构分数。
- 方向判定为演示判定、非物理识别。
- 分段动作：一次转头只换一个方位，须回中再换，绝不转圈。
- 诗文为公共领域唐诗，作者与文本已核对；问答答案均为真实唐诗事实。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：方向页 _startSensor＋_onYaw（回正武装）＋点头主确认；全部游戏页 onHeadGesture('nod')。
- 21 页，.ink md5 全不相同，方向页 4/4 带传感器接线。
