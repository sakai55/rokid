# 园林拍照核对

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-garden-photo
```

[china-garden-photo.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-garden-photo.aix)

## 功能

苏州园林参观者双手拿导览册，看向园林、点头触发拍照核对 12 个拍照点，差一处不算走完。

## 场景

苏州园林参观者双手拿导览册，看向园林、点头触发拍照核对 12 个拍照点，差一处不算走完。

## 方向构成

中国在地 × 指向性（视线拍照核对）× 注意力。

## 眼镜独占能力

解放双手的第一视角即时捕获：双手拿导览册时无法掏手机，看向园林、点头即拍照，拍照是走完放行的必经步。接线：pages/photo/index.ink photoTap（getUserMedia + ImageCapture.takePhoto），点头触发 primaryTap，confirmTap 无照片拒绝确认。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 6 处园林 |
| pages/photo | 看向锁定、点头拍照、打勾 12 处 |
| pages/record | 走完记录 |

## 内容集

6 处园林 × 2 个拍照点 = 12 个拍照点（拙政园：正门／荷花池前；留园：正门／曲廊前；网师园：正门／池边；狮子林：正门／假山前；沧浪亭：正门／复廊前；环秀山庄：正门／假山前）。

## 跨会话持久化

存储键 `chinaGardenPhotoV1`（已选园林、已打勾拍照点、拍照时间与字节数、走完记录、lastError）。照片本身只在会话内保留，不持久化。

## 权限

声明 CAMERA。定位与媒体权限不用。

## 手势映射

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## 错误码

- `E5001` 存储写入失败
- `E5002` 存储读取失败
- `E3005` 语音播报失败
- `E8001` 页面跳转失败
- `E7001` 头部传感器不可用或读数失败
- `E8004` 相机接口缺失
- `E2001` 拍照失败
- `E2013` 照片编码失败

- 照片只作本人核对，不识别他人正脸，不声称自动识别景点。
- 没拍照不能确认走完，未打勾的拍照点只提醒，不写记录。
- 预览无相机时拍照如实失败，绝不伪造成成功。

## 预览截图

![preview-china-garden-photo-index.png](../screenshots/china-garden-photo/preview-china-garden-photo-index.png)
![preview-china-garden-photo-photo.png](../screenshots/china-garden-photo/preview-china-garden-photo-photo.png)
![preview-china-garden-photo-photo-s2.png](../screenshots/china-garden-photo/preview-china-garden-photo-photo-s2.png)
![preview-china-garden-photo-record.png](../screenshots/china-garden-photo/preview-china-garden-photo-record.png)

## 提审资料

### Feature Description

苏州园林参观者双手拿导览册，看向园林、点头触发拍照核对 12 个拍照点，差一处不算走完。

### Opening Message

苏州园林参观者双手拿导览册，看向园林、点头触发拍照核对 12 个拍照点，差一处不算走完。

### Preview Media

[preview-china-garden-photo-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-garden-photo/preview-china-garden-photo-video.mp4)
![preview-china-garden-photo-index.png](../screenshots/china-garden-photo/preview-china-garden-photo-index.png)
![preview-china-garden-photo-photo.png](../screenshots/china-garden-photo/preview-china-garden-photo-photo.png)
![preview-china-garden-photo-photo-s2.png](../screenshots/china-garden-photo/preview-china-garden-photo-photo-s2.png)

### Change Log

- Features：首版功能见上文页面表。
- Improvements：无。
- Fixes：无.

## 设备测试信息

| Studio 名称 | 待填 |
|---|---|
| Studio 名称 | 待填 |
| Version / Build | 待填 |
| App Category | 待填 |
| Intent Description | 待填 |
| Agent ID | 待填 |
| 状态 | 待填 |
