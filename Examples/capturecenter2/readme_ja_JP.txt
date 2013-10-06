このサンプルプログラムは，Cap::CaptureCenter classesを使って１つのDecklinkデバイス，１つのUSBカメラをオープンして，OpenCVのHighGUIウィンドウに表示します．

次のように動作します．
 - DeckLinkとQtKitのカメラを開き，
 - これらをデフォルトセッティングで設定し，キャプチャを開始します，
 - 届いたフレームをOpenCVのウィンドウに描画します．

このプログラムでは，Cap::CaptureCenterを継承したクラスで以下をオーバーライドしています．
 Cap::CaptureCenter::imagesArrived()でフレームを受け取って表示して，
 Cap::CaptureCenter::stateChanged()でカメラの状態変化に関するログを表示

カメラを抜き差しして，ログがどうなるかを試してみてください．

USBカメラ（Elecom UCAM-DLY300TA）１個だけの場合，カメラから表示まで100-130 msecであった（MacBookAir  (Mid11), 640x480）．cv::VideoCaptureを使う場合130-170 msecであったので，１フレーム改善．
