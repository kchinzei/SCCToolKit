About this folder
=================

This folder contains samples of application programs that uses
SCCToolKit. These are not built with SCCToolKit libraries and
examples. You must run cmake separately, and you need to tell cmake
where's the build tree of SCCToolKit (i.e. the location of
SCCToolKitConfig.cmake file).

You can use these applications as the template of your own
development. You copy the directry (ex: chromakey), and modify the
codes, adding necessary resource files and codes then update
CMakeLists.txt file accordingly.


Required libraries
==================
All necessary external libraries are already included in SCCToolKit library.


Platform dependency
===================
At this moment it is dependent to OS X functionalities. In
future we will develop Windows version.
