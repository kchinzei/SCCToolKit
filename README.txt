This directory contains SCCToolKit and a few applications that uses SCCToolKit.
http://scc.pj.aist.go.jp

Directory Contents
------------------
The root directory, SCCToolKit, can be placed at any place where convenient for you. In the root directory,
 - Apps : Some application programs that uses SCCToolKit. Each directory in Apps are 'independent' so that you can put it at any place, or remove.
 - The rest of Directories and files in the root directory are the part of SCCToolKit. Do not move, rename or replace them. The CMakeLists.txt file build the library and the example programs.


Prerequisite
--------------
Currently, SCCToolKit is supported only on Mac OSX 10.7 or higher. [MaxOS 10.12 has issues now].
(We plan to extend to Windows.)
In addition, you need the followings being installed.
- XCode.app from apple.com
- Qt 4.8.7 or Qt 5.6 (long term support). We tested on Qt 5.8.
- OpenCV 2.4 or higher. You may need to build it before you build SCCToolKit.
- Blackmagic Design's Decklink SDK. We tested on 9.6.9 or later, but should work from 9.0. (This SDK is necessary to link everything. But you can run the most of examples without the Decklink hardware.)


Build it
--------------
1. Do "cd" to the root directory, SCCToolKit.
2. Do "mkdir build ; cd bold".
3. Run "ccmake ..". If you want Xcode to do debug, do "ccmake -GXcode .."
4. Type 'c' once. ccmake will ask you where's your Qt, OpenCV, and DeckLink SDK.
5. After ccmake successfully identifies these, you type a few more 'c' and you can finish ccmake by typing 'g'.
6. Run "make". This will build the library and sample programs in Examples.
   If everything goes fine, you get "make" complete with "100% done".
7. Play with the examples.

To build application programs in Apps, you need to do similar to the above process. For example,
8. Do "cd" to "Apps/chromakey".
9. Do "mkdir build ; cd build"
10. Run "ccmake .."
11. Type 'c' once. This case, you need to tell ccmake where is SCCToolKitConfig.cmake file, which is "../../build" in above example.
12. After finding SCCToolKitConfig.cmake and do some customization, type 'c' a few more and if you are satisfied to your setting, type 'g'.
13. Run "make".