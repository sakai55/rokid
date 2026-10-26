# dabiaoge（大表哥）

rokidpost 通道的眼镜侧薄客户端（AIUI Agent）。眼镜只负责三件事：采集（说话）、发送（文字投单）、按结果信封格式化显示与朗读；推理与动作全在 Muse 侧（RokidRelay 处理）。

## 身份

用户在眼镜上向 Muse 提问的入口。打开大表哥，点头或单击镜腿开口说话，眼镜宿主先把语音转成文字，文字经前门（Cloudflare Worker + D1 队列）送到 Muse，Muse 的回单以信封形式回到眼镜：屏上按字幕卡版式显示，speak 摘要由眼镜朗读。

## 链路（v1 只走文字）

过通道的永远是文字，没有录音离开眼镜：

1. **说话**：点头（`onHeadGesture 'nod'`）或单击镜腿（Enter / GlobalHook，400ms 去重）开始；宿主 `SpeechRecognition` 识别，**识别文字分段攒起来实时显示在「你说的是」框里**（听错当场可见，停顿不截断）；攒到的文字以结束词「大表哥」结尾时剥掉结束词投单，单击/点头也可立即发送已攒文字。宿主 ASR 按自身停顿规则分段收尾（其停顿判定应用改不了），每段结束后自动续听；连续 6 次续听无新段则回待命；只说了结束词不投单并提示先说事；攒满 500 字自动发送。
2. **投单**：`POST https://rokidp.datumoj.com/submit`，header `x-channel-key` 带钥匙，正文 `{session, kind:"ask", text}`。session id 首次随机生成、`localStorage` 持久化。
3. **等单**：每 4 秒 `GET /ticket/<id>` 查一次，总超时 150 秒；按 status 显示进度（queued=已排队 / working=Muse 正在处理）。ticket id 存 `localStorage`。
4. **回单渲染**：done 后按信封渲染——text 显示 title+body；list 显示 title+body+items 逐行；choices 只展示选项（v1 不回传）；card 按 title+body 显示。speak 非空且与 body 不同才 TTS 朗读（相同不重复念）。
5. **特殊状态**：needs-approval 显示「这件事要你在手机上批准，已挂起」；error 显示失败原因；超时显示「单子不会丢，下次打开自动补收」。
6. **补收**：冷启动时若本地存有未完成 ticket，先查一次它的状态——办完的直接显示结果，排队/处理中的继续轮询。眼镜关掉不丢单。

## 钥匙纪律

- 钥匙（CHANNEL_KEY）只放在工程根目录 **`channel.js`** 一个文件里，仓库中永远只有占位符 `PASTE_CHANNEL_KEY_HERE`。
- 打包前在 Studio 里打开 `channel.js` 把占位符换成真钥匙（GO 本人操作；Muse 不持有这把钥匙）。填了真钥匙的工程**不回传 GitHub**；每次从 GitHub 重新导入都要重填。
- 钥匙未填时投单会被本地拦下并显示「钥匙未填」，不发无效请求。

## 操作（镜腿手势优先）

- 界面只有一个主按钮（胶囊形，随状态变文案：开始说话 / 发送 / 处理中… / 再问一句），同时保留 bindtap 供模拟器点按。
- 点头 = 与单击同效（开始说话 / 立即发送已攒文字 / 再问一句），处理中点头忽略。
- 滑动未占用；双击（Backspace）交给系统（返回/退出），页面不拦截。
- 页脚「演示」小钮循环切换示例三态（处理中 / 列表结果 / 文字结果 → 回待命），供预览截图与真机对照版式；示例数据在屏上标注「演示状态」，演示路径永不投单。

## 行为边界

- 权限只要 `RECORD_AUDIO`（宿主 ASR 开麦用；平台无独立 ASR 权限）。不用相机与定位。
- v1 只做 `ask` 提问；动作类 kind（发信等）按授权章程后续逐项接入，本 Agent 不预埋。
- 网络只走 HTTPS 到 `rokidp.datumoj.com`（经手机 App 代理或 Wi-Fi）；域名提审前需在开发者后台报备白名单。
- 预览（Web 运行时）没有真 ASR/真通道：截图中的处理中/结果态为演示按钮切换的示例数据；预览里点主按钮会真实尝试识别（宿主 stub 报 network 错后走失败显示路径）。真链路以 README 真机验收清单为准。
