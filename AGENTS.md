# 自提核对 — Agent Notes

DI59。中国组：中国在地 × 指向性 × 注意力。

## Design contract

中国社区团购自提点取货者双手提袋，看向货架、点头触发拍照核对团购商品，差一件不走。

## Counts

内容集：6 个货架 × 12 件商品（每架 2 件）：一号架牛奶／鸡蛋、二号架馒头／饺子、三号架苹果／香蕉、四号架青菜／土豆、五号架纸巾／洗衣液、六号架汤圆／水饺。取货记录按实数计。

## Storage

存储键 `chinaPickupPhotoV1`（所选货架、打勾状态、照片时间与字节数、取货记录数组、lastError）。照片本体只在当次会话内存中持有，不持久化。

## Gesture map

| 镜腿手势 | 按键事件 | 本台作用 |
|---|---|---|
| 单指点按 | Enter | 主确认（核对页为拍照） |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换货架 |
| 点头 | onHeadGesture('nod') | 等同主确认：拍照 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 照片只作本人核对，不识别他人正脸，不声称自动识别商品；打勾由取货者本人完成。
- 取货确认有门：无照片不确认，未勾齐只提醒，不写记录。
- 相机与视线同轴，看向货架即瞄准该架；预览无相机时拍照失败如实显示，不伪造成功。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中；无旧式文件读取调用（Blob 转 data URL 走 arrayBuffer 加分块 btoa）。
- 拍照接线：pages/check/index.ink 的 photoTap（getUserMedia ＋ ImageCapture.takePhoto）；转头切架经 _onYaw。
