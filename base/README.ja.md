# 基本項目（base/）

[中文](README.md) | [English](README.en.md) | 日本語
中国語版（2026-10-29 時点）の翻訳。

どのシリーズにも属さない置き場。my-agent は公式スキャフォールドのサンプル、glasses-benchmark は全機能ベンチマークの自己点検、stream-probe は連続動画ストリームのプローブ、storage-probe はローカルストレージのプローブ、qr-capacity-probe は二次元コード容量のプローブ、dabiaoge は汎用メッセージチャネルの眼鏡側クライアント。

- [my-agent](my-agent/) — 公式スキャフォールドのサンプル。タップで中国語と英語の挨拶を切り替える
- [glasses-benchmark](glasses-benchmark/) — 眼鏡の全機能を自己点検。21項目を1回で実行して結果を出す
- [stream-probe](stream-probe/) — 連続動画ストリームのプローブ。ストリームのフレーム取得率、録画のデータ率、フレームを大規模モデルへ送る際の遅延を測る
- [storage-probe](storage-probe/) — ローカルストレージのプローブ。3つの保存領域の往復・容量・クォータを実測する
- [qr-capacity-probe](qr-capacity-probe/) — 二次元コード容量プローブ。4 段階の誤り訂正レベルごとに、テキストの符号化と読み戻しデコードの容量境界を実測する
- [dabiaoge](dabiaoge/) — dabiaoge：汎用メッセージトンネルの眼鏡側クライアント。声で質問すると画面に答えが出る

全リストはルートの [README](../README.md) 末尾にある Agent リストを参照。
