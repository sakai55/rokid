# expiry-check

Rokid 眼镜临期检查智能体（AIUI Agent）。

## 身份

一个运行在 Rokid 眼镜上的食品临期守卫，解决冰箱/囤货食品放到过期才
发现的问题。看着包装，用长焦拍下日期区域，日期由用户语音/步进器
确认（运行时没有 OCR，绝不假装读出），眼镜自动算剩余天数、维护一份
按紧急程度排序的临期清单，3 天内到期的出声警告。

## 能力

- 凝视确认：开启世界感知（enableWorldAwareness），头部稳定
  （onOrientationStabilityChange stable）后才进入可用状态，显示
  「HEAD STEADY」；点头（onHeadGesture nod）第一次触发 LOOK 拍照、
  拍照后再次点头确认 ADD 入清单 — 用点头代替腾手点按钮。
- 长焦拍照：getUserMedia({video:true}) 取流后用
  ImageCapture.takePhoto({mode:'telephoto'}) 拍包装上的日期区域，
  界面显示照片字节数；ImageCapture 不可用时回退 wx.media
  CameraContext。照片只作日期区域的影像记录，日期不从照片读取。
- 日期确认（用户确认，非 OCR）：日期步进器显示年/月/日，FIELD 按钮
  切换聚焦字段，ArrowUp / ArrowDown 调整（默认今天）；物品名点
  NAME 用 SpeechRecognition（zh-CN）说出，不可用时如实提示并轮换
  内置名称（牛奶/鸡蛋/酸奶/面包/剩菜）。
- 临期清单：最多 6 项，按到期日升序排列，自动算剩余天数；
  ≤3 天标「!」高亮，过期标「EXPIRED」；清单用 wx.setStorageSync
  持久化（key `expiryWatchlist`），关掉重开还在。REMOVE 删除最紧急
  的一项，CLEAR 清空。
- 语音警告：SPEAK 用 speechSynthesis.speak 朗读由真实清单生成的
  临期摘要（如「临期提醒：2 项在 3 天内到期。牛奶明天到期……」）。
- DEMO：依次加入内置样例食品（到期偏移 +1/+2/+5/0/-1/+9 天轮换，
  名称带「(样例)」标注），方便在没有相机/麦克风的预览环境里看到
  排序后的清单与紧急标记。

## 行为边界

- 运行时没有 OCR 接口：日期一律是用户确认的，界面、代码注释与
  README 都如实标注「user-confirmed, no OCR」，绝不声称从照片
  读出了日期。
- 相机/麦克风只在用户点 LOOK / NAME、点头或按 Enter 时启动，
  拍完立即停掉全部媒体轨道，识别器在页面卸载时 abort，清单
  在卸载时落盘。
- 主机没有相机时 LOOK 显示 FAIL 并写明原因；没有
  SpeechRecognition 时 NAME 如实提示并回退内置名称轮换，
  不伪造识别结果。
- 不上传照片，不保存拍摄内容；照片只取字节数用于状态显示。
- 剩余天数按本机日期计算；样例数据为内置演示值，名称带
  「(样例)」标注，不冒充真实记录。
