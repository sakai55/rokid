# 长城拍照核对

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-greatwall-photo
```

[china-greatwall-photo.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-greatwall-photo.aix)

## 功能

长城参观者双手拿导览册，看向城楼、点头触发拍照核对 12 个拍照点，差一处不算走完。

## 场景

长城参观者双手拿导览册，看向城楼、点头触发拍照核对 12 个拍照点。

## 方向构成

中国在地 × 指向性（视线拍照核对）× 注意力。

## 眼镜独占能力

解放双手的第一视角即时捕获：双手拿导览册，看向城楼、点头触发拍照，拍照是走完放行的必经步。接线：app.json 声明 CAMERA，photo 页 photoTap（getUserMedia＋ImageCapture.takePhoto），Blob 转 data URL 用 arrayBuffer＋分块 btoa，FileReader＝0；没拍照不能确认走完。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 6 处城楼 |
| pages/photo | 12 个拍照点核对 |
| pages/record | 走完记录 |

## 内容集

城楼 6 处×拍照点 12 个：八达岭（八达岭关城楼／好汉坡石碑）、慕田峪（慕田峪关楼／敌楼）、居庸关（居庸关城楼／云台）、司马台（司马台东段／天梯）、金山岭（金山岭砖楼／将军楼）、山海关（天下第一关楼／老龙头）。

## 跨会话持久化

存储键 `chinaGreatwallPhotoV1`（已选城楼、已打勾拍照点、拍照时间与字节数、走完记录、lastError）。照片本身只在会话内保留，不持久化。

## 权限

声明 CAMERA（拍照核对用）。定位与媒体权限不用。

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
- `E8004` 拍照接口缺失（相机接口不存在）
- `E2001` 拍照失败（takePhoto 抛错）
- `E2013` 照片编码失败（arrayBuffer／分块 btoa 转码抛错）

- 照片只作本人核对，不识别他人正脸，不声称自动识别景点。
- 没拍照不能确认走完，未打勾的拍照点只提醒，不写记录。
- 预览无相机时拍照如实失败，绝不伪造成成功。

## 预览截图

![preview-china-greatwall-photo-index.png](../../screenshots/china-greatwall-photo/preview-china-greatwall-photo-index.png)
![preview-china-greatwall-photo-photo.png](../../screenshots/china-greatwall-photo/preview-china-greatwall-photo-photo.png)
![preview-china-greatwall-photo-photo-s2.png](../../screenshots/china-greatwall-photo/preview-china-greatwall-photo-photo-s2.png)
![preview-china-greatwall-photo-record.png](../../screenshots/china-greatwall-photo/preview-china-greatwall-photo-record.png)

## 提审资料

### Feature Description

长城参观者双手拿导览册，看向城楼、点头触发拍照核对 12 个拍照点，差一处不算走完。

### Opening Message

导览册拿好，看向城楼、点头拍照，12 处拍完才算走完。

### Preview Media

[preview-china-greatwall-photo-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-greatwall-photo/preview-china-greatwall-photo-video.mp4)
![preview-china-greatwall-photo-index.png](../../screenshots/china-greatwall-photo/preview-china-greatwall-photo-index.png)
![preview-china-greatwall-photo-photo.png](../../screenshots/china-greatwall-photo/preview-china-greatwall-photo-photo.png)
![preview-china-greatwall-photo-photo-s2.png](../../screenshots/china-greatwall-photo/preview-china-greatwall-photo-photo-s2.png)

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
