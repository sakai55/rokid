# Rokid Glasses ローカルストレージガイド

[中文](STORAGE.md) | [English](STORAGE.en.md) | 日本語

本書は中文版 v1.0.0（2026-10-30）に対応する日本語版である。内容に食い違いがある場合は中文版を正とする。

> 作成：2026-10-30／現行バージョン v1.0.0（2026-10-30）
> 資料の方針：**出典は Rokid 公式に限る**（公式ドキュメントサイト、公式 GitHub リポジトリ `yodaos-project/AIUI` および同梱の `aiui-dev` スキルリファレンス）。公式が公表していない数値は、その旨を「未公表」と明記し、他プラットフォームの数値で代用しない。

## はじめに

本書は Rokid AIUI の開発者が個人的に保守しているガイドであり、Rokid の公式ドキュメントではない。Agent が使えるローカルストレージについて――何種類あり、それぞれ何を保存するのに向いていて、どう書けばよく、どこに限界があるのか――をまとめた。

まず全体像から。Agent のローカルストレージは `localStorage`、wx ストレージ、OPFS ファイルストレージの 3 系統ある。いずれもグラス本体に保存され、Agent ごとに隔離されていて、互いに読み書きはできない。プラットフォームは Agent 向けのクラウドストレージを用意していない。データがスマートフォンやクラウドに同期されることはなく、ユーザーがアプリデータを消去したりアンインストールしたりすれば、保存データも一緒に消える。デバイスをまたいで保存したければ、バックエンドを自前で用意するしかない。

## 1. 3 つのストレージの概要

なぜ 3 系統もあるのか。同じ機能の複製ではなく、由来がそれぞれ違うからである。

- **localStorage は Web の系統**。ランタイムの Ink は Web スタイルのコンテナで、fetch、WebSocket、Streams といった Web のインターフェースを備えている。localStorage は Web 標準のキーバリュー保存としてコンテナに付随するもので、公式の Web API リファレンスで「文字列のキーバリュー、同期読み書き」と定義されている。
- **wx ストレージはミニプログラムの系統**。プラットフォームは WeChat ミニプログラム互換のインターフェース一式を取り込んでおり、wx ストレージはその一つ。公式の「ストレージ」ガイドが扱うのはこの系統だけで、位置づけは「ローカルデータのキャッシュ。ユーザー設定、ページの状態、業務キャッシュなど、JSON にシリアライズ可能なデータの保存に向く」とされている。公式ドキュメントの上では、プラットフォームの正式なストレージ機能はこちらである。
- **OPFS はファイルの系統**。キーバリューでは大きなバイナリを収められないため、ファイルという層を OPFS が補う。公式の OPFS 専用ページでは「ファイル、バイナリリソース、オフラインキャッシュ、そして単純なキーバリューでは収まらない容量の永続データを保存するもの」と位置づけられている。

公式が 3 系統を比較した文書はなく、どれかがどれかを置き換えると宣言されたこともない。重なるのは小さなキーバリューの領域だけで（localStorage と wx ストレージの両方で保存できる）、分担はデータの形で決まる。キーバリューは前 2 者、ファイルは OPFS、である。

画像を例にすると分担がはっきりする。画像はバイナリであり、localStorage と wx ストレージには直接保存できない。base64 文字列に変換して迂回保存する方法はあるが、容量が約 3 分の 1 増えるうえ、localStorage は同期書き込みのため大きな文字列では画面が固まる。正攻法は OPFS に Blob のまま書き込むことである。なお、写真をシステムのメディアライブラリ（利用者がギャラリーで見られる場所）に保存するのは `CREATE_MEDIA_IMAGES` 権限の経路であり、この 3 系統のプライベートストレージとは別である。

| 系統 | インターフェース | 向いている保存内容 | データの形 |
|---|---|---|---|
| localStorage | `localStorage.getItem / setItem / removeItem / clear` | 小さな設定、フラグ、セッションをまたぐ進捗へのポインタ | 文字列のみ |
| wx ストレージ | `wx.setStorage / getStorage / removeStorage / clearStorage` と同期版 | ユーザー設定、ページの状態、業務キャッシュ、セーブデータ本体 | JSON にシリアライズ可能なデータ |
| OPFS | `navigator.storage.getDirectory()` から始まるファイル API | 大きなファイル、バイナリ、キーバリューでは収まらない容量の内容 | ファイル |

3 系統とも権限は不要である（7 つの権限名のいずれにも該当しない）。`clear` 系のインターフェースが消せるのは自 Agent のストレージだけで、他所には手が届かない。

## 2. localStorage

### 例：進捗データの保存と読み戻し

```javascript
const KEY = 'myagent.progress';

// 保存：对象先序列化，存档带版本号
function saveProgress(progress) {
  try {
    localStorage.setItem(KEY, JSON.stringify({ v: 1, progress }));
  } catch (e) {
    fail('E5001', e); // 记录保存失败
  }
}

// 读回：取不到是 null；解析失败按存档损坏处理
function loadProgress() {
  let raw;
  try {
    raw = localStorage.getItem(KEY);
  } catch (e) {
    fail('E5002', e);
    return null;
  }
  if (raw === null) return null; // 从未存过
  try {
    const data = JSON.parse(raw);
    if (data.v !== 1) { fail('E5004'); return null; } // 存档版本不兼容
    return data.progress;
  } catch (e) {
    fail('E5002', e);
    return null;
  }
}
```

### 制約

- キーも値も強制的に文字列へ変換される。オブジェクトをそのまま渡すと `'[object Object]'` になってしまうので、`JSON.stringify` は自分で行うこと。
- 同期インターフェースであり、呼べばその場で実行される。大きなデータを書き込むとページがブロックされるため、大量データの保存には使わないこと。
- 容量の上限は公表されていない（第 5 節参照）。書き込みがクォータで拒否されると例外が投げられ、エラーコードは E5003。インターフェース自体が存在しない、あるいは無効化されている場合は E5005 である。

