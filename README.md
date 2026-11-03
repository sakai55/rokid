# 自提核对

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-pickup-photo
```

[china-pickup-photo.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-pickup-photo.aix)

## 功能

社区团购自提点取货者双手提袋，看向货架、点头触发拍照核对团购商品，12 件齐才可取货确认，差一件不走。

## 场景

中国社区团购自提点取货者双手提袋，看向货架、点头触发拍照核对团购商品，差一件不走。

## 方向构成

中国在地 × 指向性（视线拍照核对）× 注意力（逐件守候核对）。指向性承担看向锁定与拍照核对，注意力承担 12 件逐件守候。

## 眼镜独占能力

视线与头部方向协调＋第一视角即时捕获：相机与视线同轴，看向哪个货架就拍哪个货架，双手提袋时点头即拍，不用掏手机。接线：app.json 声明 CAMERA；pages/check/index.ink 的 photoTap（getUserMedia ＋ ImageCapture.takePhoto）为取货确认必经步，照片经 blob.arrayBuffer()＋分块 btoa 转 data URL，预览无相机时失败如实显示；_onYaw 转头切架；取货确认须照片＋12 件全勾。

## 页面

| 页面 | 职责 |
|---|---|
| pages/index | 6 个货架与核销进度 |
| pages/check | 看向锁定货架、点头拍照、逐件打勾、取货确认 |
| pages/record | 最近 6 条取货记录与合计 |

## 内容集

6 个货架 × 12 件商品（每架 2 件，逐件可数）：一号架牛奶／鸡蛋、二号架馒头／饺子、三号架苹果／香蕉、四号架青菜／土豆、五号架纸巾／洗衣液、六号架汤圆／水饺。取货记录按实数计。

## 跨会话持久化

存储键 `chinaPickupPhotoV1`。存所选货架、打勾状态、照片时间与字节数、取货记录数组、lastError。照片本体只在当次会话内存中持有，不持久化。

## 权限

`CAMERA`。语音播报不需要清单权限，定位不用。

## 手势映射

| 镜腿手势 | 按键事件 | 本台作用 |
|---|---|---|
| 单指点按 | Enter | 主确认（各页主按钮） |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## 错误码

- `E5001` 存储写入失败
- `E5002` 存储读取失败
- `E3005` 语音播报失败
- `E8001` 页面跳转失败
- `E7001` 头部传感器不可用或读数失败
- `E2001` 拍照失败
- `E2013` 照片编码失败
- `E8004` 相机接口不可用

失败时屏显裸码，lastError 里同时记裸码、slug、版本与原文。

## 预览截图

![preview-china-pickup-photo-index.png](../screenshots/china-pickup-photo/preview-china-pickup-photo-index.png)
![preview-china-pickup-photo-check.png](../screenshots/china-pickup-photo/preview-china-pickup-photo-check.png)
![preview-china-pickup-photo-record.png](../screenshots/china-pickup-photo/preview-china-pickup-photo-record.png)

## 提审资料

### Feature Description

社区团购自提点取货者双手提袋，看向货架、点头触发拍照核对团购商品，12 件齐才可取货确认，差一件不走。

### Opening Message

到自提点了？看向货架、点一下头拍照，我帮你一件件核对齐再走。

### Preview Media

[preview-china-pickup-photo-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-pickup-photo/preview-china-pickup-photo-video.mp4)
![preview-china-pickup-photo-index.png](../screenshots/china-pickup-photo/preview-china-pickup-photo-index.png)
![preview-china-pickup-photo-check.png](../screenshots/china-pickup-photo/preview-china-pickup-photo-check.png)
![preview-china-pickup-photo-record.png](../screenshots/china-pickup-photo/preview-china-pickup-photo-record.png)


### Change Log

- Features：首版功能，见上文页面表。
- Improvements：无。
- Fixes：无。

## 设备测试信息

| 项目 | 内容 |
|---|---|
| Studio 名称 | 待填 |
| Version / Build | 待填 |
| App Category | 待填 |
| Intent Description | 待填 |
| Agent ID | 待填 |
| 状态 | 待填 |
