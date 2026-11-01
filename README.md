# 菜市场核对

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-market-photo
```

**AIX 直接下载**（最新版）: [china-market-photo.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-market-photo.aix)

DI54 · 中国在地 × 指向性 × 注意力。中国菜市场买菜者双手提菜，看向摊位、点头触发拍照核对菜篮子，差一件不结账

## 预览截图

![preview-china-market-photo-index.png](../screenshots/china-market-photo/preview-china-market-photo-index.png)
![preview-china-market-photo-check.png](../screenshots/china-market-photo/preview-china-market-photo-check.png)
![preview-china-market-photo-record.png](../screenshots/china-market-photo/preview-china-market-photo-record.png)
![preview-china-market-photo-check-s2.png](../screenshots/china-market-photo/preview-china-market-photo-check-s2.png)

## 方向构成

中国在地 × 指向性 × 注意力。

## 结构与功能

index/check/record。

## 内容集计数

摊位 6 个：蔬菜摊、水果摊、肉禽摊、豆制品摊、水产摊、干货调料摊；菜篮子商品 12 件：青菜、番茄、鸡蛋、豆腐、猪肉、鲫鱼、苹果、香蕉、土豆、大葱、生姜、大蒜；结账记录按实际条数计。跨会话持久化：存储键 `chinaMarketPhotoV1`。

## 眼镜独占能力

解放双手的第一视角即时捕获：`app.json` 声明 `CAMERA`；`pages/check/index.ink` 的 `photoTap`（点头经 `primaryTap` 触发）调用 `ImageCapture.takePhoto`，经 `blob.arrayBuffer()`＋分块 `btoa` 转 data URL 校验后只记拍照元数据、不存图；拍照是结账放行必经步——未拍照或未打勾满 12 件时 `finishTap` 拒绝结账并报差件数。照片只作本人当场核对，不识别他人正脸，不声称自动识别商品。

## 权限

`CAMERA` 一个。拍照失败如实提示并报裸码，不冒充已核对；照片不上传、不存图、不做人脸或商品识别。

## 诚实边界

- 照片只给本人当场对照菜篮子用，不识别他人正脸，不声称自动识别商品。
- 差一件不结账：未打勾满 12 件或未拍照时，结账确认会被拒绝并报差件数。
- 拍照失败时如实提示，不冒充已核对。

## 错误码

失败时在眼镜屏上显示裸码，TTS 只读码本身，最近一次错误写入持久化数据的 `lastError`（含码、本机 slug、版本与原文）。本机可能出现的码：

- `E5001` 记录保存失败（存储写入异常）

- `E5002` 记录读取失败（读取／解析异常）

- `E3005` 播报失败（TTS speak 异常）

- `E8001` 页面切换失败（navigateTo／navigateBack 异常）

- `E8004` 运行时接口缺失（相机／ImageCapture 不可用）

- `E2001` 拍照失败（takePhoto 报错）

- `E2005` 照片编码转文本失败（arrayBuffer→data URL 失败）


## 设备测试信息

| Studio 名 | 未填写 |
| Version | 1.0.0 |
| App Category | 未填写 |
| Intent Description | 未填写 |
| Agent ID | 未填写 |
| 状态 | 未真机验证 |


## 提审资料

Feature Description: 菜市场买菜核对助手：双手提菜时看向摊位、点头拍照核对菜篮子，12 件打勾齐了才能结账，差一件不结账。


Opening Message: 菜买齐了没有？看向摊位、点头拍一张，对着照片逐件打勾，齐了再结账。


Preview Media:

- `preview-china-market-photo-index.png`

- `preview-china-market-photo-check.png`

- `preview-china-market-photo-record.png`


> 正式提审需媒体文件 3–5 个（含视频 ≥1 个、≤60 秒）；视频待 GO 真机录制后补。


Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: 无（初版）
- Fixes: 无（初版）
