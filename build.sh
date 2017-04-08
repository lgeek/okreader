#!/bin/bash

# Copyright (c) 2015, Cosmin Gorgovan <cosmin at linux-geek dot org>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

available_targets=("u-boot" "linux-image-imx5" "linux-modules-imx5" "linux-image-imx6" "linux-modules-imx6" "firmware-okreader" "koreader" "kobo-hwconfig")

print_usage() {
  echo "Usage: build.sh [TARGET]"
  echo "Valid targets are: "
  echo "  all                   select all targets"
  for target in ${available_targets[*]}; do
    echo "  $target"
  done
}

is_target() {
  for target in ${available_targets[*]}; do
    if [ $1 == $target ] ; then
      return 1
    fi
  done
  
  return 0
}

parse_args() {
  if [ $# -lt "1" ] ; then
    print_usage
    exit 1
  fi

  for arg in "$@"; do
    if [ $arg == all ] ; then
      targets=${available_targets[*]}
    else
      is_target $arg
      if [ $? == 1 ] ; then
        targets[${#targets[*]}]=$arg
      else
        echo "Error: Unrecognized target $arg"
        echo
        print_usage
        exit 1
      fi
    fi
  done
}

compile_uboot() {
  cd src/u-boot
  make mx50_rdp_config
  make -j$(($(nproc)+1))
  cd ../../
}

compile_linux_image_imx5() {
  export ARCH=arm
  cd src/linux
  make mx50_kobo_defconfig
  make -j$(($(nproc)+1)) uImage
  cd ../../
}

compile_linux_image_imx6() {
  export ARCH=arm
  cd src/linux-imx6
  make imx6s_ntx_alyssum_okreader_defconfig
  make -j$(($(nproc)+1)) uImage
  cd ../../
}

compile_linux_modules_imx5() {
  export ARCH=arm
  cd src/linux
  make -j$(($(nproc)+1)) modules
  cd ../../

  patch -N -p1 < src/linux_backports.patch
  cd src/backports-3.14.22-1
  KLIB_BUILD=../linux/ make defconfig-brcmfmac
  KLIB_BUILD=../linux/ make -j$(($(nproc)+1))
  cd ../
  
  mkdir -p linux-okreader-modules-imx5/lib/modules/2.6.35.3-850-gbc67621+/
  cp backports-3.14.22-1/drivers/net/wireless/brcm80211/brcmfmac/brcmfmac.ko linux-okreader-modules-imx5/lib/modules/2.6.35.3-850-gbc67621+/
  cp backports-3.14.22-1/drivers/net/wireless/brcm80211/brcmutil/brcmutil.ko linux-okreader-modules-imx5/lib/modules/2.6.35.3-850-gbc67621+/
  cp backports-3.14.22-1/net/wireless/cfg80211.ko linux-okreader-modules-imx5/lib/modules/2.6.35.3-850-gbc67621+/
  cp backports-3.14.22-1/compat/compat.ko linux-okreader-modules-imx5/lib/modules/2.6.35.3-850-gbc67621+/

  cp linux/drivers/usb/gadget/g_file_storage.ko linux-okreader-modules-imx5/lib/modules/2.6.35.3-850-gbc67621+/
  cp linux/drivers/mmc/card/sdio_wifi_pwr.ko linux-okreader-modules-imx5/lib/modules/2.6.35.3-850-gbc67621+/
  cp linux/drivers/usb/gadget/arcotg_udc.ko linux-okreader-modules-imx5/lib/modules/2.6.35.3-850-gbc67621+/
  
  dpkg-deb -b linux-okreader-modules-imx5 .
  cd ..
}

compile_linux_modules_imx6() {
  export ARCH=arm
  cd src/linux-imx6
  make -j$(($(nproc)+1)) modules
  cd ../../

  patch -N -p1 < src/linux_backports_imx6.patch
  cd src/backports-4.2.6-1
  KLIB_BUILD=../linux-imx6/ make defconfig-brcmfmac
  KLIB_BUILD=../linux-imx6/ make -j$(($(nproc)+1))
  cd ../

  mkdir -p linux-okreader-modules-imx6/lib/modules/3.0.35/
  cp backports-4.2.6-1/drivers/net/wireless/brcm80211/brcmfmac/brcmfmac.ko linux-okreader-modules-imx6/lib/modules/3.0.35/
  cp backports-4.2.6-1/drivers/net/wireless/brcm80211/brcmutil/brcmutil.ko linux-okreader-modules-imx6/lib/modules/3.0.35/
  cp backports-4.2.6-1/net/wireless/cfg80211.ko linux-okreader-modules-imx6/lib/modules/3.0.35/
  cp backports-4.2.6-1/compat/compat.ko linux-okreader-modules-imx6/lib/modules/3.0.35/

  cp linux-imx6/drivers/usb/gadget/g_file_storage.ko linux-okreader-modules-imx6/lib/modules/3.0.35/
  cp linux-imx6/drivers/mmc/card/sdio_wifi_pwr.ko linux-okreader-modules-imx6/lib/modules/3.0.35/

  dpkg-deb -b linux-okreader-modules-imx6 .
  cd ..
}

compile_firmware_okreader() {
  cd src
  dpkg-deb -b firmware-okreader .
  cd ..
}

compile_koreader() {
  cd src/koreader

  # Remove previous builds
  rm *.targz *.tar.gz *.zip

  make fetchthirdparty
  make TARGET=kobo koboupdate

  cd ../koreader-pkg
  rm -Rf opt
  mkdir opt
  cd opt
  tar xf ../../koreader/koreader-kobo-arm-linux-gnueabihf*.targz

  cp ../../../files/okreader.sh koreader/
  cp ../../../files/disable-wifi.sh koreader/
  cp ../../../files/enable-wifi.sh koreader/
  cp ../../../files/obtain-ip.sh koreader/
  cp ../../../files/release-ip.sh koreader/
  chmod +x koreader/disable-wifi.sh
  chmod +x koreader/enable-wifi.sh
  chmod +x koreader/obtain-ip.sh
  chmod +x koreader/release-ip.sh
  chmod +x koreader/restore-wifi-async.sh

  cp ../../../files/defaults.persistent.lua koreader/

  mkdir koreader/bin
  echo "ntpdate pool.ntp.org" > koreader/bin/ntpd
  chmod +x koreader/bin/ntpd

  cd ../../
  dpkg-deb -b koreader-pkg .
  cd ../
}

compile_kobo_hwconfig() {
  make pkg -C ./src/kobo_hwconfig/
}

targets=()
parse_args $@

for target in ${targets[*]}; do
  case $target in
    u-boot)
      compile_uboot
      ;;
    linux-image-imx5)
      compile_linux_image_imx5
      ;;
    linux-modules-imx5)
      compile_linux_modules_imx5
      ;;
    linux-image-imx6)
      compile_linux_image_imx6
      ;;
    linux-modules-imx6)
      compile_linux_modules_imx6
      ;;
    firmware-okreader)
      compile_firmware_okreader
      ;;
    koreader)
      compile_koreader
      ;;
    kobo-hwconfig)
      compile_kobo_hwconfig
      ;;
  esac
done

