# plant-doctor

Rokid 眼镜植物医生智能体（AIUI Agent）。

## 身份

一个运行在 Rokid 眼镜上的盆栽护理向导，解决植物蔫了不知道出了什么
问题、该不该浇水的问题。看着植物拍一张照（只作记录），用按钮/按键
选出你眼睛看到的症状，眼镜给出最可能的原因和一步一步的护理计划，
计划用语音一步步念，点头就进下一步——浇水、修剪时双手不用停。

## 能力

- 凝视确认：开启世界感知（enableWorldAwareness），头部稳定
  （onOrientationStabilityChange stable）后显示「HEAD STEADY」；
  点头（onHeadGesture nod）：没有计划时触发 LOOK 拍照，计划进行中
  则推进一步——用点头代替腾手点按钮。
- 看向拍照（只作记录）：getUserMedia({video:true}) 取流后用
  ImageCapture.takePhoto({mode:'default'}) 拍下眼前的植物，界面
  显示照片字节数；ImageCapture 不可用时回退 wx.media
  CameraContext。照片不参与诊断，界面如实标注。
- 症状选择：SYMPTOM 按钮或 ArrowUp / ArrowDown 在 5 个可见症状间
  切换：叶子发黄 / 叶子蔫垂 / 叶面斑点 / 有虫 / 只长叶不开花。
- 护理计划：CHECK 先尝试 LanguageModel 生成该症状的简短原因 +
  3-4 步计划（解析成功才采用，并标注来源 LLM）；不可用或解析
  失败时用内置专家表（每症状：可能原因一句 + 4 个具体步骤 +
  收尾复查语），标注来源 built-in guide。NEXT / 点头逐步推进，
  最后一步后显示该症状的复查收尾语。
- 朗读：SPEAK 用 speechSynthesis.speak 朗读当前步骤（无计划时
  朗读所选症状的可能原因）。
- 浇水速判：WATER 轮换土壤状态（干透 / 微潮 / 很湿），给出浇 /
  等 / 禁浇的建议行。
- DEMO：直接载入「叶子发黄」症状的内置计划并进入步骤视图，
  方便在没有相机/大模型的预览环境里看到计划运行态。

## 行为边界

- 诊断是「按症状给护理建议」，不是照片识别：本 Agent 不把照片
  送模型（产品选择；平台支持照片经 data: URL 以 image_url 送入
  大模型，本 Agent 不用这条路径），所以本 Agent 绝不声称从照片
  认出了植物种类或病害；界面、代码注释与 README 都如实标注
  「symptom-based guidance, not photo identification」。
- 相机只在用户点 LOOK、点头或按 Enter 时启动，拍完立即停掉
  全部媒体轨道；大模型会话用完即 destroy；页面卸载时同样清理。
- 主机没有相机时 LOOK 显示 FAIL 并写明原因，不伪造照片；
  大模型不可用时如实回退内置表并标注来源。
- 护理建议是家庭园艺常识级指导，植物持续恶化请咨询专业园艺师，
  本 Agent 不替代专业判断。
- 不上传照片，不保存拍摄内容；照片只取字节数用于状态显示。
