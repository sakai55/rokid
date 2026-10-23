# parking-return

Rokid 眼镜找车方位智能体（AIUI Agent）。

## 身份

一个运行在 Rokid 眼镜上的「停车方位记忆 + 找车罗盘」，解决在大型
停车场/地下车库回来时找不到自己车的问题。停车下车时点一下，
眼镜把三样东西绑在一起存好：当时的 GPS 定位、你车头的朝向
（下车面对的方向）、你选的区域（B1/B2/B3/地面/路边）。回来时
跟着相对你头部朝向的箭头和距离走；走到约 25 米内，它不再硬报
角度，而是亮出当初存下的区域与车头朝向当线索，让你抬头找车。

## 能力

- 停车存点（PARK 模式）：ZONE 轮换区域备注（B1 / B2 / B3 /
  地面 / 路边）；PARK（或头部稳定时点头、Enter）取一次
  `navigator.geolocation` 定位，并读当时的头部朝向
  （AbsoluteOrientationSensor 四元数 yaw，来源如实标注
  SENSOR / DEMO / NONE），把 {lat, lon, hasFix, accuracy,
  headingDeg, zone, time} 存入 wx 同步存储（key `parkingSpot`，
  只存一条，重新 PARK 覆盖）。
- 无定位也存（诚实降级）：地下车库常没有 GPS——定位失败时
  记录照样保存，位置标记为「no fix」，只保留区域 + 车头朝向 +
  时间；RETURN 时直接进入 NEAR 态用这些线索找车，绝不编造
  一个定位出来。朝向传感器缺失时 headingDeg 存为未记录，
  界面如实显示，不编造角度。
- 返回指引（RETURN 模式，核心数学同 head-nav / meet-point）：
  UPDATE（或 Enter / 稳定时点头）取一次新定位，Haversine 算
  到停车点的距离、初始方位角算方位，相对角 = 停车点方位 −
  当前头部朝向，归一化 −180°…180°；显示 8 向箭头与
  「CAR: LEFT-FRONT 40° · 132 m」；|相对角| ≤ 15° 高亮
  「ON COURSE — walk straight」。永远不报东南西北。
- NEAR 态：距离 < 25 米（GPS 噪声已大过方向意义）或记录
  本身无定位时，箭头换成 ◎ 并显示「NEAR — look for your car」，
  同时亮出线索行「区域 B2 · 车头当时朝 140° · 14:20 停好」，
  最后一步靠眼睛找。
- 车牌区域拍照（PLATE）：NEAR 后点 PLATE，用
  `getUserMedia` + `ImageCapture.takePhoto({mode:'telephoto'})`
  长焦拍一张车牌区域的照片当视觉记录（不可用时回退 wx
  CameraContext），界面只显示字节数并明确标注「photo record
  only — compare with your eyes (NO OCR)」：运行时没有 OCR，
  不读车牌、不声称识别。
- 取回清记录（FOUND）：找到车点 FOUND，清掉存储的记录
  （界面回「车已取回」），下次停车重新 PARK。
- 朗读：SPEAK 用 speechSynthesis 念中文指引，由实时计算值
  生成：「车在你左前方 40 度，约 132 米」／ON COURSE 时
  「车就在你正前方，一直往前走」／NEAR 时念区域+车头朝向线索。
- DEMO：点 DEMO 存一条标注 DEMO 的演示停车记录（演示原点
  +0.0010, +0.0005，约 120 米，区域 B2、车头 140°）并切到
  RETURN，朝向从 0° 起每点一次 +45°；满一圈（8 次）后演示
  记录切换为近处变体（约 15 米）进入 NEAR 态，再满一圈切回。
  演示记录只在内存中，绝不覆盖已存储的真实记录。
- 模式与按键：MODE 在 PARK / RETURN 间切换；无记录时默认
  PARK，有记录时默认 RETURN；ArrowUp/Down 在 PARK 时轮换
  区域、在 RETURN 时重新定位；页面卸载时把真实记录落盘。

## 行为边界

- 定位只在用户点 PARK / UPDATE、点头或按 Enter 时单次请求
  （getCurrentPosition，不开 watch）；相机只在点 PLATE 时
  启动，拍完立即停掉全部媒体轨道；页面隐藏/卸载时停传感器、
  清定时器、停媒体轨道。
- 地下车库无 GPS 是常态而不是错误：本 Agent 如实标记 no fix
  并降级为区域 + 车头朝向线索，不假装定位成功、不编造坐标、
  朝向或车牌文字。
- 箭头指直线方向，不是停车场内的道路导航：楼层之间、墙体
  阻隔请自行绕行；跨楼层时区域备注（B1/B2/B3）就是为此存的。
- 记录只存本机 wx 同步存储，不上传；DEMO 记录不落盘。
- 真机朝向精度、GPS 精度、长焦拍照效果未验证（见 README）。
