okreader
========

Free/libre software stack for Kobo ebook readers. No proprietary software (except WiFi and EPD controller firmware), no spyware and no DRM. Based on [koreader](https://github.com/koreader/koreader) and [Debian](https://www.debian.org/).

WARNING: At this point, okreader has only been tested on a few different devices. Only install it if you know what you're doing. You could brick your ereader and in some countries you might void your warranty.


Features yet to be implemented
------------------------------

This project is at a very early stage. Lack of the following features could be a problem, especially for non-technical users:

* No GUI for enabling and disabling access to the data partition via USB. It is always enabled and it seems to work reliably, but data could get corrupted if both software on the ereader and another computer were to write at the same time. Maintain a backup copy of your data partition.
* No GUI for setting the time & date. The NTP option in koreader is supported, but there is no UI for setting the timezone.


Supported hardware
------------------

I'm testing okreader on:
* Kobo Touch
* Kobo Mini
* Kobo Aura

okreader is also expected to work on other Kobo devices using the i.MX507 SoC, but some additional u-boot and/or kernel patches might be needed (see [this](https://github.com/kobolabs/Kobo-Reader/tree/master/hw) repository). okreader commit #1e7825eb has been confirmed by @dtamas to also work on Kobo Glo. Support for newer devices might be added at a later time. If anyone wants to test / lend or donate any of the untested or unsupported devices, please get in touch at okreader at linux-geek dot org. Also see [this thread](https://github.com/lgeek/okreader/issues/6) for a short description of the steps involved in getting okreader running on an unsupported Kobo device.

There seem to be multiple hardware revisions with different WiFi adapters. The *firmware-okreader* package only provides the firmware for the adapters in the devices I've tested: Kobo Aura, Kobo Touch rev C (N905C) and Kobo Mini.

Comparison of Kobo ereaders:

Device           | eReader | Wi-Fi   | Touch      | Mini       | Glo         | Aura        | Aura HD        | Aura H2O       | Glo HD       | Touch 2.0   | Aura One       | Aura Edition 2 |
-----------------|---------|---------|------------|------------|-------------|-------------|----------------|----------------|--------------|-------------|----------------|----------------|
okreader support | no      | no      | yes        | yes        | yes*        | yes         | kernel upg?    | kernel upg?    | no           | no          | no             | no             |
touchscreen      | no      | no      | yes        | yes        | yes         | yes         | yes            | yes            | yes          | yes         | yes            | yes            |
frontlight       | no      | no      | no         | no         | yes         | yes         | yes            | yes            | yes          | no          | yes            | yes            |
WiFi             | no      | yes     | yes        | yes        | yes         | yes         | yes            | yes            | yes          | yes         | yes            | yes            |
screen           | 6"      | 6"      | 6" 800x600 | 5" 800x600 | 6" 1024x768 | 6" 1024x768 | 6.8" 1440×1080 | 6.8" 1440×1080 | 6" 1448x1072 | 6" 800x600  | 7.8" 1872x1404 | 6" 1024x768    |
SoC              | i.MX357 | i.MX357 | i.MX507    | i.MX507    | i.MX507     | i.MX507     | i.MX507        | i.MX507        | i.MX6 Solo   | i.MX6 Solo? | ?              | ?              |
is current model | no      | no      | no         | no         | no          | no          | no             | yes            | yes          | yes         | yes            | yes            |

\* [commit #1e7825eb tested by @dtamas](https://github.com/lgeek/okreader/issues/1#issuecomment-285626745)

Apart from these specs, the contrast and the ghosting of the electronic ink display also tend to get better in newer models. However, even old models tend to be quite usable. I find a Kobo Touch perfectly readable in moderate to strong ambiental light and a Kobo Aura readable with the frontlight off in strong light or with the frontlight on in dark to moderately lit environments.

If you're looking to buy an ereader for use with okreader, I'd recommend getting a Kobo Touch (£10-£30 used on eBay) if you don't need a frontlight or a Kobo Glo (not tested at the moment) or Aura otherwise.


Usage
-----

Note: The build system is intended to run on Debian or Ubuntu, on ARM. Cross-building should also be possible with little effort, but it's not implemented. If you don't have access to an ARM system, you could try using [QEMU](http://qemu.org).

Install build dependencies:

    sudo apt-get install git build-essential libtool autoconf cmake luarocks zlib1g-dev libffi-dev gettext wget hashalot u-boot-tools debootstrap

Fetch all resources:

    git clone https://github.com/lgeek/okreader.git
    cd okreader
    git submodule init
    git submodule update
    ./fetch.sh all

Build all packages:

    ./build.sh all
    
Note, koreader dependecies require autoconf >= 2.65. You might have to manually specify an autoconf version, for example:

    AUTOCONF=autoconf2.65 ./build.sh all

Build artefacts:

    src/u-boot/u-boot.bin                       # U-Boot (bootloader) image
    src/linux/arch/arm/boot/uImage              # Linux kernel image
    src/firmware-okreader*_armhf.deb            # WiFi firmware
    src/linux-okreader-modules_*_armhf.deb      # Linux kernel modules
    src/koreader_*_armhf.deb                    # koreader
    src/kobo_hwconfig/kobo-hwconfig_*_armhf.deb # GPL implementation of kobo_hwconfig

Prepare a Debian rootfs (including the .deb packages previously built):

    sudo ./build_rootfs.sh


Installation on the device
--------------------------

WARNING: At this point, okreader has only been tested on 3(!) different devices. Only install it if you know what you're doing. You could brick your ereader and in some countries you might void your warranty.

Important: The internal micro SD / eMMC stores configuration information unique to each hardware unit and firmware files which might not be available elsewhere. Therefore, it is essential to backup the first 15 MiB of the internal storage at the very least. I strongly recommend backing up the entire internal storage.

Some Kobo ereaders (as far as I know, Touch, Glo and some Aura revisions) store their firmware and data on internal removable microSD cards. On these devices, it is recommended to replace the internal microSD card with one containing okreader. Other ereaders store their firmware on an eMMC chip soldered to the PCB. On these devices, it is recommended to boot okreader from the external microSD slot, leaving the official firmware on the internal storage unmodified.


Installation on the internal microSD
-----------------------------------

* Fully power off your device.
* Find a guide on how to open up the case of your particular ereader and follow it. Most are simply retained by plastic clips, so they're easy to open up using a spudger, a plastic card or a guitar pick.
* Locate the internal microSD card and remove it.
* Using a computer with an SD card reader, fully backup the factory SD. For example, on a GNU/Linux computer, assuming the SD card is at /dev/mmcblk0 (replace as needed):

```
dd if=/dev/mmcblk0 of=<PATH_TO_BACKUP_FILE>
```

* Delete the recovery partition (partition 2) and extended (using cfdisk, fdisk, parted, etc) the main system partition (partition 1) in the free space between partitions 1 and 3. It is essential to leave the first 15 MiB free before the first partition, which are used for U-Boot, the kernel, configuration information and display firmware. The system partition should have id 1 and the data partition should have id 3.

* Write U-Boot and the Linux image to the disk (assuming the SD card is at */dev/mmcblk0*:

```
sudo dd if=src/u-boot/u-boot.bin of=/dev/mmcblk0 bs=1024 skip=1 seek=1
sudo dd if=src/linux/arch/arm/boot/uImage of=/dev/mmcblk0 bs=1024 seek=1024
```

* Format the system partition:

```
sudo mkfs.ext4 /dev/mmcblk0p1
```

* Copy okreader's rootfs to the SD card:

```
sudo mount /dev/mmcblk0p1 /mnt/
sudo cp -Rp rootfs/* /mnt/
sudo umount /dev/mmcblk0p1
sync
```

* Move the SD card to the ereader and boot it up.


Booting from the external microSD card
--------------------------------------
TODO


Notes for developers
--------------------

The first partition on the factory SD starts at the 15 MiB offset. The space before the first partition contains U-Boot, the Linux kernel image (in uImage format), the serial number of the device, a *hwconfig* block used both by U-Boot and Linux to detect the hardware configuration, a *waveform* block used by the electronic ink screen driver and one other unknown data blob.

    Address (in 512B blocks) | Size (in 512B blocks) | Data
    -------------------------------------------------------------------------
    0                        | 1                     | MBR
    1                        | 1                     | Serial no.
    2                        | Variable              | U-Boot
    1023                     | 1                     | Unknown
    1024                     | 1                     | HWCONFIG
    2048                     | Variable              | Linux
    14335                    | 1                     | Waveform header?
    14336                    | Variable?             | Waveform

