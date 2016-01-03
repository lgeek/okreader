okreader
========

Free/libre firmware for Kobo ebook readers. No proprietary software (except firmware for the WiFi adapter), no spyware and no DRM. Based on [koreader](https://github.com/koreader/koreader) and [Debian](https://www.debian.org/).


Supported hardware
------------------

Tested on:
* Kobo Touch
* Kobo Aura

okreader is also expected to work on Kobo Glo out of the box.

There seem to be multiple hardware revisions with different WiFi adapters. The *firmware-okreader* package only provides the required firmware for the adapters in the devices I've tested.


Usage
-----

Note: The build system is intended to run on Debian or Ubuntu, on ARM. Cross-building should also be possible with little effort, but it's not implemented. If you don't have access to an ARM system, you could try using [QEMU](http://qemu.org).

Fetch all resources:

    git clone https://github.com/lgeek/okreader.git
    cd okreader
    git submodule init
    git submodule update
    ./fetch.sh all
    
Build all packages:

    ./build.sh all
    
...or, alternatively, one at a time:

    ./build.sh linux-image
    ./build.sh linux-modules
    ./build.sh firmware-okreader
    ./build.sh koreader
    
Prepare a Debian rootfs:

    ./build_rootfs.sh
    

Installation on the device
--------------------------

To be documented...

