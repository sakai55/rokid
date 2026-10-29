// config.js —— 真境探针的唯一部署配置（照大表哥 channel.js 的成例：
// domain + key 两件都在同一个配置文件里，不要只配 key）。
//
// BASE_URL：日志回传前门地址。完整 URL：带 https://、末尾不带斜杠、
// 不带路径。默认值 = AV11 日志试点实际用的 rokidpost 前门
// （av/stop-motion-studio/logq.js 的 LOG_URL 去掉 /log 路径段）。
// 用默认前门时这一项可以不改。
//
// CHANNEL_KEY：前门的眼镜侧钥匙。仓库里只存占位符
// PASTE_CHANNEL_KEY_HERE；真钥只在 Studio 导入后就地填入，永不回推
// 仓库，Muse 不持有真钥。每次重新导入工程都要重填（见 README
// 「打包前必做」）。
//
// 启用条件：CHANNEL_KEY 不是占位符 且 BASE_URL 非空，两件齐 logq
// 才发；缺任一件 = 完全 no-op 静默，不报错、不影响探针任何功能。

export var BASE_URL = 'https://rokidp.datumoj.com';
export var CHANNEL_KEY = 'PASTE_CHANNEL_KEY_HERE';
