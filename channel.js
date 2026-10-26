// dabiaoge configuration - the ONLY place deployment-specific values
// live. The page code contains no hardcoded domain or key, so anyone
// can run this agent against their own rokidpost front door by editing
// just this file.
//
// BASE_URL: the COMPLETE URL of the rokidpost front door (Cloudflare
//   Worker) - including the https:// protocol, with NO trailing slash
//   and NO path (the code appends /submit and /ticket/<id> itself).
//   The value below is the default public front door. If you deploy
//   your own front door (see the rokidpost repo), replace it with your
//   own Worker address, in the same complete-URL form.
// CHANNEL_KEY: the glasses-side key of YOUR front door. The repo
//   stores a placeholder only. Before packaging, open this file in
//   Global AIUI Studio and replace the placeholder with the real key,
//   then package. Never push the filled file back to GitHub, and refill
//   after every fresh GitHub import (imports are snapshots).
// Steps: README section "打包前必做：填配置（域名 + 钥匙）".
export const BASE_URL = "https://post.rokid";
export const CHANNEL_KEY = "PASTE_CHANNEL_KEY_HERE";
