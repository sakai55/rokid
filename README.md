# 市役所手续助手 Shiyakusho Tetsuzuki

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-shiyakusho-tetsuzuki
```

一句话场景：市役所办手续的高龄者，照着清单带齐文件、守着号码不错过叫号。

## 方向构成

- 日本在地：手续与书类均为日本市役所制度实物（転入届、転出届、マイナンバーカード、国民健康保険、印鑑登録、児童手当），用户可见文案全日语。
- 路缘坡：高齢者与不熟悉手续的人先行——大字票据、逐项打勾、点头推进，障碍不为大众收益稀释。
- 注意力：盯守模式——书类齐全盯守与番号等待盯守落在同一手续上，场景内生，不是功能拼盘。

## 预览截图

![手続き一覧](../screenshots/shiyakusho-tetsuzuki/preview-shiyakusho-tetsuzuki-index.png)
![書類チェック](../screenshots/shiyakusho-tetsuzuki/preview-shiyakusho-tetsuzuki-docs.png)
![書類チェック 2](../screenshots/shiyakusho-tetsuzuki/preview-shiyakusho-tetsuzuki-docs-s2.png)
![番号待ち](../screenshots/shiyakusho-tetsuzuki/preview-shiyakusho-tetsuzuki-number.png)
![番号待ち 2](../screenshots/shiyakusho-tetsuzuki/preview-shiyakusho-tetsuzuki-number-s2.png)

## 结构与功能

3 页：

- `pages/index/` 手続き一覧：6 件手续票据，每件标書類数（4/4/5/3/3/5 点，合计 24 点）；下方为子页选择列（▶ 标记，onShow 时复位为第 1 项）：选中第 1 项时 Enter 打开书类页，按一次 ArrowDown 再 Enter 打开番号页；子页行本身也可点击直达；目标手续显示在明细行，用“つぎの手続きへ”按钮切换。
- `pages/docs/` 書類チェック：选中手续的书类逐项打勾卡片，点头/Enter 推进，全部勾齐时 TTS 播报并写入完成记录。
- `pages/number/` 番号待ち：手动开始的等待计时（大字 mm:ss，1 秒刷新），“呼ばれた”确认与“手続き完了”各写一条持久化记录（含等待秒数与时刻）。

内容集计数：手续 6 件；书类 24 点（転入届 4、転出届 4、マイナンバーカード 5、国民健康保険 3、印鑑登録 3、児童手当 5）。跨会话持久化：存储键 `shiyakushoV1`（选中手续、每件打勾数组、完成/叫号/完了记录数组）。

## 手势映射

| 位置 | 镜腿/按键 | 动作 |
| --- | --- | --- |
| 一览 | ArrowUp/ArrowDown | 上/下一子页（书类页/番号页） |
| 一览 | Enter / 点头 | 打开选中子页（第 1 项为书类页，第 2 项为番号页） |
| 一览 | 按钮 | 切换目标手续 / 打开选中子页 |
| 一览 | onShow | 选中项复位为第 1 项 |
| 书类 | ArrowUp/ArrowDown | 上/下一份书类 |
| 书类 | Enter / 点头 | 勾选当前书类并推进 |
| 书类 | Backspace / 返回按钮 | wx.navigateBack 回首页 |
| 番号 | ArrowUp/ArrowDown | 上/下一动作 |
| 番号 | Enter / 点头 | 执行选中动作（开始/停止、呼ばれた、记录完成） |
| 番号 | Backspace / 返回按钮 | wx.navigateBack 回首页 |

## 权限

无。

## 诚实边界

- 番号计时只计量用户自己按下开始后的时间，不读取市役所叫号屏；“呼ばれた”只由用户本人确认，不声称知道真实叫号。
- 书类打勾只证明用户本人勾过，不保证窗口实际收件；窗口要求以现场为准。

## 设备测试信息

| 项目 | 内容 |
| --- | --- |
| Studio 名 | 待回填 |
| Version | 1.0.0 |
| App Category | 待回填 |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| 状态 | 未真机验证 |

## 提审资料 (Review Submission)

Feature Description: 市役所办手续的高龄者助手：6 件日本市役所手续配 24 点书类清单，逐项打勾、齐全播报；手动番号等待计时，叫号确认与手续完成都留记录，跨会话可查。

Opening Message: 市役所の手続きをお手伝いします。まず手続きを選んで、書類を一つずつ確認しましょう。

Preview Media: 预览截图 5 张（见上「预览截图」节；视频待 GO 真机录制后补）。

Change Log — Build 1.0.0:

- Features added: 6 件手续×24 点书类清单；逐项打勾与齐全播报；手动番号等待计时与叫号/完成记录持久化。
- Improvements: 无（首版）。
- Fixes: 无（首版）。
