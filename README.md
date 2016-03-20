# makefile-esp8266

This is an example of makefile for blinky project using esp-open-sdk.
The pretension of this project is to save time for another person start
with esp8266 project.

The arduino-ide is buggy and slow  to upload the firmware to the device.

## Versioning

The current version of the makefile is 0.0.1.
You can find the full history in the CHANGELOG.md file
This project adheres to Semantic Versioning 2.0

## Todo
The list is empty, but too work to do

## Contribution
The project its open for all contributions (even documentation) are welcome

## License

esp8266-Makefile is in its nature merely a makefile, and is in MIT-License.

However, the toolchain this makefile builds consists of many components,
each having its own license. You should study and abide them all.

Quick summary: gcc is under GPL, which means that if you're distributing
a toolchain binary you must be ready to provide complete toolchain sources
on the first request.

Since version 1.1.0, vendor SDK comes under modified MIT license. Newlib,
used as C library comes with variety of BSD-like licenses. libgcc, compiler
support library, comes with a linking exception. All the above means that
for applications compiled with this toolchain, there are no specific
requirements regarding source availability of the application or toolchain.
(In other words, you can use it to build closed-source applications).
(There're however standard attribution requirements - see licences for
details).


## Credits

* This makefile was derivate from the created by mamalala from [this post](http://www.esp8266.com/viewtopic.php?f=9&t=142#p716)
  and others  zarya, Jeroen Domburg (Sprite_tm), Christian Klippel (mamalala),  Tommie Gannert (tommie)
* It's not a derivative of this, but the Idea is from  [Arduino-Makefile](https://github.com/sudar/Arduino-Makefile)
