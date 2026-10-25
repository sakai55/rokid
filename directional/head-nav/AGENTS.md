# head-nav

Rokid 眼镜头向导航智能体（AIUI Agent）。

## 身份

一个运行在 Rokid 眼镜上的步行方向罗盘，解决看手机导航要低头走路、
东南西北分不清的问题。它不报方位角术语，而是把目标方向换算成
相对你头部朝向的方向：视线里一个大箭头加「左前方 35°」式提示，
转头/转身让箭头指向上方，就能往前走。

## 能力

- 头部朝向：AbsoluteOrientationSensor（约 5Hz）读取四元数
  [x, y, z, w]，由 yaw 公式算出朝向角；界面如实标注来源
  SENSOR / DEMO / NONE，传感器不可用时不假装有朝向。
- 定位与目标：START 用 navigator.geolocation 取一次定位；目标是
  内置演示点位（车站 / 便利店 / 公园 / 家），以「相对当前定位的
  经纬度小偏移」表达，所以在任何地点都能算出方位与距离
  （Haversine 距离 + 初始方位角公式）。
- 相对方位指引（核心）：相对角 = 目标方位角 − 头部朝向，归一化到
  −180°…180°；显示 8 向箭头（↑↗→↘↓↙←↖）与方向词
  FRONT / RIGHT-FRONT / RIGHT / RIGHT-BACK / BACK / LEFT-BACK /
  LEFT / LEFT-FRONT + 度数；|相对角| ≤ 15° 时高亮
  「ON COURSE — WALK STRAIGHT」。永远不报东南西北。
- 凝视确认：开启世界感知（enableWorldAwareness），显示头部稳定
  状态（HEAD STEADY）；点头（onHeadGesture nod）= 重新定位并重算。
- 朗读：SPEAK 用 speechSynthesis 念相对方位中文句，如
  「车站在你左前方 35 度，约 420 米」，由实时计算值生成；
  ON COURSE 时念「就在你正前方，一直往前走」。
- DEMO：无 GPS 时的仿真模式——原点固定在标注了 DEMO 的演示坐标，
  朝向从 0° 起、每点一次 DEMO +45°，可在预览里看到箭头旋转并
  转到 ON COURSE；所有演示值在界面上标 DEMO。
- 目标切换：DEST 按钮或 ArrowUp / ArrowDown 键循环四个目标；
  Enter / GlobalHook = 重新定位；Backspace 由宿主处理返回。

## 行为边界

- 这是方向罗盘，不是逐向道路导航：运行时没有地图/路径规划服务，
  目标是内置演示偏移点，不能替代真实导航软件的路线与路口提示。
- 定位只在用户点 START / UPDATE、点头或按 Enter 时请求
  （getCurrentPosition 单次取位，不开 watch）；权限被拒或主机无
  定位时显示 FAIL 并写明错误码，不假装定位成功。
- 传感器缺失时朝向来源标 NONE 并提示用 DEMO，不编造朝向数值；
  演示模式下所有数值都是仿真值，界面与文案如实标注 DEMO。
- 页面隐藏/卸载时停传感器、清定时器、清定位 watch（若曾开启），
  不在后台持续读取朝向或位置。
- 不上传、不保存位置与朝向数据，全部计算在本机当场完成。
