# shelf-compare

Rokid 眼镜看货比价智能体（AIUI Agent）。

## 身份

一个运行在 Rokid 眼镜上的超市比价工具，解决同类商品看花眼、价格/规格/
单位价记不住没法比的问题。看着货架上的商品扫条码，一个个加进对比表，
眼镜自动算单位价、标出最划算的一件，并把结论朗读出来。

## 能力

- 凝视确认：开启世界感知（enableWorldAwareness），头部稳定
  （onOrientationStabilityChange stable）后才进入可扫状态，显示
  「HEAD STEADY」；点头（onHeadGesture nod）在没有待确认项时触发扫码，
  有待确认项时确认加入对比表；清空表格用 CLEAR 按钮。
- 宽幅扫码：getUserMedia({video:true}) 取流后用
  ImageCapture.takePhoto({mode:'wide'}) 拍货架商品条码（media 文档注明
  wide 模式用于条码扫描），再用 BarcodeDetector.detect 解出码值；
  ImageCapture 不可用时回退 wx.media CameraContext 拍照，并按文档要求
  把返回的编码数据连同 mimeType 包成 Blob 再做条码检测。
- 商品解析：内置演示目录按条码（EAN-13）查约 10 件常见商品（名称、
  价格、规格）；查不到的码如实以「Unknown item + 原始码值」加入，
  无价格/规格，不参与单位价比较。
- 对比表：最多 4 行，每行显示价格、规格与算出的单位价
  （每 100g / 100ml）；单位价最低的一行标 BEST，并给出一行结论
  （VERDICT）。REMOVE 删最后一行，CLEAR 清空。
- 朗读：speechSynthesis.speak 把结论读出来（SPEAK 按钮）。
- DEMO：依次取内置演示商品（四种牛奶，单位价可直接对比）作为
  待确认项，方便在没有相机的预览环境里看到装满的对比表。

## 行为边界

- 相机只在用户点 SCAN、点头确认或按 Enter 时启动，拍完立即停掉全部
  媒体轨道；页面卸载时同样清理。
- 主机没有相机或没有 BarcodeDetector 时，SCAN 显示 FAIL 并写明原因，
  不假装扫到；预览主机上 SCAN 走的就是这条诚实失败路径。
- 内置目录是演示数据（价格/规格为示例值），界面与 README 均如实标注，
  不是实时商超数据。
- 不上传照片，不保存拍摄内容；照片只用于当场解码条码。
