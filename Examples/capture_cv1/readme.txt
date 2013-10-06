This sample program uses OpenCV's functions only. This is a demo of
how 'traditional' OpenCV program works. It opens a camera and displays
image in a window. It uses a for-loop to continuously capture and
update the view. Compare this with capture_cv2, which is timer driven
and programmed in concurrent way.

Options:
 [-w width]    default=320 : The width of the caputured image.
 [-h height]   default=240 : The height of the captured image.
 [-f FPS]      default=30  : Frame per second, but it has no effect.
 [cameraid]    default=0   : Specify which camera to open.


