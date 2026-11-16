# 平遥拍照核对 - Agent Notes

DI98. 中国在地 × 指向性（视线拍照核对）× 注意力。

## Design contract

平遥古城参观者双手拿导览册，看向景点、点头触发拍照核对 12 个拍照点。

## Counts

景点 6 处×拍照点 12 个：古城墙（南门瓮城／北门箭楼）、日升昌票号（票号正厅／票号后院）、县衙（县衙大堂／县衙监狱）、城隍庙（城隍庙正殿／城隍庙戏台）、协同庆票号（协同庆正厅／协同庆账房）、明清街（明清街牌坊／明清街老铺）。

## Storage

存储键 `chinaPingyaoPhotoV1`（已选景点、已打勾拍照点、拍照时间与字节数、走完记录、lastError）。照片本身只在会话内保留，不持久化。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 照片只作本人核对，不识别他人正脸，不声称自动识别景点。
- 没拍照不能确认走完，未打勾的拍照点只提醒，不写记录。
- 预览无相机时拍照如实失败，绝不伪造成成功。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 拍照接线：pages/photo/index.ink photoTap（getUserMedia＋ImageCapture.takePhoto）；Blob 转 data URL 用 arrayBuffer＋分块 btoa，FileReader＝0。
- 错误码 E8004／E2001／E2013 均已在仓库 ERROR-CODES.md 核实含义相符。
