# 花火帰り

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-hanabi-kaeri
```

JP30 · 日本在地 × 指向性 × 路缘坡。花火大会の後、混雑の中で集合場所へGPSの方角と距離で戻る

## 预览截图

![preview-hanabi-kaeri-index.png](../screenshots/hanabi-kaeri/preview-hanabi-kaeri-index.png)
![preview-hanabi-kaeri-guide.png](../screenshots/hanabi-kaeri/preview-hanabi-kaeri-guide.png)
![preview-hanabi-kaeri-record.png](../screenshots/hanabi-kaeri/preview-hanabi-kaeri-record.png)
![preview-hanabi-kaeri-record-s2.png](../screenshots/hanabi-kaeri/preview-hanabi-kaeri-record-s2.png)

## 方向构成

- 本 Agent 的方向构成：日本在地 × 指向性 × 路缘坡。每个方向在场景里承担不可替代的一环，非功能拼盘。
- 一句话场景：花火大会の後、混雑の中で集合場所へGPSの方角と距離で戻る。

## 结构与功能

3 页：`pages/index/` 集合場所登録（GPS一键保存经纬度＋时刻，未保存时明示未登録）；`pages/guide/` 帰路（重新测位后算出8方位cardinal＋10m取整距离，约数明示含误差，到着ボタン记一条到着记录；预览环境无GPS，guide-s2不以无定位状态充数，故本台截图为4张：首页/归路/记录/记录-到着后）；`pages/record/` 記録（最近6条＋总数）。定位三件套：app.json声明GEOLOCATION、index/guide两页调用navigator.geolocation.getCurrentPosition、guide页用经纬度差算方位角→8方位换算。

内容集计数：集合場所1点（GPS实测保存）；方位8方向；到着记录按实际条数计。跨会话持久化：存储键 `hanabiKaeriV1`（选中项、打勾/答题/计数状态、完成记录数组、`lastError`）。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 主确认（各页主按钮） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 切换选项 / 上下一项 |
| 点头（头稳时） | `onHeadGesture('nod')` | 等价于主确认 |
| 双击 | Backspace | 返回上一页（子页） |

## 权限

GEOLOCATION：仅用于保存集合場所与计算回集合場所的方位・距离，拒绝/不可用时如实降级、绝不编造位置。

## 诚实边界

- 方角と距離は GPS の測位からの概算です。誤差を含み、10m単位に丸めています。
- 屋内・人混みでは GPS が弱く、測れないときは測れないと出します。位置を推測で補いません。
- 集合場所は本人が現地で登録した一点だけを使います。

## 错误码

失败时眼镜屏显裸码、TTS 只读码、最近一次错误写入持久数据的 `lastError`（含码、本台 slug、版本与原文）。本台可能出现的码：

- `E5001` 记录保存失败（存储写入抛错）
- `E5002` 记录读取失败（读取/解析抛错）
- `E3005` 播报失败（TTS speak 抛错）
- `E8001` 页面切换失败（navigateTo/navigateBack 抛错）
- `E7002` 定位失败（getCurrentPosition 失败，非权限类）
- `E7003` 定位权限未给（getCurrentPosition 拒绝）

## 设备测试信息

| 项目 | 内容 |
|---|---|
| Studio 名 | 待回填 |
| Version | 1.0.0 |
| App Category | 待回填 |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| 状态 | 未真机验证 |

## 提审资料 (Review Submission)

Feature Description: Hanabi kaeri: after a fireworks festival, return to a saved meeting point by GPS cardinal bearing and approximate distance, with honest degradation when no fix is available.

Opening Message: 花火大会の後ですね。集合場所を登録して、方角と距離で戻りましょう。

Preview Media:
- `preview-hanabi-kaeri-index.png`
- `preview-hanabi-kaeri-guide.png`
- `preview-hanabi-kaeri-record.png`
- `preview-hanabi-kaeri-record-s2.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机录制后补。

Change Log — Build 1.0.0:

- Features added: 首个版本；花火大会の後、混雑の中で集合場所へGPSの方角と距離で戻る
- Improvements: 无（首个版本）
- Fixes: 无（首个版本）
