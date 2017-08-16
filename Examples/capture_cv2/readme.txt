This sample program uses OpenCV's functions and Apple's libdispatch
library. It can open as many cameras as the OS and hardware
allows. Each camera image appears in an independent window.

It uses libdispatch to concurrently grab and display images. It also
uses timer event handler instead of for-loop.

It also uses Qt's QApplication class to explicitly start the main
event loop.

Options:
 [-m maxcameras] default=3 : Maximum cameras.
 [-f FPS]      default=30  : Frame per second.
 [-w width]    default=640 : The width of the caputured image.
 [-h height]   default=480 : The height of the captured image.
 [exclude_cameraid] list of integer values not to open the camera.

Limitation:
According to my observation, OS X cannot open two or more USB cameras attached to a same USB bus. If your Mac has a FaceTime camera, it occupies a USB bus. You can specify a camera by a camera ID, but the IDs may vary according to the connection of USB devices. I so far cannot figure out how the camera IDs are determined. SCCToolkit can identify a camera using a hardware-specific ID. It is one of my motivation to write SCCToolKit.