This sample program is a minimal runnable sample using SCCToolKit's Cap::CaptureCenter and QCvGLWidget classes.

It works as following;
 - Open a DeckLink device,
 - Configure it using the default setting and start capturing,
 - Draw the arriving frame to the QCvGLWidget view.

The program has a derived class of Cap::CaptureCenter. The class overrides Cap::CaptureCenter::imagesArrived() to get the frame and draw it.

This function may be called from other that the main thread. Since Qt requires drawing is done in the main thread, we use a libdispatch function.

There is no error check. When there is some error such as fail t o open a window, it will hang. When DekcLink driver is not installed, you can detect it by checking the return value of Cap::CaptureCenter::addCapture().

One of biggest point of this sample program (and that of SCCToolKit) is, the situation like device unconnected, video signal not available, is not an error. It silently waits until the correct frame arrives.