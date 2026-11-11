# 熊猫基地拍照核对 - Agent Notes

DI83. 中国在地 × 指向性（视线拍照核对）× 注意力。

## Design contract

成都大熊猫繁育研究基地参观者双手拿导览册，看向馆区、点头触发拍照核对 12 个拍照点。

## Counts

馆区 6 处×拍照点 12 个：太阳产房（产房外活动场／产房内参观窗）、月亮产房（产房外活动场／产房内参观窗）、大熊猫1号别墅（别墅外竹林／别墅内活动场）、大熊猫2号别墅（别墅外竹林／别墅内活动场）、熊猫幼儿园（幼儿园外草坪／幼儿园内活动室）、成年大熊猫别墅（别墅外活动场／别墅内参观窗）。

## Storage

存储键 `chinaPandaPhotoV1`（已选馆区、已打勾拍照点、拍照时间与字节数、走完记录、lastError）。照片本身只在会话内保留，不持久化。

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
