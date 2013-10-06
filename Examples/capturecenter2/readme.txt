This sample program opens two camera devices, one Decklink, one USB camera via QtKit using Cap::CaptureCenter classes. To display, it uses OpenCV's HighGUI windows.

It works as following;
 - Open a DeckLink and QtKit devices,
 - Configure it using the default setting and start capturing,
 - Draw the arriving frame to OpenCV windows.

The program has a derived class of Cap::CaptureCenter. The class overrides Cap::CaptureCenter::imagesArrived() to get the frame and draw it, and Cap::CaptureCenter::stateChanged() to give the status change of the cameras.

You can see the various state messages by plug in/out the cameras.

We measured the latency from capture to display.
Methods: The camera was a USB cam (Elecom UCAM-DLY300TA), on MacBook Air mid 11 with window size 640x480. We took a few photos of a digital stop watch together with the displayed image through the USB cam. The stop watch had digits of 0.01 sec. As control, we used cv::VideoCapture in capture_cv2 sample program.
Results:
Cap::CaptureCenter: 100-130 msec.
cv::VideoCapture  : 130-170 msec.
Conclusion: Cap::CaptureCenter is 1 frame faster.
