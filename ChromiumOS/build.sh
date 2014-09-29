#!/usr/bin/env bash
set -e

source "$(dirname ${0})/../util/common.sh"

if [ ${USER} == "kaendfinger" ]
then
  cd ~/chromiumos
  open_block "Chromium OS Build System"
  ./build.sh ${BOARD}
  close_block "Chromium OS Build System"
else
  sudo -u kaendfinger ${0}
fi
