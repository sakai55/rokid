# 云冈拍照核对 - Agent Notes

DI119. 中国在地 × 指向性（视线拍照核对）× 注意力。

## Design contract

云冈石窟参观者双手拿导览册，看向石窟、点头触发拍照核对 12 个拍照点。

## Counts

石窟 6 处×拍照点 12 个：第5窟（大佛正脸／侧壁千佛）、第6窟（塔柱浮雕／释迦生平）、第12窟（乐伎浮雕／天宫伎乐）、第20窟（露天大佛／窟前遗迹）、第13窟（交脚弥勒／窟顶藻井）、云冈石窟博物馆（北魏展厅／造像展品）。

## Storage

存储键 `chinaYungangPhotoV1`（已选石窟、已打勾拍照点、拍照时间与字节数、走完记录、lastError）。照片本身只在会话内保留，不持久化。

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
- 判定：与 china-dunhuang-photo 机制相同、地点不同，6 处地点与 12 个拍照点无逐字重复（见 README 判定说明）。