## 3. wx ストレージ

公式のストレージガイドで中心になっている系統で、非同期と同期の 2 組のインターフェースがある。

### 例：セーブデータの非同期読み書き

```javascript
// 写入：结果走 success / fail 回调
wx.setStorage({
  key: 'myagent.save',
  data: { v: 1, level: 3, items: ['a', 'b'] },
  fail(res) { fail('E5001', res.errMsg); },
});

// 读回：成功时 res.data 就是写入的对象
wx.getStorage({
  key: 'myagent.save',
  success(res) {
    const save = res.data;
    // 使用 save 前先查 save.v 做版本迁移
  },
  fail(res) { fail('E5002', res.errMsg); },
});

// 同步版：key 不存在时 getStorageSync 返回 undefined
wx.setStorageSync('myagent.theme', { mode: 'dark' });
const theme = wx.getStorageSync('myagent.theme');
```

### 制約

- 保存できるのは JSON にシリアライズ可能なデータだけである。関数、`undefined`、循環参照は保存できない。
- 非同期版は、現在のコンテキストがストレージに対応していることが前提で、対応していなければ呼び出し自体が例外になる。同期版で存在しないキーを読むと、例外ではなく `undefined` が返る。
- キー 1 件あたりのサイズ上限も総量の上限も公表されていない（第 5 節参照）。

## 4. OPFS ファイルストレージ

`navigator.storage` が、現在の Agent 専用のファイルシステム（OPFS）を提供する。他の 2 系統とは独立している。ホスト側に OPFS のバックエンドがない環境では呼び出しが `NotSupportedError` で失敗するため、使う前に存在を確認しておくこと。

### 例：クォータを確認してから大きなファイルを書き、読み戻す

```javascript
async function writeBigFile(bytes) {
  if (!navigator.storage || !navigator.storage.getDirectory) {
    fail('E5005'); // 持久化不可用
    return;
  }
  // 配额是运行时值：写大文件前先查
  const { usage, quota } = await navigator.storage.estimate();
  if (quota && bytes.length > quota - usage) {
    fail('E5003'); // 存储空间不足
    return;
  }
  await navigator.storage.persist(); // 申请持久化（结果是 boolean，不保证批准）

  const root = await navigator.storage.getDirectory();
  const dir = await root.getDirectoryHandle('save', { create: true });
  const file = await dir.getFileHandle('blob.bin', { create: true });
  const writable = await file.createWritable();
  await writable.write(bytes);
  await writable.close(); // close 之后才真正落盘

  const snapshot = await file.getFile(); // 读回校验
  return snapshot.size;
}
```

### 制約

- `estimate()` は現在の使用量とクォータを返すが、クォータの具体的な数値は公表されていない。ホストが実行時に返す値であり、デバイスやバージョンによって異なりうる。
- 現行の実装は実用的なサブセットで、ブラウザの File System Access API の完全な実装ではない。`StorageManager` もハンドル類も、コンストラクタで直接生成することはできない。
- 書き込みはまずバッファに入り、`close()` で確定する。途中で例外が起きた場合の後始末（中途半端なファイルを削除するなど）は自分で行うこと。

## 5. 既知の限界まとめ

- **容量の数値はすべて未公表**。3 系統のいずれについても、項目ごとの上限や総量の上限を公式が示したことはない。WeChat ミニプログラムの「キー 1 件 1 MB、総量 10 MB」や、ブラウザの localStorage でよく言われる数値は、このプラットフォームには当てはまらない。代用してはいけない。
- **有効期限の仕組みはない**。TTL、失効時刻、自動削除のルールは公式のどこにも記されていない。保存したデータは、自分で削除するか、ユーザーがアプリデータを消去するまで残る。逆に、ストレージが回収されることは決してない、という保証も公式にはない。OPFS に `persisted()` の照会と `persist()` の申請という専用のメソッドがあること自体、永続化が「申請して得る状態」であることを示している。
- **すべてローカルで、同期はなし**。3 系統ともネットワークには出ず、スマートフォン側のアプリと同期することもない。デバイスを替えれば、保存データはゼロからになる。
- **隔離は双方向**。他の Agent のストレージは読めないし、ホストアプリ側のデータにも届かない。
- **実測による裏付けはこれから**。実際の容量と OPFS のクォータは、ストレージ探査用の Agent（`base/storage-probe`）で実機計測し、結果を能力レジストリ（`docs/CAPABILITIES.md`）の C6001 から C6003 のエントリへ反映する。本書の数値の扱いはレジストリを正とする。

## 6. 使い分けの早見

- 設定、スイッチ、前回どこまで進んだかといった記録は、wx ストレージでも localStorage でもよい。手に馴染む方で構わない。
- 構造化したセーブデータ（進捗、収集物、履歴）は wx ストレージへ。セーブデータのオブジェクトには、初日から `v` のバージョンフィールドを持たせること。
- 画像、音声、自前で生成した大きなバイナリは OPFS へ。書き込む前に `estimate()` で確認する。
- 前回のセーブの続きから再開する用途なら、どれを使ってもよい。有効期限という関門は仕組み上存在しない。警戒すべきはセーブ形式のバージョンアップの方で、バージョン番号を残し、移行処理を書き、古いセーブで新しいバージョンが読み込みに失敗しないようにすること（エラーコード E5004）。

## 7. 変更履歴

### v1.0.0 2026-10-30

初版。3 系統のストレージについて、概要、書き方の例、既知の限界を、公式のストレージガイドと OPFS 専用ページに基づいてまとめた。容量とクォータの実測値をどう反映するかについては第 5 節に記した。
