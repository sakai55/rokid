<script def>
{
  "title": "Probe About"
}
</script>

<script setup>
import { VER } from '../../probe.js';

export default {
  data: {
    evt: 'EVT: about',
    ver: 'v' + VER
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">说明与已知边界</text>
    <text class="ln">本探针实测三套本地存储：官方没公布的数字，以实测为准。</text>
    <text class="hd">三套存储（互相独立 · 按 Agent 隔离 · 全在本地）</text>
    <text class="ln">· localStorage：字符串键值，值只能是字符串</text>
    <text class="ln">· wx 存储：数据须 JSON 可序列化，同步/异步两组口</text>
    <text class="ln">· OPFS：navigator.storage 文件存储，大块数据用</text>
    <text class="hd">已知边界（官方口径）</text>
    <text class="ln">· 三套都没有公布配额数字；OPFS 配额只能运行时用</text>
    <text class="ln">　estimate() 查，各机/各版本可能不同</text>
    <text class="ln">· 三套都没有过期 / TTL 机制的记载：存了就一直在，</text>
    <text class="ln">　直到自己删或用户清应用数据；官方也没承诺永不</text>
    <text class="ln">　回收（OPFS 有 persist() 申请持久化）</text>
    <text class="ln">· localStorage 存对象会变 '[object Object]'，须先序列化</text>
    <text class="ln">· OPFS 是实用子集；宿主无后端时 NotSupportedError</text>
    <text class="hd">测法</text>
    <text class="ln">往返校验 + 32 KiB 步进爬坡（上限 16 MiB）；OPFS 按</text>
    <text class="ln">1 MiB 写文件读回核对。测后只删 sprobe.* 自有键与</text>
    <text class="ln">目录，从不清空全部存储。容量按载荷字符数计。</text>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 8px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 16px; font-weight: 500; }
.hd { color: #000000; background-color: #40ff5e; font-size: 12px; font-weight: 500; padding: 1px 6px; margin-top: 7px; }
.ln { color: #7dff9e; font-size: 12.5px; line-height: 17px; margin-top: 1px; }
.footrow { display: flex; flex-direction: row; margin-top: 6px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
