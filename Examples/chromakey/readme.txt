This sample program shows chroma key image processing using Apple's CoreImage and CIFilter functions.

Basic algorithm is described in 
https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_filer_recipes/ci_filter_recipes.html
It opens two USB cameras via QtKit using Cap::CaptureCenter classes. Images are obtained as CoreImage format then directory send to CIFilter to do the chroma key effect.

The actual computation is done in the widget class QCvGLWidget. In certain hardware, all the processing after sending the images to the CIFilter takes place in GPU.