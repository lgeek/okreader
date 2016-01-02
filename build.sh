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

available_targets=("linux-image" "linux-modules" "firmware-okreader" "koreader")

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

compile_linux_image() {
  cd src/linux
  make mx50_kobo_defconfig
  make -j$(($(nproc)+1)) uImage
  cd ../../
}

compile_linux_modules() {
  cd src/linux
  make -j$(($(nproc)+1)) modules
  cd ../../

  cd src/backports-3.14.22-1
  KLIB_BUILD=../linux/ make defconfig-brcmfmac
  KLIB_BUILD=../linux/ make -j$(($(nproc)+1))
  cd ../
  
  mkdir -p linux-okreader-modules/lib/modules/2.6.35.3-850-gbc67621+/
  cp backports-3.14.22-1/drivers/net/wireless/brcm80211/brcmfmac/brcmfmac.ko linux-okreader-modules/lib/modules/2.6.35.3-850-gbc67621+/
  cp backports-3.14.22-1/drivers/net/wireless/brcm80211/brcmutil/brcmutil.ko linux-okreader-modules/lib/modules/2.6.35.3-850-gbc67621+/
  cp backports-3.14.22-1/net/wireless/cfg80211.ko linux-okreader-modules/lib/modules/2.6.35.3-850-gbc67621+/
  cp backports-3.14.22-1/compat/compat.ko linux-okreader-modules/lib/modules/2.6.35.3-850-gbc67621+/

  cp linux/drivers/usb/gadget/g_file_storage.ko linux-okreader-modules/lib/modules/2.6.35.3-850-gbc67621+/
  cp linux/drivers/mmc/card/sdio_wifi_pwr.ko linux-okreader-modules/lib/modules/2.6.35.3-850-gbc67621+/
  cp linux/drivers/usb/gadget/arcotg_udc.ko linux-okreader-modules/lib/modules/2.6.35.3-850-gbc67621+/
  
  dpkg-deb -b linux-okreader-modules .
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
  rm *.tar.gz *.zip

  make fetchthirdparty

  # Remove -m32 cflag
  patch -p1 < ../koreader_base_arm.patch

  make TARGET=kobo koboupdate

  # Reverse the patch so that koreader-base can be cleanly updated in the future
  patch -R -p1 < ../koreader_base_arm.patch

  cd ../koreader-pkg
  rm -R opt
  mkdir opt
  cd opt
  tar xf ../../koreader/koreader-kobo-arm-linux-gnueabihf*.targz
  cd ../../
  dpkg-deb -b koreader-pkg .
}

targets=()
parse_args $@

for target in ${targets[*]}; do
  case $target in
    linux-image)
      compile_linux_image
      ;;
    linux-modules)
      compile_linux_modules
      ;;
    firmware-okreader)
      compile_firmware_okreader
      ;;
    koreader)
      compile_koreader
      ;;
  esac
done

