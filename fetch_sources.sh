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

available_targets=("linux-backports" "firmware-okreader")

print_usage() {
  echo "Usage: fetch_sources.sh [TARGET]"
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

fetch_and_unpack_archive() {
  if [ -d src/$3 ] ; then
    echo "Warn: $2 already unpacked"
    return
  fi

  if [ -f src/$2 ] ; then
    echo "Info: $2 already downloaded"
  else
    wget $1 -O ./src/$2
  fi

  if [ $(sha256sum src/$2 | awk '{ print $1 }') != $4 ] ; then
    echo "Error: wrong checksum for $2"
    return
  fi

  tar xf src/$2 -C ./src/
}

fetch_and_verify() {
  if [ -f $2 ] ; then
    echo "Info: $2 already exists"
  else
    wget $1 -O $2
  fi
  
  if [ $(sha256sum $2 | awk '{ print $1 }') != $3 ] ; then
    echo "Error: wrong checksum for $2"
    rm $2
    return
  fi
}

targets=()
parse_args $@

for target in ${targets[*]}; do
  case $target in
    linux-backports)
      fetch_and_unpack_archive "https://www.kernel.org/pub/linux/kernel/projects/backports/stable/v3.14.22/backports-3.14.22-1.tar.xz" "backports-3.14.22-1.tar.xz" "backports-3.14.22-1" "a1b6a03647624545d77559db7cc33027aa4dcd882b48247287697dc6a255e3ac"
      ;;
    firmware-okreader)
      mkdir -p src/firmware-okreader/lib/firmware/brcm
      fetch_and_verify https://raw.githubusercontent.com/allwinner-ics/lichee_linux-3.0/e1a12df96abab1805df4e4b46b3ef7759cca0f84/modules/wifi/bcm40181/open-src/src/dhd/linux/NVRAM.txt src/firmware-okreader/lib/firmware/brcm/brcmfmac43362-sdio.txt 4542dd0adc727f56b4870e52388b47c9ae4afb9a4bbd7b7c30de9714af1aa173
  
      fetch_and_verify https://git.kernel.org/cgit/linux/kernel/git/firmware/linux-firmware.git/plain/brcm/brcmfmac43362-sdio.bin?id=b794c5039dcf0b7ebfeb58929d035f7a1d4c80dd src/firmware-okreader/lib/firmware/brcm/brcmfmac43362-sdio.bin 5783fd90528cc7ae421b6a6056b1572a3840eac4559b26d299d1acae17523e42
      ;;
  esac
done

