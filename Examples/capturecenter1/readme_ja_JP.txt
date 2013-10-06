このサンプルプログラムは，SCCToolKitのCap::CaptureCenterとQCvGLWidgetクラスを利用した最小限の動作をするサンプルプログラムです．

以下の動作をしています．
 - １個のDeckLinkデバイスをオープンして，
 - デフォルト設定でキャプチャを開始して，
 - QCvGLWidgetのビュー１個のウィンドウに表示する．

プログラムでは，Cap::CaptureCenterを継承するクラスのなかで，Cap::CaptureCenter::imagesArrived()をオーバーライドして，ここでビューの再描画を行っています．

このクラス関数はメインスレッド以外から呼ばれる可能性があります．Qtの描画はメインスレッドで行うべきなので，libdispatchの関数を使っています．

エラーチェックを一切していないので，ウィンドウが開けないなどの異常時にはハングアップします．DeckLinkを使うためのドライバがインストールされていない場合は，Cap::CaptureCenter::addCapture()の返り値で検出できます．

このプログラムの（そしてSCCToolKitの）最大の特徴は，「デバイスが未接続，ビデオ信号が来ない等の場合はエラーではない」ことです．その場合は，myCaptureCenter::imagesArrived()が呼ばれないだけで，正しい入力が来るまで静かに待ちます．